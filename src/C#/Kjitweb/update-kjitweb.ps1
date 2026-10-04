<# 
Author: Andreas Lucas [MSFT]
Download: 


.SYNOPSIS
    Updates an existing KjitWeb installation without changing its configuration.
.DESCRIPTION
    Stops the KjitWeb service, replaces the installed application files from the
    publish-service folder, restores the existing appsettings files and app_data,
    and starts the service again. If the update fails, the previous installation
    is restored automatically.
.PARAMETER SourceServiceFolder
    Folder containing the new published KjitWeb files. Defaults to the
    publish-service folder next to this script.
.PARAMETER InstallServiceFolder
    Existing KjitWeb installation folder. Defaults to Program Files\KJITWEB.
.PARAMETER ServiceName
    Name of the installed Windows service. Defaults to KjitWeb.
.EXAMPLE
    .\update-kjitweb.ps1
.EXAMPLE
    .\update-kjitweb.ps1 -InstallServiceFolder "D:\Services\KJITWEB"
#>
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string]$SourceServiceFolder = (Join-Path $PSScriptRoot "publish-service"),
    [string]$InstallServiceFolder = (Join-Path $env:ProgramFiles "KJITWEB"),
    [string]$ServiceName = "KjitWeb"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$configurationFilePattern = "appsettings*.json"
$persistentDirectoryNames = @("app_data")
$backupRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("KjitWeb-Update-{0}" -f [guid]::NewGuid().ToString("N"))
$service = $null
$serviceWasRunning = $false
$backupCreated = $false
$updateStarted = $false
$keepBackup = $false

function Wait-ServiceState {
    param(
        [Parameter(Mandatory = $true)]
        [System.ServiceProcess.ServiceController]$Service,
        [Parameter(Mandatory = $true)]
        [System.ServiceProcess.ServiceControllerStatus]$Status,
        [int]$TimeoutSeconds = 30
    )

    $Service.WaitForStatus($Status, [TimeSpan]::FromSeconds($TimeoutSeconds))
    $Service.Refresh()
    if ($Service.Status -ne $Status) {
        throw "Service '$($Service.ServiceName)' did not reach state '$Status'."
    }
}

function Copy-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    New-Item -Path $Destination -ItemType Directory -Force | Out-Null
    Get-ChildItem -LiteralPath $Source -Force |
        Copy-Item -Destination $Destination -Recurse -Force
}

<#
.SYNOPSIS
    Copies the KjitWeb management scripts (install-kjitweb.ps1, update-kjitweb.ps1,
    set-kjitweb-allowedclient.ps1, get-kjitweb-allowedclient.ps1) next to the installed service so administrators can find and
    re-run them later without having to keep or re-extract the original release package.
.PARAMETER SourceRoot
    The folder containing the management scripts to be copied (normally $PSScriptRoot).
.PARAMETER TargetFolder
    The destination folder where the management scripts should be copied to (the KjitWeb
    installation folder).
.EXAMPLE
    Copy-ManagementScripts -SourceRoot $PSScriptRoot -TargetFolder "C:\Program Files\KJITWEB"
#>
function Copy-ManagementScripts {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,
        [Parameter(Mandatory = $true)]
        [string]$TargetFolder
    )
    $managementScripts = @(
        "install-kjitweb.ps1",
        "update-kjitweb.ps1",
        "set-kjitweb-allowedclient.ps1",
        "get-kjitweb-allowedclient.ps1"
    )
    foreach ($scriptName in $managementScripts) {
        $sourceScriptPath = Join-Path $SourceRoot $scriptName
        if (Test-Path -LiteralPath $sourceScriptPath -PathType Leaf) {
            Copy-Item -LiteralPath $sourceScriptPath -Destination $TargetFolder -Force
        }
        else {
            Write-Warning "Management script not found next to the installer, skipping: $sourceScriptPath"
        }
    }
}

<#
.SYNOPSIS
    Reserves an HTTP.sys URL namespace for a non-administrator service account.
