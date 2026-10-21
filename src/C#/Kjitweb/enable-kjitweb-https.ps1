<#
.SYNOPSIS
    Converts an installed KjitWeb service from HTTP to HTTPS on the same port.
.DESCRIPTION
    Uses either a new self-signed test certificate (-SelfSigned with -DnsName) or an
    existing certificate from Cert:\LocalMachine\My (-Thumbprint). Reserves the HTTPS
    URLs for the current service account and binds the certificate in HTTP.sys for
    IPv4 and IPv6. Preserves URL hosts, other service environment values, and all
    firewall rules. Verifies TLS and an HTTP response before reporting success.
    Replaces matching HTTP URL reservations, preserving their SDDL for rollback.
    On failure, restores the previous environment, HTTP reservations and service state and removes
    only resources created by this invocation. Existing certificates are never deleted,
    and existing HTTPS bindings are never replaced.
    Run locally on the service host in an elevated Windows PowerShell.
.PARAMETER SelfSigned
    Creates a non-exportable, self-signed test certificate in Cert:\LocalMachine\My.
    Requires -DnsName.
.PARAMETER DnsName
    With -SelfSigned: mandatory DNS names written to the certificate.
    With -Thumbprint: optional DNS name used for verification; it must be covered by
    the certificate. Defaults to the first non-wildcard DNS name of the certificate.
.PARAMETER Thumbprint
    Thumbprint of an existing server certificate with private key in Cert:\LocalMachine\My.
.PARAMETER Port
    Existing HTTP port to convert. Defaults to 5240.
.PARAMETER ServiceName
    Installed Windows service name. Defaults to KjitWeb.
.PARAMETER CertificatePath
    Only with -SelfSigned: destination for the public certificate (.cer), which clients
    must explicitly trust. Defaults to KjitWeb-test.cer in the current directory.
    Existing files are not overwritten.
.EXAMPLE
    .\enable-kjitweb-https.ps1 -SelfSigned -DnsName "server01.contoso.local"
.EXAMPLE
    .\enable-kjitweb-https.ps1 -Thumbprint "0123456789ABCDEF0123456789ABCDEF01234567"
.EXAMPLE
    .\enable-kjitweb-https.ps1 -Thumbprint "0123456789ABCDEF0123456789ABCDEF01234567" -WhatIf
#>
#Requires -Version 5.1
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true, ParameterSetName = "SelfSigned")]
    [switch]$SelfSigned,
    [Parameter(Mandatory = $true, ParameterSetName = "SelfSigned")]
    [Parameter(ParameterSetName = "Thumbprint")]
    [ValidateNotNullOrEmpty()]
    [string[]]$DnsName,
    [Parameter(Mandatory = $true, ParameterSetName = "Thumbprint")]
    [ValidateNotNullOrEmpty()]
    [string]$Thumbprint,
    [ValidateRange(1, 65535)]
    [int]$Port = 5240,
    [ValidatePattern('^[a-zA-Z0-9_.-]+$')]
    [string]$ServiceName = "KjitWeb",
    [Parameter(ParameterSetName = "SelfSigned")]
    [string]$CertificatePath = (Join-Path (Get-Location).Path "KjitWeb-test.cer")
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

function Invoke-KjitWebNetsh {
    <#
    .SYNOPSIS
        Invokes netsh.exe with the specified arguments and throws on failure.
    .PARAMETER Arguments
        Array of arguments to pass to netsh.exe.
    .OUTPUTS
        The output lines from netsh.exe.
    #>
    param([string[]]$Arguments)

    $output = & netsh.exe @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "netsh $($Arguments -join ' ') failed (exit $LASTEXITCODE): $($output -join ' ')"
    }
    return $output
}

