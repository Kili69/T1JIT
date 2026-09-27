<# 
Script Info

Author: Andreas Lucas [MSFT]
Download: 

Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
damages whatsoever (including, without limitation, damages for loss of business profits, business 
interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages

.SYNOPSIS
    Changes which client(s) may reach an already-installed KjitWeb service, without a full reinstall.
.DESCRIPTION
    install-kjitweb.ps1 only asks for -AllowedClient during the initial installation; update-kjitweb.ps1
    deliberately never changes it, so it always preserves the existing configuration when a new release is
    applied. This script lets an administrator change AllowedClient afterwards - for example because a
    client that used to reach KjitWeb by its hostname stopped working, or because access requirements
    changed - without stopping/removing/recreating the Windows service (which install-kjitweb.ps1 would do).

    It updates, consistently, every place AllowedClient affects:
    - appsettings.json / appsettings.Production.json (AllowedClient, ServiceUrl, AllowedHosts)
    - the service's ASPNETCORE_URLS registry value (HKLM:\SYSTEM\CurrentControlSet\Services\KjitWeb\Environment)
    - the HTTP.sys URL ACL reservation for the NetworkService account
    - the Windows Firewall rule restricting remote access to the KjitWeb TCP port

    The KjitWeb service is restarted at the end so the new binding takes effect. If anything fails after
    changes were made, the script attempts to restore the previous appsettings files, registry value, and
    URL ACL reservation automatically. AllowedClient values can also be supplied through the pipeline.
.PARAMETER AllowedClient
    One or more hostnames/FQDNs, IP addresses, or CIDR subnets identifying which clients may connect to
    KjitWeb. Supply a PowerShell array or separate entries with commas or semicolons. Use "localhost" (or
    an empty value) to restrict access to the KjitWeb server itself. Loopback and all active local interface
    addresses are always added automatically. "*" allows any remote client and cannot be combined with
    other entries.
.PARAMETER Add
    Adds one or more entries to the currently configured AllowedClient list.
.PARAMETER Remove
    Removes one or more exact entries from the currently configured AllowedClient list.
.PARAMETER InstallServiceFolder
    Existing KjitWeb installation folder. Defaults to Program Files\KJITWEB.
.PARAMETER ServiceName
    Name of the installed Windows service. Defaults to KjitWeb.
.EXAMPLE
    .\set-kjitweb-allowedclient.ps1 -AllowedClient "adminpc01.contoso.com"
    Restricts KjitWeb to the resolved address(es) of "adminpc01.contoso.com" plus the local system.
.EXAMPLE
    .\set-kjitweb-allowedclient.ps1 -AllowedClient "localhost"
    Restricts KjitWeb to the local system, including loopback and active local interface addresses.
.EXAMPLE
    .\set-kjitweb-allowedclient.ps1 -AllowedClient "192.168.10.0/24", "192.168.11.0/26", "localhost"
    Allows both IPv4 subnets and explicit access from the KjitWeb server itself.
.EXAMPLE
    "192.168.10.0/24", "2001:db8:10::/64", "localhost" | .\set-kjitweb-allowedclient.ps1
    Accepts IPv4, IPv6, and localhost entries from the pipeline and applies them in one operation.
.EXAMPLE
    .\set-kjitweb-allowedclient.ps1 -Add "192.168.10.0/24"
    Adds a subnet without replacing the existing configured entries.
.EXAMPLE
    .\set-kjitweb-allowedclient.ps1 -Remove "192.168.10.0/24" -WhatIf
    Shows the resulting configuration without changing the service, files, URL ACL, or firewall.
.INPUTS
    System.String. Hostnames, IP addresses, CIDR subnets, localhost, and the standalone wildcard can
    be supplied through the pipeline.
.OUTPUTS
    PSCustomObject. Returns a KjitWeb.AllowedClientConfiguration object containing the configured and
    effective allow lists separated into IPv4 and IPv6 addresses and subnets.
.NOTES
    This script must be run with administrator privileges.
    -Version 0.1.20260927.3
    Added multiple IPv4/IPv6 clients, CIDR subnets, pipeline input, local-system access,
    structured output, Add/Remove operations, WhatIf support, input validation, and firewall rollback.
    -Version 0.1.20260925
    Initial version.
#>
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias("IPAddress", "Address", "RemoteAddress")]
    [string[]]$AllowedClient,
    [string[]]$Add,
    [string[]]$Remove,
    [string]$InstallServiceFolder = (Join-Path $env:ProgramFiles "KJITWEB"),
    [string]$ServiceName = "KjitWeb"
)