.DESCRIPTION
    KjitWeb is hosted on HTTP.sys, which (unlike Kestrel) requires either Administrator
    privileges or an explicit URL ACL reservation for a non-admin account, such as
    NetworkService, to bind an HTTP prefix. Any pre-existing reservation for the exact same
    URL is removed first because "netsh http add urlacl" fails if a reservation already
    exists, even for the same account.
.PARAMETER ServiceUrl
    The ASPNETCORE_URLS-style prefix (or ";"-separated list of prefixes) the service binds
    to, e.g. "http://*:5240" or "http://127.0.0.1:5240;http://[::1]:5240".
.PARAMETER Account
    The account to grant listen permission to, e.g. "NT AUTHORITY\NETWORK SERVICE".
#>
function Set-HttpSysUrlAcl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceUrl,
        [Parameter(Mandatory = $true)]
        [string]$Account
    )

    $prefixes = $ServiceUrl -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($prefix in $prefixes) {
        # URL ACL reservations require a trailing slash on the URL prefix.
        $urlAclUrl = $prefix.Trim().TrimEnd('/') + '/'

        netsh http delete urlacl "url=$urlAclUrl" 2>&1 | Out-Null

        $addOutput = netsh http add urlacl "url=$urlAclUrl" "user=$Account" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Could not reserve URL '$urlAclUrl' for '$Account' (netsh exited with code $LASTEXITCODE): $addOutput"
        }
    }
}

<#
.SYNOPSIS
    Reads the ASPNETCORE_URLS value the installed service is currently configured with.
#>
function Get-ConfiguredServiceUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )

    $envValues = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName" -Name "Environment" -ErrorAction SilentlyContinue).Environment
    $urlsEntry = $envValues | Where-Object { $_ -like "ASPNETCORE_URLS=*" } | Select-Object -First 1
    if ($null -eq $urlsEntry) {
        return $null
    }

    return $urlsEntry.Substring("ASPNETCORE_URLS=".Length)
}

<#
.SYNOPSIS
    Writes a new ASPNETCORE_URLS value into the service's registry Environment entry.
.PARAMETER ServiceName
    Name of the installed Windows service.
.PARAMETER ServiceUrl
    The new ASPNETCORE_URLS value to persist (may contain multiple ";"-separated prefixes).
#>
function Set-ConfiguredServiceUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,
        [Parameter(Mandatory = $true)]
        [string]$ServiceUrl
    )

    $envRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
    $envValues = (Get-ItemProperty -Path $envRegPath -Name "Environment" -ErrorAction SilentlyContinue).Environment
    if ($null -eq $envValues) {
        Write-Warning "Could not read the service Environment registry value; ASPNETCORE_URLS was not updated."
        return
    }

    $newEnvValues = $envValues | ForEach-Object {
        if ($_ -like "ASPNETCORE_URLS=*") { "ASPNETCORE_URLS=$ServiceUrl" } else { $_ }
    }
    New-ItemProperty -Path $envRegPath -Name "Environment" -PropertyType MultiString -Value $newEnvValues -Force | Out-Null
}

<#
.SYNOPSIS
    Migrates older localhost-only HTTP.sys bindings to the local-system firewall model.
.DESCRIPTION
    Older installations may bind only to localhost or to the two loopback addresses. The local
    system is now always allowed through loopback and all active interface addresses, so HTTP.sys
    must listen on every local interface while Windows Firewall enforces the source allow list.
.PARAMETER ServiceName
    Name of the installed Windows service.
.PARAMETER ConfiguredServiceUrl
    The ASPNETCORE_URLS value currently configured for the service.
.PARAMETER InstallPath
    Installed KjitWeb folder, used to locate appsettings.json/appsettings.Production.json.
.RETURNS
    The (possibly rewritten) ASPNETCORE_URLS value to use.