function Get-KjitWebHttpsPlan {
    <#
    .SYNOPSIS
        Generates a plan for enabling HTTPS for the KjitWeb service.
    .PARAMETER EnvironmentValues
        Array of environment variable strings, typically from the service configuration.
    .PARAMETER Port
        The port number to use for HTTPS.
    .PARAMETER UrlAclOutput
        Output of netsh http show urlacl.
    .PARAMETER SslCertOutput
        Output of netsh http show sslcert.
    .OUTPUTS
        A custom object containing the new URLs, updated environment variables, and IP:port bindings.
    #>
    param(
        [string[]]$EnvironmentValues,
        [int]$Port,
        [string[]]$UrlAclOutput,
        [string[]]$SslCertOutput
    )

    # Extract the existing ASPNETCORE_URLS entry from the environment values.
    $entries = @($EnvironmentValues | Where-Object { $_ -match '^ASPNETCORE_URLS=' })
    # Ensure there is exactly one ASPNETCORE_URLS entry.
    if ($entries.Count -ne 1) {
        throw "Expected exactly one service-specific ASPNETCORE_URLS entry."
    }
    # Split the ASPNETCORE_URLS entry into individual URLs.
    $urls = @($entries[0].Substring("ASPNETCORE_URLS=".Length) -split ';')
    # Convert each HTTP URL to an HTTPS URL on the specified port.
    $httpsUrls = @(
        foreach ($url in $urls) {
            $url = $url.Trim()
            # check that the URL is an HTTP root URL on the specified port
            if ($url -notmatch '^http://(?<host>\[[^\]]+\]|[^/:;\s]+):(?<port>\d+)/?$' -or
                [int]$Matches.port -ne $Port) {
                throw "Only HTTP root URLs on port $Port can be converted; found '$url'."
            }
            # construct the corresponding HTTPS URL on the specified port
            "https://$($Matches.host):$Port/"
        }
    ) | Select-Object -Unique

    # Match endpoint values, not localized field labels (IPv4, IPv6, SNI and CCS).
    foreach ($line in $SslCertOutput) {
        if ($line -match '^\s*.+?:\s+(?:(?:\[[^\]]+\]|[^\s:]+):)?(?<port>\d+)\s*$' -and
            [int]$Matches.port -eq $Port) {
            throw "An HTTP.sys TLS binding already uses port $Port. No binding was changed."
        }
    }
    # Ensure that the HTTP.sys configuration query returned output.
    $httpUrls = @($httpsUrls | ForEach-Object { $_ -replace '^https:', 'http:' })
    $httpReservations = @()
    $reservation = $null
    # Throw an error if either the URL ACL output or SSL certificate output is empty.
    foreach ($line in $UrlAclOutput) {
        if ($line -match '^\s*[^:]+:\s*(?<url>https?://\S+)\s*$') {
            $url = $Matches.url
            if ($url -in $httpsUrls) {
                throw "The HTTPS URL reservation '$url' already exists. No reservation was changed."
            }
            $reservation = $null
            # Check if the URL is an HTTP URL that needs to be tracked for reservation.
            if ($url -in $httpUrls) {
                $reservation = [pscustomobject]@{ Url = $url; Sddl = $null }
                $httpReservations += $reservation
            }
        }
        elseif ($null -ne $reservation -and $line -match '^\s*SDDL\s*:\s*(?<sddl>\S+)\s*$') {
            $reservation.Sddl = $Matches.sddl
        }
    }
    # Ensure that all HTTP URL reservations have valid SDDLs.
    foreach ($reservation in $httpReservations) {
        if ([string]::IsNullOrWhiteSpace($reservation.Sddl)) {
            throw "Cannot read the original SDDL for HTTP URL reservation '$($reservation.Url)'. No reservation was changed."
        }
    }

    # Generate the new environment variable array with updated ASPNETCORE_URLS.
    $newEnvironment = @(
        # Iterate through the existing environment values and update the ASPNETCORE_URLS entry.
        foreach ($value in $EnvironmentValues) {
            # If the current environment value is the ASPNETCORE_URLS entry, replace it with the updated HTTPS URLs.
            if ($value -match '^ASPNETCORE_URLS=') {
                "ASPNETCORE_URLS=$($httpsUrls -join ';')"
            }
            else {
                $value
            }
        }
    )
    # Return a custom object containing the new URLs, updated environment variables, and IP:port bindings.
    [pscustomobject]@{
        Urls = @($httpsUrls)
        Environment = $newEnvironment
        IpPorts = @("0.0.0.0:$Port", "[::]:$Port")
        HttpReservations = $httpReservations
    }
}

