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
    Returns the IP addresses and subnets currently allowed to access KjitWeb.
.DESCRIPTION
    Reads AllowedClient and ServiceUrl from the installed KjitWeb configuration and reads the matching
    Windows Firewall rule. It emits one object per effective IPv4 address, IPv6 address, or CIDR subnet.
    A localhost-only installation returns the loopback addresses even though it does not require a
    firewall rule.
.PARAMETER InstallServiceFolder
    Existing KjitWeb installation folder. Defaults to Program Files\KJITWEB.
.PARAMETER ServiceName
    Name of the installed Windows service. Defaults to KjitWeb.
.EXAMPLE
    .\get-kjitweb-allowedclient.ps1
    Lists the effective addresses and subnets for the default KjitWeb installation.
.EXAMPLE
    .\get-kjitweb-allowedclient.ps1 | Where-Object AddressFamily -eq IPv6
    Lists only effective IPv6 addresses and subnets.
.INPUTS
    None.
.OUTPUTS
    PSCustomObject. One KjitWeb.AllowedClientAddress object is returned for each effective address.
.NOTES
    -Version 0.1.20260927.2
    Initial version.
#>
[CmdletBinding()]
param(
    [string]$InstallServiceFolder = (Join-Path $env:ProgramFiles "KJITWEB"),
    [string]$ServiceName = "KjitWeb"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"
$scriptVersion = "0.1.20260927.2"

Write-Host "get-kjitweb-allowedclient.ps1 version $scriptVersion"

<#
.SYNOPSIS
    Reads the installed KjitWeb AllowedClient configuration.
.DESCRIPTION
    Searches appsettings.Production.json and appsettings.json in precedence order and returns
    the first complete KjitWebInstall configuration. Invalid JSON and missing configuration
    are reported as terminating errors.
.PARAMETER InstallPath
    Resolved path to the installed KjitWeb application folder.
.OUTPUTS
    PSCustomObject containing the stored AllowedClient and ServiceUrl values.
#>
function Get-InstalledKjitWebConfiguration {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallPath
    )

    foreach ($fileName in @("appsettings.Production.json", "appsettings.json")) {
        $path = Join-Path $InstallPath $fileName
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            continue
        }

        try {
            $settings = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        }
        catch {
            throw "Could not parse '$path': $($_.Exception.Message)"
        }

        if ($settings.PSObject.Properties["KjitWebInstall"] -and
            $settings.KjitWebInstall.PSObject.Properties["AllowedClient"] -and
            -not [string]::IsNullOrWhiteSpace([string]$settings.KjitWebInstall.AllowedClient)) {
            return [PSCustomObject]@{
                AllowedClient = [string]$settings.KjitWebInstall.AllowedClient
                ServiceUrl = if ($settings.KjitWebInstall.PSObject.Properties["ServiceUrl"]) {
                    [string]$settings.KjitWebInstall.ServiceUrl
                }
                else {
                    $null
                }
            }
        }
    }

    throw "No AllowedClient configuration was found in '$InstallPath'."
}

<#
.SYNOPSIS
    Classifies and normalizes an effective Windows Firewall address.
.DESCRIPTION
    Identifies IPv4, IPv6, CIDR subnets, firewall keywords, and loopback addresses. Subnet
    masks returned by Windows Firewall, such as 255.255.255.0, are converted to their CIDR
    prefix length. Unknown firewall keywords or ranges are preserved and classified as Other.
.PARAMETER RemoteAddress
    Address, subnet, range, or Windows Firewall keyword to inspect.
.OUTPUTS
    PSCustomObject containing the normalized address, address family, address type, prefix
    length, and loopback state.
