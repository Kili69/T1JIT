<#
Script Info

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
    Imports the local device into Windows Autopilot and waits for completion.
.DESCRIPTION
    Installs Az.Accounts and Microsoft.Graph.Authentication, reads the local
    serial number and hardware hash, uploads them to Intune, and waits until
    the import is complete and the Windows Autopilot device is visible.
.PARAMETER TenantId
    Microsoft Entra tenant ID or verified tenant domain. If omitted, the
    interactive Microsoft Graph sign-in selects the tenant.
.PARAMETER GroupTag
    Optional Windows Autopilot group tag.
.PARAMETER AssignedUserPrincipalName
    Optional user principal name to assign during import.
.PARAMETER TimeoutMinutes
    Maximum time to wait for the import and device synchronization.
.PARAMETER PollIntervalSeconds
    Number of seconds between status checks.
.EXAMPLE
    .\Register-WindowsAutopilotDevice.ps1 -TenantId contoso.onmicrosoft.com -GroupTag Tier1
.NOTES
    Run this script in an elevated Windows PowerShell session on the device
    that should be registered. The signed-in account requires the Intune
    permission DeviceManagementServiceConfig.ReadWrite.All.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter()]
    [AllowEmptyString()]
    [string]$GroupTag = "",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$AssignedUserPrincipalName,

    [Parameter()]
    [ValidateRange(1, 240)]
    [int]$TimeoutMinutes = 30,

    [Parameter()]
    [ValidateRange(5, 300)]
    [int]$PollIntervalSeconds = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Install-RequiredModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$RequiredCommand
    )

    if (Get-Command -Name $RequiredCommand -ErrorAction SilentlyContinue) {
        return
    }

    Write-Host "Installing PowerShell module $Name..."
    $installParameters = @{
        Name = $Name
        Scope = "AllUsers"
        Repository = "PSGallery"
        Force = $true
        AllowClobber = $true
        ErrorAction = "Stop"
    }
    Install-Module @installParameters
    Import-Module -Name $Name -Force

    if (-not (Get-Command -Name $RequiredCommand -ErrorAction SilentlyContinue)) {
        throw "Module $Name was installed, but command $RequiredCommand is unavailable."
    }
}

function ConvertTo-GraphFilterValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    return $Value.Replace("'", "''")
}

function Get-GraphCollection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    $result = Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject
    if ($null -eq $result.value) {
        return @()
    }

    return @($result.value)
}

$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run this script from an elevated PowerShell session."
}

if ($PSVersionTable.PSVersion.Major -le 5) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Write-Host "Installing the NuGet package provider..."
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
}

Install-RequiredModule -Name "Az.Accounts" -RequiredCommand "Connect-AzAccount"
Install-RequiredModule -Name "Microsoft.Graph.Authentication" -RequiredCommand "Connect-MgGraph"

$bios = Get-CimInstance -ClassName Win32_BIOS
$serialNumber = [string]$bios.SerialNumber
if ([string]::IsNullOrWhiteSpace($serialNumber)) {
    throw "The device serial number could not be determined."
}
$serialNumber = $serialNumber.Trim()

$deviceDetail = Get-CimInstance -Namespace "root/cimv2/mdm/dmmap" `
    -ClassName "MDM_DevDetail_Ext01" `
    -Filter "InstanceID='Ext' AND ParentID='./DevDetail'"
$hardwareHash = [string]$deviceDetail.DeviceHardwareData
if ([string]::IsNullOrWhiteSpace($hardwareHash)) {
    throw "The Windows Autopilot hardware hash could not be determined."
}

$connectParameters = @{
    Scopes = @("DeviceManagementServiceConfig.ReadWrite.All")
    NoWelcome = $true
}
if (-not [string]::IsNullOrWhiteSpace($TenantId)) {
    $connectParameters.TenantId = $TenantId
}

Write-Host "Connecting to Microsoft Graph..."
Connect-MgGraph @connectParameters | Out-Null

$escapedSerialNumber = ConvertTo-GraphFilterValue -Value $serialNumber
$encodedImportFilter = [Uri]::EscapeDataString("serialNumber eq '$escapedSerialNumber'")
$importLookupUri = "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities?`$filter=$encodedImportFilter"
$existingImports = Get-GraphCollection -Uri $importLookupUri
$import = $existingImports | Select-Object -First 1

if ($null -eq $import) {
    $body = @{
        "@odata.type" = "#microsoft.graph.importedWindowsAutopilotDeviceIdentity"
        serialNumber = $serialNumber
        hardwareIdentifier = $hardwareHash
        groupTag = $GroupTag
        state = @{
            "@odata.type" = "microsoft.graph.importedWindowsAutopilotDeviceIdentityState"
            deviceImportStatus = "pending"
            deviceRegistrationId = ""
            deviceErrorCode = 0
            deviceErrorName = ""
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($AssignedUserPrincipalName)) {
        $body.assignedUserPrincipalName = $AssignedUserPrincipalName
    }

    Write-Host "Uploading the Windows Autopilot hardware hash for $serialNumber..."
    $import = Invoke-MgGraphRequest `
        -Method POST `
        -Uri "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities" `
        -Body ($body | ConvertTo-Json -Depth 5) `
        -ContentType "application/json" `
        -OutputType PSObject
}
else {
    Write-Host "Continuing existing Windows Autopilot import for $serialNumber..."
}

$deadline = [DateTime]::UtcNow.AddMinutes($TimeoutMinutes)
$importUri = "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities/$($import.id)"
do {
    $import = Invoke-MgGraphRequest -Method GET -Uri $importUri -OutputType PSObject
    $status = [string]$import.state.deviceImportStatus
    Write-Host "Import status: $status"

    if ($status -eq "error") {
        throw "Windows Autopilot import failed: $($import.state.deviceErrorName) (code $($import.state.deviceErrorCode))."
    }
    if ($status -ne "complete") {
        Start-Sleep -Seconds $PollIntervalSeconds
    }
} while ($status -ne "complete" -and [DateTime]::UtcNow -lt $deadline)

if ($status -ne "complete") {
    throw "Windows Autopilot import did not complete within $TimeoutMinutes minutes."
}

$encodedDeviceFilter = [Uri]::EscapeDataString("contains(serialNumber,'$escapedSerialNumber')")
$deviceLookupUri = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=$encodedDeviceFilter"
do {
    $autopilotDevices = Get-GraphCollection -Uri $deviceLookupUri
    $autopilotDevice = $autopilotDevices |
        Where-Object { $_.serialNumber -eq $serialNumber } |
        Select-Object -First 1

    if ($null -eq $autopilotDevice -and [DateTime]::UtcNow -lt $deadline) {
        Write-Host "Import complete; waiting for the Windows Autopilot device to become visible..."
        Start-Sleep -Seconds $PollIntervalSeconds
    }
} while ($null -eq $autopilotDevice -and [DateTime]::UtcNow -lt $deadline)

if ($null -eq $autopilotDevice) {
    throw "The import completed, but the Windows Autopilot device was not visible within $TimeoutMinutes minutes."
}

Write-Host "Windows Autopilot import completed for $serialNumber." -ForegroundColor Green
[PSCustomObject]@{
    SerialNumber = $serialNumber
    ImportId = $import.id
    AutopilotDeviceId = $autopilotDevice.id
    GroupTag = $autopilotDevice.groupTag
}