#>
function Convert-LocalSystemServiceUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,
        [Parameter(Mandatory = $true)]
        [string]$ConfiguredServiceUrl,
        [Parameter(Mandatory = $true)]
        [string]$InstallPath
    )

    if ($ConfiguredServiceUrl -notmatch ':(?<port>\d+)') {
        return $ConfiguredServiceUrl
    }

    $port = $Matches.port
    $normalizedServiceUrl = $ConfiguredServiceUrl.Trim().TrimEnd("/")
    $localOnlyServiceUrls = @(
        "http://localhost:$port",
        "http://127.0.0.1:$port;http://[::1]:$port"
    )
    if ($normalizedServiceUrl -notin $localOnlyServiceUrls) {
        return $ConfiguredServiceUrl
    }

    $newServiceUrl = "http://*:$port"
    Write-Host "Migrating the local-system HTTP.sys binding to '$newServiceUrl' so local interface addresses remain reachable."

    foreach ($prefix in @("http://localhost:$port", "http://127.0.0.1:$port", "http://[::1]:$port")) {
        netsh http delete urlacl "url=$prefix/" 2>&1 | Out-Null
    }

    Set-ConfiguredServiceUrl -ServiceName $ServiceName -ServiceUrl $newServiceUrl

    foreach ($appSettingsFile in @("appsettings.json", "appsettings.Production.json")) {
        $appSettingsPath = Join-Path $InstallPath $appSettingsFile
        if (-not (Test-Path -LiteralPath $appSettingsPath -PathType Leaf)) {
            continue
        }
        try {
            $appSettings = Get-Content -Path $appSettingsPath -Raw | ConvertFrom-Json
            $changed = $false

            if ($appSettings.PSObject.Properties["AllowedHosts"] -and $appSettings.AllowedHosts -ne "*") {
                $appSettings.AllowedHosts = "*"
                $changed = $true
            }
            if ($appSettings.PSObject.Properties["KjitWebInstall"] -and
                $appSettings.KjitWebInstall.PSObject.Properties["ServiceUrl"] -and
                $appSettings.KjitWebInstall.ServiceUrl -ieq $ConfiguredServiceUrl.Trim()) {
                $appSettings.KjitWebInstall.ServiceUrl = $newServiceUrl
                $changed = $true
            }

            if ($changed) {
                $appSettings | ConvertTo-Json -Depth 20 | Set-Content -Path $appSettingsPath -Encoding UTF8
                Write-Host "Updated $appSettingsFile with the local-system binding."
            }
        }
        catch {
            Write-Warning "Could not update $appSettingsFile with the local-system binding: $($_.Exception.Message)"
        }
    }

    return $newServiceUrl
}

<#
.SYNOPSIS
    Normalizes allowed-client input into individual entries.
.PARAMETER Client
    Hostnames, IP addresses, CIDR subnets, localhost, or a wildcard. Each supplied string may contain
    comma- or semicolon-separated entries.
.RETURNS
    A unique array of normalized entries.
#>
function ConvertTo-AllowedClientEntries {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Client
    )

    $entries = @($Client |
        ForEach-Object { $_ -split '[,;]' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique)

    if ($entries.Count -eq 0) {
        return @("localhost")
    }

    if ($entries -contains "*" -and $entries.Count -gt 1) {
        throw "AllowedClient '*' cannot be combined with hostnames, IP addresses, subnets, or localhost."
    }

    return @($entries)
}

<#
.SYNOPSIS
    Returns the loopback and active local unicast addresses of this computer.
.RETURNS
    A unique array of IPv4 and IPv6 addresses accepted by Windows Firewall.
#>
function Get-LocalSystemAddresses {
    $addresses = @("127.0.0.1", "::1")

    try {
        $addresses += @(Get-NetIPAddress -AddressFamily IPv4, IPv6 -ErrorAction Stop |
            Where-Object {
                $_.AddressState -eq "Preferred" -and
                -not [string]::IsNullOrWhiteSpace($_.IPAddress)
            } |
            ForEach-Object { $_.IPAddress -replace '%\d+$', '' })
    }
    catch {
        throw "Could not determine the local system IP addresses: $($_.Exception.Message)"
    }

    return @($addresses |
        Where-Object { $_ -notin @("0.0.0.0", "::") } |
        Select-Object -Unique)
}

<#
.SYNOPSIS
    Validates a DNS hostname before attempting name resolution.
.PARAMETER HostName
    Hostname or FQDN to validate.