#>
function Get-AddressDetails {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RemoteAddress
    )

    if ($RemoteAddress -in @("Any", "*")) {
        return [PSCustomObject]@{
            AddressFamily = "Any"
            AddressType = "Any"
            PrefixLength = $null
            IsLoopback = $false
        }
    }

    $addressParts = @($RemoteAddress -split '/', 2)
    $ipAddress = $null
    if (-not [System.Net.IPAddress]::TryParse($addressParts[0], [ref]$ipAddress)) {
        return [PSCustomObject]@{
            AddressFamily = "Other"
            AddressType = "FirewallKeywordOrRange"
            PrefixLength = $null
            IsLoopback = $false
        }
    }

    $isSubnet = $addressParts.Count -eq 2
    $prefixLength = $null
    $normalizedRemoteAddress = $RemoteAddress
    if ($isSubnet) {
        $maximumPrefixLength = if ($ipAddress.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
            32
        }
        else {
            128
        }

        $numericPrefixLength = 0
        if ([int]::TryParse($addressParts[1], [ref]$numericPrefixLength)) {
            if ($numericPrefixLength -lt 0 -or $numericPrefixLength -gt $maximumPrefixLength) {
                return [PSCustomObject]@{
                    RemoteAddress = $RemoteAddress
                    AddressFamily = "Other"
                    AddressType = "FirewallKeywordOrRange"
                    PrefixLength = $null
                    IsLoopback = $false
                }
            }
            $prefixLength = $numericPrefixLength
        }
        else {
            $subnetMask = $null
            if (-not [System.Net.IPAddress]::TryParse($addressParts[1], [ref]$subnetMask) -or
                $subnetMask.AddressFamily -ne $ipAddress.AddressFamily) {
                return [PSCustomObject]@{
                    RemoteAddress = $RemoteAddress
                    AddressFamily = "Other"
                    AddressType = "FirewallKeywordOrRange"
                    PrefixLength = $null
                    IsLoopback = $false
                }
            }

            $maskBits = (($subnetMask.GetAddressBytes() |
                    ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, "0") }) -join "")
            if ($maskBits -notmatch '^1*0*$') {
                return [PSCustomObject]@{
                    RemoteAddress = $RemoteAddress
                    AddressFamily = "Other"
                    AddressType = "FirewallKeywordOrRange"
                    PrefixLength = $null
                    IsLoopback = $false
                }
            }

            $firstZero = $maskBits.IndexOf("0")
            $prefixLength = if ($firstZero -lt 0) { $maximumPrefixLength } else { $firstZero }
        }

        $normalizedRemoteAddress = "$($ipAddress.IPAddressToString)/$prefixLength"
    }

    [PSCustomObject]@{
        RemoteAddress = $normalizedRemoteAddress
        AddressFamily = if ($ipAddress.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork) {
            "IPv4"
        }
        else {
            "IPv6"
        }
        AddressType = if ($isSubnet) { "Subnet" } else { "Address" }
        PrefixLength = $prefixLength
        IsLoopback = [System.Net.IPAddress]::IsLoopback($ipAddress)
    }
}

$installPath = (Resolve-Path -LiteralPath $InstallServiceFolder).ProviderPath
$configuration = Get-InstalledKjitWebConfiguration -InstallPath $installPath
$configuredAllowList = @($configuration.AllowedClient -split '[,;]' |
    ForEach-Object { $_.Trim() } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Select-Object -Unique)

$serviceUrl = $configuration.ServiceUrl
if ([string]::IsNullOrWhiteSpace($serviceUrl)) {
    $environmentPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"
    $environmentValues = (Get-ItemProperty -Path $environmentPath -Name Environment -ErrorAction Stop).Environment
    $serviceUrlEntry = $environmentValues |
        Where-Object { $_ -like "ASPNETCORE_URLS=*" } |
        Select-Object -First 1
    if ([string]::IsNullOrWhiteSpace($serviceUrlEntry)) {
        throw "Could not determine the configured service URL for '$ServiceName'."
    }
    $serviceUrl = $serviceUrlEntry.Substring("ASPNETCORE_URLS=".Length)
}

if ($serviceUrl -notmatch ':(?<port>\d+)') {
    throw "Could not determine the TCP port from '$serviceUrl'."
}
$port = [int]$Matches.port
$firewallRuleName = "KjitWeb Port $port Client Restriction"

$loopbackOnlyBinding = $serviceUrl -match 'http://localhost:' -or
    ($serviceUrl -match 'http://127\.0\.0\.1:' -and $serviceUrl -match 'http://\[::1\]:')
if ($loopbackOnlyBinding) {
    $effectiveAddresses = @("127.0.0.1", "::1")
    $source = "HTTP.sys loopback binding"
}
else {
    $firewallRule = Get-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction Stop
    $effectiveAddresses = @(@("127.0.0.1", "::1") + @($firewallRule |
            Get-NetFirewallAddressFilter |
            ForEach-Object { $_.RemoteAddress } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) |
        Select-Object -Unique)
    if ($effectiveAddresses.Count -eq 0) {
        throw "Firewall rule '$firewallRuleName' does not contain any remote addresses."
    }
    $source = "Windows Firewall"
}

foreach ($remoteAddress in $effectiveAddresses) {
    $details = Get-AddressDetails -RemoteAddress $remoteAddress
    [PSCustomObject]@{
        PSTypeName = "KjitWeb.AllowedClientAddress"
        RemoteAddress = if ($details.PSObject.Properties["RemoteAddress"]) {
            $details.RemoteAddress
        }
        else {
            $remoteAddress
        }
        AddressFamily = $details.AddressFamily
        AddressType = $details.AddressType
        PrefixLength = $details.PrefixLength
        IsLoopback = $details.IsLoopback
        Source = if ($details.IsLoopback) { "Local system" } else { $source }
        Port = $port
        ServiceName = $ServiceName
        FirewallRuleName = $firewallRuleName
        ConfiguredAllowList = @($configuredAllowList)
    }
}