function Wait-KjitWebService {
    <#
    .SYNOPSIS
        Waits for the specified KjitWeb service to reach the desired status.
    .PARAMETER Name
        The name of the service to wait for.
    .PARAMETER Status
        The desired service status to wait for.
    #>
    param([string]$Name, [string]$Status)
    # Retrieve the service object for the specified service name.
    $service = Get-Service -Name $Name -ErrorAction Stop
    # Wait for the service to reach the desired status within the specified timeout.
    $service.WaitForStatus(
        [System.ServiceProcess.ServiceControllerStatus]$Status,
        [TimeSpan]::FromSeconds(30)
    )
}

function Test-KjitWebHttpsEndpoint {
    <#
    .SYNOPSIS
        Tests the HTTPS endpoint of the specified KjitWeb service.
    .PARAMETER ConnectHost
        The host to connect to for the TCP connection.
    .PARAMETER DnsName
        The DNS name to use for the SSL handshake.
    .PARAMETER HostHeader
        The host header to include in the HTTP request.
    .PARAMETER Port
        The port to connect to.
    .PARAMETER Thumbprint
        The expected certificate thumbprint.
    .EXAMPLE
        Test-KjitWebHttpsEndpoint -ConnectHost "localhost" -DnsName "example.com" -HostHeader "example.com" -Port 443 -Thumbprint "ABC123"
        Tests the HTTPS endpoint on localhost with the specified DNS name, host header, port, and certificate thumbprint.
    #>
    param(
        [string]$ConnectHost,
        [string]$DnsName,
        [string]$HostHeader,
        [int]$Port,
        [string]$Thumbprint
    )
    # Set a deadline for the HTTPS verification to complete within 30 seconds.
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    do {
        # Attempt to establish a TCP connection to the specified host and port.
        $client = New-Object System.Net.Sockets.TcpClient
        $stream = $null
        try {
            # Initiate the asynchronous connection to the specified host and port.
            $connect = $client.ConnectAsync($ConnectHost, $Port)
            # Wait for the connection to complete or timeout after 3 seconds.
            if (-not $connect.Wait(3000)) {
                throw "TCP connection timed out."
            }
            # Set the receive and send timeouts for the TCP client to 3 seconds.
            $client.ReceiveTimeout = 3000
            $client.SendTimeout = 3000
            # Define the certificate validation callback to ensure the certificate matches the expected thumbprint and has no name mismatch errors.
            $validateCertificate = {
                param($sender, $certificate, $chain, $errors)
                return $null -ne $certificate -and
                    $certificate.GetCertHashString() -eq $Thumbprint -and
                    (($errors -band [System.Net.Security.SslPolicyErrors]::RemoteCertificateNameMismatch) -eq 0)
            }.GetNewClosure()
            # Create an SSL stream using the TCP client stream and the certificate validation callback.
            $stream = [System.Net.Security.SslStream]::new(
                $client.GetStream(), $false,
                [System.Net.Security.RemoteCertificateValidationCallback]$validateCertificate
            )
            # Set the read and write timeouts for the SSL stream to 3 seconds.
            $stream.ReadTimeout = 3000
            $stream.WriteTimeout = 3000
            # Perform the SSL handshake as a client using the specified DNS name.
            $stream.AuthenticateAsClient($DnsName)
            # Send an HTTP GET request to the specified host and port.
            $request = [Text.Encoding]::ASCII.GetBytes(
                "GET / HTTP/1.1`r`nHost: ${HostHeader}:$Port`r`nConnection: close`r`n`r`n"
            )
            $stream.Write($request, 0, $request.Length)
            # Read the HTTP response status line.
            $reader = [IO.StreamReader]::new($stream)
            $status = $reader.ReadLine()
            if ($status -notmatch '^HTTP/1\.[01] (?:[23]\d\d|401|403)\b') {
                throw "Unexpected HTTPS response: '$status'."
            }
            return $status
        }
        catch {
            # If an exception occurs, check if the deadline has been reached and retry until it is.
            if ([DateTime]::UtcNow -ge $deadline) {
                throw "HTTPS verification failed: $($_.Exception.Message)"
            }
            Start-Sleep -Milliseconds 500
        }
        finally {
            if ($null -ne $stream) { $stream.Dispose() }
            $client.Dispose()
        }
    } while ($true)
}