begin {
Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"
$scriptVersion = "0.1.20260927.3"

Write-Host "set-kjitweb-allowedclient.ps1 version $scriptVersion"

$allowedClientBuffer = New-Object System.Collections.Generic.List[string]
$appSettingsFileNames = @("appsettings.json", "appsettings.Production.json")
$backupRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("KjitWeb-AllowedClient-{0}" -f [guid]::NewGuid().ToString("N"))
$changesApplied = $false
$previousServiceUrl = $null
$previousFirewallRuleExisted = $false
$previousFirewallAddresses = @()

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
    Retrieves the service URL based on the allowed client. See install-kjitweb.ps1 for the full rationale.
#>
function Get-ServiceUrlFromAllowedClient {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Client,
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    return "http://*:$Port"
}

<#
.SYNOPSIS
    Retrieves the AllowedHosts value for ASP.NET Core host filtering based on the allowed client.
#>
function Get-AllowedHostsFromAllowedClient {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Client
    )

    # Remote source addresses are enforced by Windows Firewall, not by HTTP Host headers.
    return "*"
}

<#
.SYNOPSIS
    Reserves an HTTP.sys URL namespace for a non-administrator service account.
.PARAMETER ServiceUrl
    The ASPNETCORE_URLS-style prefix (or ";"-separated list of prefixes) the service binds to.
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
    Removes the HTTP.sys URL ACL reservation(s) for the given ServiceUrl value(s).
#>
function Remove-HttpSysUrlAcl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceUrl
    )

    $prefixes = $ServiceUrl -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($prefix in $prefixes) {
        $urlAclUrl = $prefix.Trim().TrimEnd('/') + '/'
        netsh http delete urlacl "url=$urlAclUrl" 2>&1 | Out-Null
    }
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
    Reads the currently configured AllowedClient value from the installed appsettings files.
#>
function Get-ConfiguredAllowedClient {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallPath
    )

    foreach ($appSettingsFileName in @("appsettings.Production.json", "appsettings.json")) {
        $appSettingsPath = Join-Path $InstallPath $appSettingsFileName
        if (-not (Test-Path -LiteralPath $appSettingsPath -PathType Leaf)) {
            continue
        }

        try {
            $appSettings = Get-Content -LiteralPath $appSettingsPath -Raw | ConvertFrom-Json
        }
        catch {
            throw "Could not parse '$appSettingsPath': $($_.Exception.Message)"
        }

        if ($appSettings.PSObject.Properties["KjitWebInstall"] -and
            $appSettings.KjitWebInstall.PSObject.Properties["AllowedClient"] -and
            -not [string]::IsNullOrWhiteSpace([string]$appSettings.KjitWebInstall.AllowedClient)) {
            return [string]$appSettings.KjitWebInstall.AllowedClient
        }
    }

    throw "No existing AllowedClient configuration was found in '$InstallPath'."
}

<#
.SYNOPSIS
    Writes a new ASPNETCORE_URLS value into the service's registry Environment entry.
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
    Updates AllowedClient, ServiceUrl, and AllowedHosts in an appsettings file, preserving every other
    existing value (CompanyName, JitConfigPath, DebugLog, MutualTls, etc.).
