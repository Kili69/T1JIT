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
    URL ACL reservation automatically.
.PARAMETER AllowedClient
    Hostname/FQDN, IP address, or "*" identifying which client(s) may connect to KjitWeb. Use "localhost"
    (or an empty value) to restrict access to the KjitWeb server itself (binds only to the loopback
    addresses 127.0.0.1/[::1], no firewall rule is created). A specific hostname or IP address binds to all
    interfaces but restricts both ASP.NET Core host filtering and the Windows Firewall rule to that
    client's resolved address(es). "*" allows any remote client; only use this when another control (a
    firewall, IPsec, mutual TLS, or an access proxy) already restricts who can reach the KjitWeb port. Only
    a single hostname/IP is supported, not a list or a subnet/CIDR range.
.PARAMETER InstallServiceFolder
    Existing KjitWeb installation folder. Defaults to Program Files\KJITWEB.
.PARAMETER ServiceName
    Name of the installed Windows service. Defaults to KjitWeb.
.EXAMPLE
    .\set-kjitweb-allowedclient.ps1 -AllowedClient "adminpc01.contoso.com"
    Restricts KjitWeb to the resolved address(es) of "adminpc01.contoso.com" (plus localhost, for local
    troubleshooting).
.EXAMPLE
    .\set-kjitweb-allowedclient.ps1 -AllowedClient "localhost"
    Restores the default loopback-only configuration (no network access, only http://localhost:<port>).
.NOTE
    This script must be run with administrator privileges.
    -Version 0.1.20260925
    initial version
#>
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AllowedClient,
    [string]$InstallServiceFolder = (Join-Path $env:ProgramFiles "KJITWEB"),
    [string]$ServiceName = "KjitWeb"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

$AllowedClient = $AllowedClient.Trim()
$appSettingsFileNames = @("appsettings.json", "appsettings.Production.json")
$backupRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("KjitWeb-AllowedClient-{0}" -f [guid]::NewGuid().ToString("N"))
$changesApplied = $false
$previousServiceUrl = $null

<#
.SYNOPSIS
    Resolves the allowed client addresses for a given client identifier.
.PARAMETER Client
    The client identifier (e.g., hostname, IP address, or wildcard).
.RETURNS
    An array of IP addresses corresponding to the allowed client.
#>
function Resolve-AllowedClientAddresses {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Client
    )

    if ([string]::IsNullOrWhiteSpace($Client)) {
        return @("127.0.0.1", "::1")
    }

    $candidate = $Client.Trim()
    if ($candidate -ieq "localhost") {
        return @("127.0.0.1", "::1")
    }

    if ($candidate -eq "*") {
        return @("Any")
    }

    try {
        $addresses = @([System.Net.Dns]::GetHostAddresses($candidate) |
            ForEach-Object { $_.IPAddressToString -replace '%\d+$', '' } |
            Select-Object -Unique)
        if (-not $addresses -or $addresses.Count -eq 0) {
            throw "No IP addresses resolved."
        }
        return @($addresses)
    }
    catch {
        Write-Error "Could not resolve allowed client '$candidate' to IP address(es): $($_.Exception.Message)"
        exit 1
    }
}

<#
.SYNOPSIS
    Retrieves the service URL based on the allowed client. See install-kjitweb.ps1 for the full rationale.
#>
function Get-ServiceUrlFromAllowedClient {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Client,
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    if ([string]::IsNullOrWhiteSpace($Client) -or $Client.Trim() -ieq "localhost") {
        return "http://127.0.0.1:$Port;http://[::1]:$Port"
    }

    return "http://*:$Port"
}

<#
.SYNOPSIS
    Retrieves the AllowedHosts value for ASP.NET Core host filtering based on the allowed client.
#>
function Get-AllowedHostsFromAllowedClient {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Client
    )

    $loopbackHosts = "localhost;127.0.0.1;[::1]"

    if ([string]::IsNullOrWhiteSpace($Client)) {
        return $loopbackHosts
    }

    $candidate = $Client.Trim()
    if ($candidate -eq "*") {
        return "*"
    }

    if ($candidate -ieq "localhost") {
        return $loopbackHosts
    }

    # Keep localhost/loopback access for local troubleshooting while allowing the configured client.
    return "$loopbackHosts;$candidate"
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
        Select-Object -Unique)
    $isLoopbackOnly = ($addresses.Count -gt 0) -and (@($addresses | Where-Object { $_ -notin @("127.0.0.1", "::1") }).Count -eq 0)
    if ($isLoopbackOnly) {
        Write-Host "Skipping firewall rule for localhost-only mode."
        return
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

try {
    $installPath = (Resolve-Path -LiteralPath $InstallServiceFolder).ProviderPath
    if (-not (Test-Path -LiteralPath (Join-Path $installPath "KjitWeb.exe") -PathType Leaf)) {
        throw "No existing KjitWeb installation was found in '$installPath'. Run install-kjitweb.ps1 for a first-time installation."
    }

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

    $newServiceUrl = Get-ServiceUrlFromAllowedClient -Client $AllowedClient -Port $Port
    $allowedHosts = Get-AllowedHostsFromAllowedClient -Client $AllowedClient
    $allowedRemoteAddresses = @(Resolve-AllowedClientAddresses -Client $AllowedClient)
    $firewallRuleName = "KjitWeb Port $Port Client Restriction"

    Write-Host "Current service URL binding : $previousServiceUrl"
    Write-Host "New service URL binding      : $newServiceUrl"
    Write-Host "New AllowedHosts             : $allowedHosts"
    Write-Host "New allowed remote address(es): $($allowedRemoteAddresses -join ', ')"

    if ($newServiceUrl -eq $previousServiceUrl) {
        Write-Host "AllowedClient already resolves to the current service URL binding; only appsettings/AllowedHosts and the firewall rule will be refreshed." -ForegroundColor Yellow
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
        Set-AllowedClientInAppSettings -AppSettingsPath $appSettingsPath -AllowedClient $AllowedClient -ServiceUrl $newServiceUrl -AllowedHosts $allowedHosts
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