#>
function Assert-AllowedClientHostName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostName
    )

    $normalizedHostName = $HostName.TrimEnd(".")
    $labels = @($normalizedHostName -split '\.')
    $looksLikeInvalidIpAddress = $HostName -match '^[0-9.]+$' -or $HostName.Contains(":")
    $hasInvalidLabel = [string]::IsNullOrWhiteSpace($normalizedHostName) -or
        $normalizedHostName.Length -gt 253 -or
        @($labels | Where-Object {
                $_.Length -gt 63 -or
                $_ -notmatch '^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$'
            }).Count -gt 0

    if ($looksLikeInvalidIpAddress -or $hasInvalidLabel) {
        throw "AllowedClient '$HostName' is not a valid IPv4 address, IPv6 address, CIDR subnet, or DNS hostname. Use a complete value such as '192.168.1.10', '192.168.1.0/24', or 'adminpc01.contoso.com'."
    }
}

<#
.SYNOPSIS
    Resolves allowed-client entries to addresses accepted by Windows Firewall.
.PARAMETER Client
    Hostnames, IP addresses, CIDR subnets, localhost, or a wildcard.
.RETURNS
    An array of IP addresses and CIDR subnets.
#>
function Resolve-AllowedClientAddresses {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Client
    )

    $entries = @(ConvertTo-AllowedClientEntries -Client $Client)
    if ($entries.Count -eq 1 -and $entries[0] -eq "*") {
        return @("Any")
    }

    $addresses = @(
        Get-LocalSystemAddresses
        foreach ($candidate in $entries) {
            if ($candidate -ieq "localhost") {
                continue
            }

            if ($candidate -match '/') {
                $cidrParts = @($candidate -split '/', 2)
                $ipAddress = $null
                $prefixLength = 0
                if ($cidrParts.Count -ne 2 -or
                    -not [System.Net.IPAddress]::TryParse($cidrParts[0], [ref]$ipAddress) -or
                    -not [int]::TryParse($cidrParts[1], [ref]$prefixLength)) {
                    throw "AllowedClient '$candidate' is not a valid CIDR subnet."
                }

                $maximumPrefixLength = if ($ipAddress.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
                    32
                }
                else {
                    128
                }
                if ($prefixLength -lt 0 -or $prefixLength -gt $maximumPrefixLength) {
                    throw "AllowedClient '$candidate' has an invalid prefix length for its address family."
                }

                "$($ipAddress.IPAddressToString -replace '%\d+$', '')/$prefixLength"
                continue
            }

            $ipAddress = $null
            if ([System.Net.IPAddress]::TryParse($candidate, [ref]$ipAddress)) {
                $ipAddress.IPAddressToString -replace '%\d+$', ''
                continue
            }

            Assert-AllowedClientHostName -HostName $candidate
            try {
                $resolvedAddresses = @([System.Net.Dns]::GetHostAddresses($candidate))
                if ($resolvedAddresses.Count -eq 0) {
                    throw "No IP addresses resolved."
                }
                $resolvedAddresses |
                    ForEach-Object { $_.IPAddressToString -replace '%\d+$', '' }
            }
            catch {
                throw "Could not resolve allowed client '$candidate' to IP address(es): $($_.Exception.Message)"
            }
        }
    )

    return @($addresses | Select-Object -Unique)
}

<#
.SYNOPSIS
    Configures a Windows Firewall rule to allow inbound TCP traffic on a specified port from specified
    remote addresses. See install-kjitweb.ps1 for the full rationale.
#>
function Set-ClientAccessFirewallRule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RuleName,
        [Parameter(Mandatory = $true)]
        [string[]]$RemoteAddresses,
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue |
        Remove-NetFirewallRule -ErrorAction SilentlyContinue | Out-Null

    $addresses = @($RemoteAddresses |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim() -replace '%\d+$', '' } |
        Where-Object { $_ -notin @("127.0.0.1", "::1") } |
        Select-Object -Unique)
    if ($addresses.Count -eq 0) {
        throw "No non-loopback addresses were available for firewall rule '$RuleName'."
    }
    New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port -RemoteAddress $addresses -Profile Any -ErrorAction Stop | Out-Null
}

<#
.SYNOPSIS
    Ensures the Kerberos Service Principal Names (SPNs) required for remote access are registered
    on the local computer account. See install-kjitweb.ps1 for the full rationale.