#>
function Set-AllowedClientInAppSettings {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppSettingsPath,
        [Parameter(Mandatory = $true)]
        [string]$AllowedClient,
        [Parameter(Mandatory = $true)]
        [string]$ServiceUrl,
        [Parameter(Mandatory = $true)]
        [string]$AllowedHosts
    )

    if (-not (Test-Path -LiteralPath $AppSettingsPath -PathType Leaf)) {
        Write-Warning "$AppSettingsPath not found. Skipping."
        return
    }

    $appSettings = Get-Content -LiteralPath $AppSettingsPath -Raw | ConvertFrom-Json

    $appSettings | Add-Member -MemberType NoteProperty -Name "AllowedHosts" -Value $AllowedHosts -Force

    if ($null -eq $appSettings.PSObject.Properties["KjitWebInstall"]) {
        $appSettings | Add-Member -MemberType NoteProperty -Name "KjitWebInstall" -Value ([PSCustomObject]@{}) -Force
    }
    $appSettings.KjitWebInstall | Add-Member -MemberType NoteProperty -Name "AllowedClient" -Value $AllowedClient -Force
    $appSettings.KjitWebInstall | Add-Member -MemberType NoteProperty -Name "ServiceUrl" -Value $ServiceUrl -Force

    $appSettings | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $AppSettingsPath -Encoding UTF8
    Write-Host "Updated $(Split-Path -Path $AppSettingsPath -Leaf)."
}
}

process {
    foreach ($clientEntry in @($AllowedClient)) {
        if ($null -ne $clientEntry) {
            $allowedClientBuffer.Add([string]$clientEntry)
        }
    }
}