function Get-KjitWebExistingCertificate {
    <#
    .SYNOPSIS
        Retrieves an existing certificate from the local machine's personal store by thumbprint.
    .PARAMETER Thumbprint
        The thumbprint of the certificate to retrieve.
    .EXAMPLE
        Get-KjitWebExistingCertificate -Thumbprint "ABC123"
        Retrieves the certificate with the specified thumbprint from the local machine's personal store.
    #>
    param([string]$Thumbprint)

    # Thumbprints copied from the certificate MMC often contain spaces or invisible characters.
    $normalized = ($Thumbprint -replace '[^0-9A-Fa-f]', '').ToUpperInvariant()
    # Ensure the normalized thumbprint contains exactly 40 hexadecimal characters.
    if ($normalized -notmatch '^[0-9A-F]{40}$') {
        throw "Thumbprint must contain 40 hexadecimal characters: '$Thumbprint'."
    }
    # Attempt to retrieve the certificate from the local machine's personal store using the normalized thumbprint.
    $certificate = Get-Item -LiteralPath "Cert:\LocalMachine\My\$normalized" -ErrorAction SilentlyContinue

    # Ensure the certificate was found in the local machine's personal store.
    if ($null -eq $certificate) {
        throw "Certificate '$normalized' was not found in Cert:\LocalMachine\My."
    }
    # Ensure the certificate has a private key.
    if (-not $certificate.HasPrivateKey) {
        throw "Certificate '$normalized' has no private key."
    }
    # Ensure the certificate is currently valid.
    $now = Get-Date
    if ($certificate.NotBefore -gt $now -or $certificate.NotAfter -le $now) {
        throw "Certificate '$normalized' is not currently valid ($($certificate.NotBefore) - $($certificate.NotAfter))."
    }
    # Ensure the certificate is valid for Server Authentication (EKU 1.3.6.1.5.5.7.3.1).
    $usages = @($certificate.EnhancedKeyUsageList | ForEach-Object { [string]$_.ObjectId })
    if ($usages.Count -gt 0 -and "1.3.6.1.5.5.7.3.1" -notin $usages) {
        throw "Certificate '$normalized' is not valid for Server Authentication (EKU 1.3.6.1.5.5.7.3.1)."
    }
    # Extract the DNS names from the certificate and ensure at least one is present.
    $names = @($certificate.DnsNameList | ForEach-Object { [string]$_.Unicode } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($names.Count -eq 0) {
        throw "Certificate '$normalized' contains no DNS name."
    }
    # Return a custom object containing the certificate and its DNS names.
    [pscustomobject]@{
        Certificate = $certificate
        DnsNames = $names
    }
}

function Test-KjitWebCertificateName {
    <#
    .SYNOPSIS
        Tests if a given name matches any of the certificate names, including wildcard handling.
    .PARAMETER CertificateNames
        An array of certificate names to test against.
    .PARAMETER Name
        The name to test for a match.
    .OUTPUTS
        [bool] Returns $true if the name matches any certificate name, otherwise $false.
    .EXAMPLE
        Test-KjitWebCertificateName -CertificateNames @("example.com", "*.example.org") -Name "sub.example.org"
        # Returns $true because "sub.example.org" matches the wildcard "*.example.org".
    #>
    param([string[]]$CertificateNames, [string]$Name)
    # Iterate through each certificate name and check for a match with the provided name.
    foreach ($certificateName in $CertificateNames) {
        # Check for an exact match first.
        if ($certificateName -eq $Name) { return $true }
        # A wildcard covers exactly one additional left-most label.
        # Check if the certificate name starts with "*." indicating a wildcard.
        if ($certificateName.StartsWith("*.")) {
            $suffix = $certificateName.Substring(1)
            # Extract the suffix after the wildcard for comparison.
            if ($Name.EndsWith($suffix, [StringComparison]::OrdinalIgnoreCase)) {
                $label = $Name.Substring(0, $Name.Length - $suffix.Length)
                # Remove the trailing dot from the label if present.
                if ($label.Length -gt 0 -and -not $label.Contains(".")) { return $true }
            }
        }
    }
    return $false
}

function Enable-KjitWebHttps {
    <#
    .SYNOPSIS
        Enables HTTPS for a specified service using a given certificate.
    .PARAMETER DnsName
        An array of DNS names to associate with the certificate.
    .PARAMETER Thumbprint
        The thumbprint of an existing certificate to use.
    .PARAMETER Port
        The port on which to enable HTTPS.
    .PARAMETER ServiceName
        The name of the service to configure.
    .PARAMETER CertificatePath
        The path to export the certificate if a new one is created.
    #>
    param(
        [string[]]$DnsName,
        [string]$Thumbprint,
        [int]$Port,
        [string]$ServiceName,
        [string]$CertificatePath
    )
    # Validate input parameters and prepare for HTTPS configuration.
    $useExisting = -not [string]::IsNullOrWhiteSpace($Thumbprint)
    $existing = $null
    # If using an existing certificate, retrieve it and validate the DNS names.
    if ($useExisting) {
        # Retrieve the existing certificate using the provided thumbprint.
        $existing = Get-KjitWebExistingCertificate -Thumbprint $Thumbprint
        # Ensure the certificate was found.
        if (-not $existing) {
            throw "Certificate with thumbprint '$Thumbprint' not found."
        }
        # If DNS names are not provided, attempt to use the first non-wildcard name from the certificate.
        if (-not $DnsName) {
            $DnsName = @($existing.DnsNames | Where-Object { -not $_.StartsWith("*.") } | Select-Object -First 1)
            # If no suitable DNS name is found, throw an error.
            if (-not $DnsName) {
                throw "The certificate only contains wildcard names. Specify -DnsName for verification."
            }
        }
    }
    elseif (-not $DnsName) {
        throw "DnsName is required for a self-signed certificate."
    }
    #
    $environmentPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
    # Retrieve the current environment settings for the service.
    $oldEnvironment = @(
        (Get-ItemProperty -LiteralPath $environmentPath -Name Environment -ErrorAction Stop).Environment
    )
    # Ensure that the environment values for the service are retrieved successfully.
    $urlAclOutput = @(Invoke-KjitWebNetsh -Arguments @("http", "show", "urlacl"))
    # Ensure that the URL ACL and SSL certificate outputs are captured successfully.
    $sslCertOutput = @(Invoke-KjitWebNetsh -Arguments @("http", "show", "sslcert"))
    # Ensure that the HTTP.sys configuration query returned output.
    if ($urlAclOutput.Count -eq 0 -or $sslCertOutput.Count -eq 0) {
        throw "HTTP.sys configuration query returned no output. No configuration was changed."
    }
    # Generate the plan for configuring HTTPS based on the current environment and HTTP.sys settings.
    $plan = Get-KjitWebHttpsPlan -EnvironmentValues $oldEnvironment -Port $Port `
        -UrlAclOutput $urlAclOutput -SslCertOutput $sslCertOutput
    # Retrieve the service and ensure it is in a valid state for configuration.
    $service = Get-Service -Name $ServiceName -ErrorAction Stop
    # Ensure the service is either running or stopped before proceeding.
    if ($service.Status -notin @("Running", "Stopped")) {
        throw "Service '$ServiceName' must be Running or Stopped."
    }
    # Record whether the service was running before making changes.
    $wasRunning = $service.Status -eq "Running"
    # Retrieve the service account information and construct the corresponding SDDL for access control.
    $serviceInfo = Get-CimInstance Win32_Service -Filter "Name='$ServiceName'" -ErrorAction Stop
    # Determine the account under which the service is running.
    $account = switch ($serviceInfo.StartName) {
        "LocalSystem" { "NT AUTHORITY\SYSTEM" }
        default { $serviceInfo.StartName }
    }
    # Translate the account name to a security identifier (SID) for use in the SDDL.
    $sid = ([System.Security.Principal.NTAccount]::new($account)).
        Translate([System.Security.Principal.SecurityIdentifier]).Value
    # Construct the SDDL string for granting access to the service account.
    $sddl = "D:(A;;GX;;;$sid)"
    # If not using an existing certificate, validate the certificate path and directory.
    if (-not $useExisting) {
        # Resolve the full path of the certificate file.
        $CertificatePath = [IO.Path]::GetFullPath($CertificatePath)
        # Ensure the certificate file does not already exist.
        if (Test-Path -LiteralPath $CertificatePath) {
            throw "Certificate export already exists: $CertificatePath"
        }
        # Ensure the certificate export directory exists.
        if (-not (Test-Path -LiteralPath (Split-Path $CertificatePath -Parent) -PathType Container)) {
            throw "Certificate export directory does not exist: $CertificatePath"
        }
    }
    # Validate the DNS names provided for the certificate.
    foreach ($name in $DnsName) {
        # Ensure the DNS name is not empty or null.
        if (-not $name) {
            throw "DNS name cannot be empty."
        }
        # Ensure the DNS name is a valid hostname and not a wildcard.
        if ([Uri]::CheckHostName($name) -ne [UriHostNameType]::Dns -or $name.Contains('*')) {
            throw "Use explicit DNS names, not IP addresses or wildcards: '$name'."
        }
        # If using an existing certificate, ensure the DNS name is covered by the certificate.
        if ($useExisting -and -not (Test-KjitWebCertificateName -CertificateNames $existing.DnsNames -Name $name)) {
            throw "DNS name '$name' is not covered by the certificate names: $($existing.DnsNames -join ', ')."
        }
    }
    # Determine if the first URL host is covered by the certificate, considering wildcards.
    $wildcardHost = $plan.Urls[0] -match '^https://[*+]:'
    # Extract the host part of the first URL, replacing wildcard placeholders with localhost for validation.
    $firstHost = ([Uri]($plan.Urls[0] -replace '://\*:', '://localhost:' -replace '://\+:', '://localhost:')).Host
    # If the first host is not localhost and is a valid DNS name, check if it is covered by the certificate.
    if ($firstHost -ne "localhost" -and
        [Uri]::CheckHostName($firstHost.Trim('[', ']')) -eq [UriHostNameType]::Dns) {
        # Check if the first host is covered by the certificate, either by the existing certificate or the DNS names provided.
            $hostCovered = if ($useExisting) {
            Test-KjitWebCertificateName -CertificateNames $existing.DnsNames -Name $firstHost
        }
        else {
            $firstHost -in $DnsName
        }
        # If the host is not covered, throw an error indicating the certificate must include it.
        if (-not $hostCovered) {
            throw "The certificate must include the configured URL host '$firstHost'."
        }
    }
    # If using an existing certificate, verify it against the trusted chain on this server.
    if ($useExisting -and -not $existing.Certificate.Verify()) {
        Write-Warning "Certificate '$($existing.Certificate.Thumbprint)' could not be validated against a trusted chain on this server. Clients may reject it."
    }
    # Initialize variables for tracking the creation of the certificate, URLs, and bindings.
    $certificate = $null
    $createdCertificate = $false
    $createdUrls = @()
    $createdBindings = @()
    $removedHttpReservations = @()
    $serviceTouched = $false
    $environmentChanged = $false
    $exportCreated = $false
    try {
        # Determine which certificate to use, either existing or new.
        if ($useExisting) {
            $certificate = $existing.Certificate
        }
        else {
            # Create a new self-signed certificate for the specified DNS names.
            $certificate = New-SelfSignedCertificate -DnsName $DnsName `
                -CertStoreLocation "Cert:\LocalMachine\My" -Type SSLServerAuthentication `
                -FriendlyName "KjitWeb HTTPS test ($Port)" -KeyAlgorithm RSA -KeyLength 2048 `
                -HashAlgorithm SHA256 -KeyExportPolicy NonExportable `
                -NotAfter (Get-Date).AddMonths(3) -ErrorAction Stop
            $createdCertificate = $true
        }
        # Ensure that the plan contains the necessary HTTP reservations, URLs, and IP:Port bindings before proceeding.
        if ($plan.HttpReservations.Count -gt 0) {
            # If there are HTTP reservations to be removed, mark the service as touched and stop it for modification.
            $serviceTouched = $true
            # Stop the service to safely remove the HTTP reservations.
            Stop-Service -Name $ServiceName -ErrorAction Stop
            Wait-KjitWebService -Name $ServiceName -Status Stopped
            # Remove each HTTP reservation specified in the plan.
            foreach ($reservation in $plan.HttpReservations) {
                Invoke-KjitWebNetsh -Arguments @("http", "delete", "urlacl", "url=$($reservation.Url)") | Out-Null
                $removedHttpReservations += $reservation
            }
        }
        # Add URL ACLs for each URL in the plan.
        foreach ($url in $plan.Urls) {
            Invoke-KjitWebNetsh -Arguments @("http", "add", "urlacl", "url=$url", "sddl=$sddl") | Out-Null
            $createdUrls += $url
        }
        # Generate a new application ID for the SSL bindings.
        $appId = "{$([guid]::NewGuid())}"
        # Bind the certificate to each IP:Port combination specified in the plan.
        foreach ($ipPort in $plan.IpPorts) {
            Invoke-KjitWebNetsh -Arguments @(
                "http", "add", "sslcert", "ipport=$ipPort",
                "certhash=$($certificate.Thumbprint)", "appid=$appId", "certstorename=MY"
            ) | Out-Null
            $createdBindings += $ipPort
        }

        # Restart the service to apply the new environment settings.
        if (-not $serviceTouched) {
            $serviceTouched = $true
            Stop-Service -Name $ServiceName -ErrorAction Stop
            Wait-KjitWebService -Name $ServiceName -Status Stopped
        }
        Set-ItemProperty -LiteralPath $environmentPath -Name Environment -Value $plan.Environment -ErrorAction Stop
        $environmentChanged = $true
        Start-Service -Name $ServiceName -ErrorAction Stop
        Wait-KjitWebService -Name $ServiceName -Status Running
        # Determine the host header to use for HTTPS testing.
        $hostHeader = if ($wildcardHost) { $DnsName[0] } else { $firstHost }
        # Test the HTTPS endpoint using the determined host header and certificate thumbprint.
        $status = Test-KjitWebHttpsEndpoint -ConnectHost $firstHost.Trim('[', ']') -DnsName $DnsName[0] -HostHeader $hostHeader `
            -Port $Port -Thumbprint $certificate.Thumbprint
        # If the HTTPS test failed, throw an error to trigger the rollback.
        if (-not $status) {
            throw "HTTPS endpoint verification failed for https://$($DnsName[0]):$Port/"
        }
        # Export the certificate to a file if it was newly created.
        if (-not $useExisting) {
            Export-Certificate -Cert $certificate -FilePath $CertificatePath -Type CERT -NoClobber -ErrorAction Stop | Out-Null
            $exportCreated = $true
        }
        # Output the verification and certificate details to the host.
        Write-Host "HTTPS verified: https://$($DnsName[0]):$Port/ ($status)"
        Write-Host "Certificate thumbprint: $($certificate.Thumbprint); expires: $($certificate.NotAfter)"
        # If a new certificate was created, provide information about the exported certificate and a warning for the user.
        if (-not $useExisting) {
            Write-Host "Public test certificate: $CertificatePath"
            Write-Warning "Test only: clients must explicitly trust this certificate. No trust store or firewall rule was changed."
        }
    }
    catch {
        $failure = $_
        Write-Warning "HTTPS conversion failed. Restoring the previous configuration: $($failure.Exception.Message)"
        # Prepare the cleanup steps to rollback any changes made during the HTTPS conversion.
        $cleanup = @(
            # If the service was touched, prepare to stop it.
            if ($serviceTouched) {
                @{ Kind = "Stop" }
            }
            # If the environment was changed, prepare to restore it.
            if ($environmentChanged) {
                @{ Kind = "Environment" }
            }
            # If any SSL bindings were created, prepare to remove them.
            foreach ($ipPort in $createdBindings) {
                @{ Kind = "Binding"; Value = $ipPort }
            }
            # If any URL ACLs were created, prepare to remove them.
            foreach ($url in $createdUrls) {
                @{ Kind = "Url"; Value = $url }
            }
            # If any HTTP reservations were removed, prepare to restore them.
            foreach ($reservation in $removedHttpReservations) {
                @{ Kind = "HttpUrl"; Value = $reservation }
            }
            # If the certificate was exported, prepare to delete the export.
            if ($exportCreated) {
                @{ Kind = "Export" }
            }
            # If a new certificate was created, prepare to remove it.
            if ($createdCertificate) {
                @{ Kind = "Certificate" }
            }
            # If the service was touched and was previously running, prepare to start it.
            if ($serviceTouched -and $wasRunning) {
                @{ Kind = "Start" }
            }
        )
        # Execute the cleanup steps and collect any errors that occur during rollback.
        $rollbackErrors = @(
            # Iterate through each cleanup step and attempt to execute it, capturing any errors.
            foreach ($step in $cleanup) {
                try {
                    # Determine the kind of cleanup step and execute the corresponding action.
                    switch ($step.Kind) {
                        "Stop" {
                            # Stop the service to allow rollback of HTTPS changes.
                            Stop-Service -Name $ServiceName -ErrorAction Stop
                            Wait-KjitWebService -Name $ServiceName -Status Stopped
                        }
                        "Environment" {
                            # Restore the previous environment setting.
                            Set-ItemProperty -LiteralPath $environmentPath -Name Environment -Value $oldEnvironment -ErrorAction Stop
                        }
                        "Binding" {
                            # Remove the SSL binding for the specified IP and port.
                            Invoke-KjitWebNetsh -Arguments @("http", "delete", "sslcert", "ipport=$($step.Value)") | Out-Null
                        }
                        "Url" {
                            # Remove the URL ACL for the specified URL.
                            Invoke-KjitWebNetsh -Arguments @("http", "delete", "urlacl", "url=$($step.Value)") | Out-Null
                        }
                        "HttpUrl" {
                            # Restore the HTTP URL reservation with the original SDDL.
                            Invoke-KjitWebNetsh -Arguments @(
                                "http", "add", "urlacl", "url=$($step.Value.Url)", "sddl=$($step.Value.Sddl)"
                            ) | Out-Null
                        }
                        "Export" {
                            # Remove the exported certificate file.
                            Remove-Item -LiteralPath $CertificatePath -ErrorAction Stop
                        }
                        "Certificate" {
                            # Remove the certificate from the local machine store.
                            Remove-Item -LiteralPath "Cert:\LocalMachine\My\$($certificate.Thumbprint)" -ErrorAction Stop
                        }
                        "Start" {
                            # Start the service to restore its previous running state.
                            Start-Service -Name $ServiceName -ErrorAction Stop
                            Wait-KjitWebService -Name $ServiceName -Status Running
                        }
                    }
                }
                catch { $_.Exception.Message }
            }
        )
        # If any rollback errors occurred, throw an exception with details.
        if ($rollbackErrors.Count -gt 0) {
            throw "HTTPS conversion failed: $($failure.Exception.Message). Rollback incomplete: $($rollbackErrors -join '; ')"
        }
        throw $failure
    }
}
# Determine the action description based on the parameter set.
$action = if ($PSCmdlet.ParameterSetName -eq "Thumbprint") {
    "Bind existing certificate '$Thumbprint' and switch HTTP to HTTPS (service restart)"
}
else {
    "Create a self-signed test certificate and switch HTTP to HTTPS (service restart)"
}
# Confirm the action with the user before proceeding.
if ($PSCmdlet.ShouldProcess("$ServiceName on port $Port", $action)) {
    Enable-KjitWebHttps -DnsName $DnsName -Thumbprint $Thumbprint -Port $Port `
        -ServiceName $ServiceName -CertificatePath $CertificatePath
}