#>
function Set-KjitWebSpn {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$RemoteAddresses
    )

    $addresses = @($RemoteAddresses | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $isLoopbackOnly = ($addresses.Count -gt 0) -and (@($addresses | Where-Object { $_ -notin @("127.0.0.1", "::1") }).Count -eq 0)
    if ($isLoopbackOnly) {
        Write-Host "Skipping Kerberos SPN registration for localhost-only mode."
        return
    }

    $shortName = $env:COMPUTERNAME
    try {
        $fqdn = ([System.Net.Dns]::GetHostEntry([System.Net.Dns]::GetHostName())).HostName
    }
    catch {
        Write-Warning "Could not resolve the local FQDN to verify Kerberos SPNs: $($_.Exception.Message). If Kerberos sign-in fails for remote clients, register 'HTTP/$shortName' and the server's FQDN SPN manually; see docs/Kerberos-Setup.md."
        return
    }
    $requiredSpns = @("HTTP/$shortName", "HTTP/$fqdn") | Select-Object -Unique

    try {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement -ErrorAction Stop
        $domainFqdn = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name
        $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, $domainFqdn)
        $computerPrincipal = [System.DirectoryServices.AccountManagement.ComputerPrincipal]::FindByIdentity($context, $shortName)
        if ($null -eq $computerPrincipal) {
            throw "Computer account '$shortName' was not found in domain '$domainFqdn'."
        }
        $computerEntry = $computerPrincipal.GetUnderlyingObject()
        $existingSpns = @($computerEntry.Properties["servicePrincipalName"].Value)
    }
    catch {
        Write-Warning "Could not read the Service Principal Names of computer account '$shortName`$' to verify Kerberos SPNs: $($_.Exception.Message). If Kerberos sign-in fails for remote clients, register 'HTTP/$shortName' and 'HTTP/$fqdn' manually; see docs/Kerberos-Setup.md."
        return
    }

    $missingSpns = @($requiredSpns | Where-Object { $existingSpns -notcontains $_ })
    if ($missingSpns.Count -eq 0) {
        Write-Host "Required Kerberos SPN(s) already registered on '$shortName`$': $($requiredSpns -join ', ')"
        return
    }

    Write-Host "Registering missing Kerberos SPN(s) on '$shortName`$': $($missingSpns -join ', ')"
    try {
        foreach ($spn in $missingSpns) {
            $computerEntry.Properties["servicePrincipalName"].Add($spn) | Out-Null
        }
        $computerEntry.CommitChanges()
        Write-Host "Kerberos SPN(s) registered successfully."
    }
    catch {
        $manualCommands = ($missingSpns | ForEach-Object { "setspn -A $_ $shortName`$" }) -join "; "
        Write-Warning "Insufficient permission to register the Kerberos SPN(s) $($missingSpns -join ', ') on computer account '$shortName`$': $($_.Exception.Message) Kerberos sign-in will fail for remote clients until this is fixed (NTLM fallback will still work). Ask a Domain Administrator to run: $manualCommands (see docs/Kerberos-Setup.md)."
    }
}

<#
.SYNOPSIS
    Determines the AllowedClient value an existing installation is configured for, so an update can
    verify or restore the matching firewall rule.
.DESCRIPTION
    Reads KjitWebInstall.AllowedClient from appsettings.Production.json/appsettings.json. Installations
    from before this setting was introduced do not have it; for those, a purely loopback (IP-literal)
    service URL binding implies AllowedClient was "localhost", which is inferred as a fallback. Any
    other binding without a stored AllowedClient cannot be inferred safely and returns $null.