end {
try {
    $installPath = (Resolve-Path -LiteralPath $InstallServiceFolder).ProviderPath
    if (-not (Test-Path -LiteralPath (Join-Path $installPath "KjitWeb.exe") -PathType Leaf)) {
        throw "No existing KjitWeb installation was found in '$installPath'. Run install-kjitweb.ps1 for a first-time installation."
    }

    $replacementSupplied = $allowedClientBuffer.Count -gt 0
    $addEntries = @($Add |
        ForEach-Object { $_ -split '[,;]' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique)
    $removeEntries = @($Remove |
        ForEach-Object { $_ -split '[,;]' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Select-Object -Unique)

    if ($replacementSupplied -and ($addEntries.Count -gt 0 -or $removeEntries.Count -gt 0)) {
        throw "AllowedClient cannot be combined with Add or Remove."
    }
    if (-not $replacementSupplied -and $addEntries.Count -eq 0 -and $removeEntries.Count -eq 0) {
        throw "Specify AllowedClient, Add, or Remove."
    }

    if ($replacementSupplied) {
        $operation = "Replace"
        $configuredAllowedClients = @(ConvertTo-AllowedClientEntries -Client $allowedClientBuffer.ToArray())
    }
    else {
        $currentAllowedClient = Get-ConfiguredAllowedClient -InstallPath $installPath
        $currentEntries = @(ConvertTo-AllowedClientEntries -Client $currentAllowedClient)
        $configuredAllowedClients = @($currentEntries + $addEntries |
            Where-Object { $removeEntries -notcontains $_ } |
            Select-Object -Unique)
        if ($configuredAllowedClients.Count -eq 0) {
            $configuredAllowedClients = @("localhost")
        }
        $configuredAllowedClients = @(ConvertTo-AllowedClientEntries -Client $configuredAllowedClients)
        $operation = if ($addEntries.Count -gt 0 -and $removeEntries.Count -gt 0) {
            "AddRemove"
        }
        elseif ($addEntries.Count -gt 0) {
            "Add"
        }
        else {
            "Remove"
        }
    }
    $configuredAllowedClientValue = $configuredAllowedClients -join ";"

    $service = Get-Service -Name $ServiceName -ErrorAction Stop
    $serviceWasRunning = $service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Stopped

    $previousServiceUrl = Get-ConfiguredServiceUrl -ServiceName $ServiceName
    if (-not $previousServiceUrl) {
        throw "Could not determine the currently configured ASPNETCORE_URLS value for service '$ServiceName'."
    }

    if ($previousServiceUrl -notmatch ':(?<port>\d+)') {
        throw "Could not determine the TCP port from the configured service URL '$previousServiceUrl'."
    }
    $Port = [int]$Matches.port

    $newServiceUrl = Get-ServiceUrlFromAllowedClient -Client $configuredAllowedClientValue -Port $Port
    $allowedHosts = Get-AllowedHostsFromAllowedClient -Client $configuredAllowedClientValue
    $allowedRemoteAddresses = @(Resolve-AllowedClientAddresses -Client $configuredAllowedClientValue)
    $firewallRuleName = "KjitWeb Port $Port Client Restriction"
    $existingFirewallRule = Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue
    if ($null -ne $existingFirewallRule) {
        $previousFirewallRuleExisted = $true
        $previousFirewallAddresses = @($existingFirewallRule |
            Get-NetFirewallAddressFilter |
            ForEach-Object { $_.RemoteAddress } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -Unique)
    }

    Write-Host "Current service URL binding : $previousServiceUrl"
    Write-Host "New service URL binding      : $newServiceUrl"
    Write-Host "New AllowedHosts             : $allowedHosts"
    Write-Host "New allowed remote address(es): $($allowedRemoteAddresses -join ', ')"

    if ($newServiceUrl -eq $previousServiceUrl) {
        Write-Host "AllowedClient already resolves to the current service URL binding; only appsettings/AllowedHosts and the firewall rule will be refreshed." -ForegroundColor Yellow
    }

    if (-not $PSCmdlet.ShouldProcess(
        "KjitWeb service '$ServiceName'",
        "$operation AllowedClient with '$configuredAllowedClientValue'"
    )) {
        return [PSCustomObject]@{
            PSTypeName          = "KjitWeb.AllowedClientConfiguration"
            Applied             = $false
            Operation           = $operation
            ServiceName         = $ServiceName
            Port                = $Port
            ServiceUrl          = $newServiceUrl
            FirewallRuleName    = $firewallRuleName
            ConfiguredAllowList = @($configuredAllowedClients)
            EffectiveAllowList  = @($allowedRemoteAddresses)
        }
    }

    Write-Host "Creating rollback backup: $backupRoot"
    New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null
    foreach ($appSettingsFileName in $appSettingsFileNames) {
        $appSettingsPath = Join-Path $installPath $appSettingsFileName
        if (Test-Path -LiteralPath $appSettingsPath -PathType Leaf) {
            Copy-Item -LiteralPath $appSettingsPath -Destination (Join-Path $backupRoot $appSettingsFileName) -Force
        }
    }

    foreach ($appSettingsFileName in $appSettingsFileNames) {
        $appSettingsPath = Join-Path $installPath $appSettingsFileName
        Set-AllowedClientInAppSettings -AppSettingsPath $appSettingsPath -AllowedClient $configuredAllowedClientValue -ServiceUrl $newServiceUrl -AllowedHosts $allowedHosts
    }

    $changesApplied = $true

    if ($serviceWasRunning) {
        Write-Host "Stopping service '$ServiceName'..."
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped, [TimeSpan]::FromSeconds(30))
    }

    if ($newServiceUrl -ne $previousServiceUrl) {
        Remove-HttpSysUrlAcl -ServiceUrl $previousServiceUrl
        Set-ConfiguredServiceUrl -ServiceName $ServiceName -ServiceUrl $newServiceUrl
    }

    Write-Host "Reserving HTTP.sys URL namespace for NetworkService..."
    Set-HttpSysUrlAcl -ServiceUrl $newServiceUrl -Account "NT AUTHORITY\NETWORK SERVICE"

    Write-Host "Configuring firewall rule '$firewallRuleName' for port $Port ..."
    Set-ClientAccessFirewallRule -RuleName $firewallRuleName -RemoteAddresses $allowedRemoteAddresses -Port $Port

    Write-Host "Verifying Kerberos SPN registration..."
    Set-KjitWebSpn -RemoteAddresses $allowedRemoteAddresses

    if ($serviceWasRunning) {
        Write-Host "Starting service '$ServiceName'..."
        Start-Service -Name $ServiceName -ErrorAction Stop
        $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Running, [TimeSpan]::FromSeconds(30))
    }

    Write-Host "KjitWeb AllowedClient was updated successfully." -ForegroundColor Green

    $ipv4Addresses = New-Object System.Collections.Generic.List[string]
    $ipv6Addresses = New-Object System.Collections.Generic.List[string]
    $ipv4Subnets = New-Object System.Collections.Generic.List[string]
    $ipv6Subnets = New-Object System.Collections.Generic.List[string]
    foreach ($remoteAddress in $allowedRemoteAddresses) {
        if ($remoteAddress -eq "Any") {
            continue
        }

        $addressParts = @($remoteAddress -split '/', 2)
        $parsedAddress = $null
        if (-not [System.Net.IPAddress]::TryParse($addressParts[0], [ref]$parsedAddress)) {
            continue
        }

        $isSubnet = $addressParts.Count -eq 2
        if ($parsedAddress.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
            if ($isSubnet) {
                $ipv4Subnets.Add($remoteAddress)
            }
            else {
                $ipv4Addresses.Add($remoteAddress)
            }
        }
        else {
            if ($isSubnet) {
                $ipv6Subnets.Add($remoteAddress)
            }
            else {
                $ipv6Addresses.Add($remoteAddress)
            }
        }
    }

    [PSCustomObject]@{
        PSTypeName             = "KjitWeb.AllowedClientConfiguration"
        Applied                = $true
        Operation              = $operation
        ServiceName            = $ServiceName
        Port                   = $Port
        ServiceUrl             = $newServiceUrl
        FirewallRuleName       = $firewallRuleName
        ConfiguredAllowList    = @($configuredAllowedClients)
        EffectiveAllowList     = @($allowedRemoteAddresses)
        IPv4Addresses          = @($ipv4Addresses)
        IPv4Subnets            = @($ipv4Subnets)
        IPv6Addresses          = @($ipv6Addresses)
        IPv6Subnets            = @($ipv6Subnets)
    }
}
catch {
    $reconfigureError = $_
    Write-Warning "Changing AllowedClient failed: $($reconfigureError.Exception.Message)"

    if ($changesApplied) {
        Write-Warning "Restoring the previous configuration..."
        try {
            foreach ($appSettingsFileName in $appSettingsFileNames) {
                $backupFile = Join-Path $backupRoot $appSettingsFileName
                if (Test-Path -LiteralPath $backupFile -PathType Leaf) {
                    Copy-Item -LiteralPath $backupFile -Destination (Join-Path $installPath $appSettingsFileName) -Force
                }
            }
            if ($previousServiceUrl) {
                Set-ConfiguredServiceUrl -ServiceName $ServiceName -ServiceUrl $previousServiceUrl
                Set-HttpSysUrlAcl -ServiceUrl $previousServiceUrl -Account "NT AUTHORITY\NETWORK SERVICE"
            }
            if ($previousFirewallRuleExisted -and $previousFirewallAddresses.Count -gt 0) {
                Set-ClientAccessFirewallRule -RuleName $firewallRuleName -RemoteAddresses $previousFirewallAddresses -Port $Port
            }
            else {
                Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue |
                    Remove-NetFirewallRule -ErrorAction SilentlyContinue | Out-Null
            }
            $currentService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($null -ne $currentService -and $currentService.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Stopped) {
                Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
            }
            Write-Warning "Previous configuration restored."
        }
        catch {
            Write-Warning "Automatic rollback failed: $($_.Exception.Message). Manual recovery may be required; a backup is available at: $backupRoot"
        }
    }

    throw "Changing AllowedClient failed: $($reconfigureError.Exception.Message)"
}
finally {
    if (Test-Path -LiteralPath $backupRoot) {
        Remove-Item -LiteralPath $backupRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
}