#>
function Get-ConfiguredAllowedClient {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallPath,
        [Parameter(Mandatory = $true)]
        [string]$ConfiguredServiceUrl
    )

    foreach ($appSettingsFile in @("appsettings.Production.json", "appsettings.json")) {
        $appSettingsPath = Join-Path $InstallPath $appSettingsFile
        if (-not (Test-Path -LiteralPath $appSettingsPath -PathType Leaf)) {
            continue
        }
        try {
            $appSettings = Get-Content -LiteralPath $appSettingsPath -Raw | ConvertFrom-Json
            if ($appSettings.PSObject.Properties["KjitWebInstall"] -and
                $appSettings.KjitWebInstall.PSObject.Properties["AllowedClient"] -and
                -not [string]::IsNullOrWhiteSpace([string]$appSettings.KjitWebInstall.AllowedClient)) {
                return [string]$appSettings.KjitWebInstall.AllowedClient
            }
        }
        catch {
            Write-Warning "Could not parse $appSettingsFile to determine AllowedClient: $($_.Exception.Message)"
        }
    }

    $prefixes = $ConfiguredServiceUrl -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $isLoopbackOnly = ($prefixes.Count -gt 0) -and
        (@($prefixes | Where-Object { $_ -notmatch '^\s*http://(127\.0\.0\.1|\[::1\]):\d+/?\s*$' }).Count -eq 0)
    if ($isLoopbackOnly) {
        return "localhost"
    }

    return $null
}

try {
    $sourcePath = (Resolve-Path -LiteralPath $SourceServiceFolder).ProviderPath
    $installPath = (Resolve-Path -LiteralPath $InstallServiceFolder).ProviderPath

    if ($sourcePath.TrimEnd('\') -eq $installPath.TrimEnd('\')) {
        throw "Source and installation folders must be different."
    }
    if (-not (Test-Path -LiteralPath (Join-Path $sourcePath "KjitWeb.exe") -PathType Leaf)) {
        throw "The update source does not contain KjitWeb.exe: $sourcePath"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $installPath "KjitWeb.exe") -PathType Leaf)) {
        throw "No existing KjitWeb installation was found: $installPath"
    }

    $service = Get-Service -Name $ServiceName -ErrorAction Stop
    $serviceWasRunning = $service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Stopped

    Write-Host "Creating rollback backup: $backupRoot"
    Copy-DirectoryContents -Source $installPath -Destination $backupRoot
    $backupCreated = $true

    if ($serviceWasRunning) {
        Write-Host "Stopping service '$ServiceName'..."
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        Wait-ServiceState -Service $service -Status Stopped
    }

    $updateStarted = $true
    Write-Host "Replacing KjitWeb application files..."

    Get-ChildItem -LiteralPath $installPath -Force | Where-Object {
        $_.Name -notlike $configurationFilePattern -and
        $_.Name -notin $persistentDirectoryNames
    } | Remove-Item -Recurse -Force

    Get-ChildItem -LiteralPath $sourcePath -Force | Where-Object {
        $_.Name -notlike $configurationFilePattern -and
        $_.Name -notin $persistentDirectoryNames
    } | Copy-Item -Destination $installPath -Recurse -Force

    if (-not (Test-Path -LiteralPath (Join-Path $installPath "KjitWeb.exe") -PathType Leaf)) {
        throw "KjitWeb.exe is missing after copying the update."
    }

    Write-Host "Copying KjitWeb management scripts to $installPath for future maintenance..."
    Copy-ManagementScripts -SourceRoot $PSScriptRoot -TargetFolder $installPath

    # Older installations may still run under LocalSystem because the service account was only
    # set during a fresh install (see install-kjitweb.ps1) and never touched again on update. We
    # enforce NetworkService here as well, so every update converges existing installations to the
    # least-privileged account. NetworkService is required (not LocalService) because KjitWeb
    # authenticates against Active Directory using the computer account (DefaultNetworkCredentials),
    # which LocalService cannot provide (it presents anonymous credentials on the network).
    # We use the Win32_Service.Change() WMI/CIM method instead of "sc.exe config ... password= """:
    # PowerShell drops/mangles the empty-string password argument when invoking native executables,
    # which makes sc.exe fail with exit code 1639 (invalid command line). CIM does not have this
    # problem and built-in accounts such as NetworkService never require a password anyway.
    Write-Host "Ensuring service account: NetworkService"
    $changeResult = Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'" -ErrorAction Stop |
        Invoke-CimMethod -MethodName Change -Arguments @{ StartName = "NT AUTHORITY\NetworkService"; StartPassword = $null }
    if ($changeResult.ReturnValue -ne 0) {
        Write-Warning "Could not set the service account to NetworkService. Win32_Service.Change returned code $($changeResult.ReturnValue)."
    }

    # Older installations that predate the HTTP.sys migration never needed a URL ACL reservation
    # (Kestrel binds ports directly, HTTP.sys does not), so ensure one exists here as well.
    $configuredServiceUrl = Get-ConfiguredServiceUrl -ServiceName $ServiceName
    if ($configuredServiceUrl) {
        $configuredServiceUrl = Convert-LocalSystemServiceUrl -ServiceName $ServiceName -ConfiguredServiceUrl $configuredServiceUrl -InstallPath $installPath
        Write-Host "Reserving HTTP.sys URL namespace for NetworkService..."
        Set-HttpSysUrlAcl -ServiceUrl $configuredServiceUrl -Account "NT AUTHORITY\NETWORK SERVICE"

        # Ensure the Windows Firewall rule matches the configured AllowedClient, restoring it if it
        # was manually removed, or creating it for the first time on installations that predate this
        # safeguard (install-kjitweb.ps1 only creates it during a fresh installation; update-kjitweb.ps1
        # otherwise never touched the firewall at all).
        if ($configuredServiceUrl -match ':(?<port>\d+)') {
            $configuredPort = [int]$Matches.port
            $configuredAllowedClient = Get-ConfiguredAllowedClient -InstallPath $installPath -ConfiguredServiceUrl $configuredServiceUrl
            if ($null -ne $configuredAllowedClient) {
                $allowedRemoteAddresses = @(Resolve-AllowedClientAddresses -Client $configuredAllowedClient)
                $firewallRuleName = "KjitWeb Port $configuredPort Client Restriction"
                Write-Host "Ensuring firewall rule '$firewallRuleName' matches AllowedClient '$configuredAllowedClient'..."
                Set-ClientAccessFirewallRule -RuleName $firewallRuleName -RemoteAddresses $allowedRemoteAddresses -Port $configuredPort

                Write-Host "Verifying Kerberos SPN registration..."
                Set-KjitWebSpn -RemoteAddresses $allowedRemoteAddresses
            }
            else {
                Write-Warning "Could not determine the configured AllowedClient; skipping firewall rule and Kerberos SPN verification. If KjitWeb should be reachable remotely, run set-kjitweb-allowedclient.ps1 to configure AllowedClient, the firewall rule, and the SPN."
            }
        }
    }
    else {
        Write-Warning "Could not determine the configured service URL; skipping HTTP.sys URL ACL reservation. Verify the KjitWeb service starts successfully."
    }

    if ($serviceWasRunning) {
        Write-Host "Starting service '$ServiceName'..."
        Start-Service -Name $ServiceName -ErrorAction Stop
        Wait-ServiceState -Service $service -Status Running
    }

    Write-Host "KjitWeb was updated successfully. Existing configuration was preserved." -ForegroundColor Green
}
catch {
    $updateError = $_
    Write-Warning "KjitWeb update failed: $($updateError.Exception.Message)"

    if ($backupCreated -and $updateStarted) {
        Write-Warning "Restoring the previous KjitWeb installation..."
        try {
            $currentService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($null -ne $currentService -and $currentService.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Stopped) {
                Stop-Service -Name $ServiceName -Force -ErrorAction Stop
                Wait-ServiceState -Service $currentService -Status Stopped
            }

            Get-ChildItem -LiteralPath $installPath -Force | Remove-Item -Recurse -Force
            Copy-DirectoryContents -Source $backupRoot -Destination $installPath

            if ($serviceWasRunning) {
                $currentService = Get-Service -Name $ServiceName -ErrorAction Stop
                Start-Service -Name $ServiceName -ErrorAction Stop
                Wait-ServiceState -Service $currentService -Status Running
            }
            Write-Warning "The previous installation was restored."
        }
        catch {
            $keepBackup = $true
            Write-Warning "Automatic rollback failed: $($_.Exception.Message). Backup retained at: $backupRoot"
        }
    }

    throw $updateError
}
finally {
    if ($backupCreated -and -not $keepBackup -and (Test-Path -LiteralPath $backupRoot)) {
        Remove-Item -LiteralPath $backupRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}