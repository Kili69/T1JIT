#requires -Version 5.1
#requires -PSEdition Desktop
#requires -RunAsAdministrator

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
    Removes artifacts created by a T1JIT and KjitWeb installation.
.DESCRIPTION
    Reads the installed JIT configuration before removing local files. It removes
    the KjitWeb service and firewall rules, JIT scheduled tasks and event log,
    the machine configuration variable, installed files and module, the configured
    GMSA, generated JIT administrator groups and their dedicated OU, and the JIT
    and delegation configuration files.

    OU=Servers, its computer objects, OU=SQL, and eligibility groups are test data
    and are deliberately preserved.
.PARAMETER ConfigurationFile
    Existing JIT.config path. Defaults to the machine JustInTimeConfig value and
    then to the domain SYSVOL location.
.PARAMETER DomainController
    Optional domain controller used for Active Directory removals.
.PARAMETER Force
    Suppresses all ShouldProcess confirmation prompts. WhatIf still takes precedence
    and never removes artifacts.
.EXAMPLE
    .\Remove-T1JitInstallation.ps1 -WhatIf
.EXAMPLE
    .\Remove-T1JitInstallation.ps1 -Force -Verbose
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
param(
    [string]$ConfigurationFile,
    [string]$DomainController,
    [string]$JitProgramFolder = (Join-Path $env:ProgramFiles "Just-In-Time"),
    [string]$WebInstallFolder = (Join-Path $env:ProgramFiles "KJITWEB"),
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if ($Force) {
    $ConfirmPreference = "None"
}

$moduleInstallFolder = Join-Path $env:ProgramFiles "WindowsPowerShell\Modules\Just-In-Time"
$loadedKjitCore = [AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GetName().Name -eq "KjitCore" } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_.Location) -and $_.Location.StartsWith($moduleInstallFolder, [StringComparison]::OrdinalIgnoreCase) } |
    Select-Object -First 1
if ($null -ne $loadedKjitCore -and -not $WhatIfPreference) {
    throw "KjitCore.dll is loaded from '$($loadedKjitCore.Location)' in this PowerShell process. Close this PowerShell window, open a new elevated Windows PowerShell 5.1 session, and run the cleanup again."
}

Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false
Import-Module ScheduledTasks -ErrorAction Stop -Verbose:$false
$adParameters = @{}
if (-not [string]::IsNullOrWhiteSpace($DomainController)) {
    $adParameters.Server = $DomainController
}
$domain = Get-ADDomain @adParameters

if ([string]::IsNullOrWhiteSpace($ConfigurationFile)) {
    $ConfigurationFile = [Environment]::GetEnvironmentVariable("JustInTimeConfig", [EnvironmentVariableTarget]::Machine)
}
if ([string]::IsNullOrWhiteSpace($ConfigurationFile)) {
    $ConfigurationFile = "\\$($domain.DNSRoot)\SYSVOL\$($domain.DNSRoot)\Just-In-Time\JIT.config"
}
if (-not (Test-Path -LiteralPath $ConfigurationFile -PathType Leaf)) {
    throw "JIT configuration not found at '$ConfigurationFile'. Provide -ConfigurationFile so AD artifacts can be identified safely."
}
$configuration = Get-Content -LiteralPath $ConfigurationFile -Raw | ConvertFrom-Json

function Remove-BatchLogonRight {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([Parameter(Mandatory)][string]$Sid)

    if (-not $PSCmdlet.ShouldProcess($Sid, 'Remove from "Log on as a batch job"')) {
        return
    }

    $temporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) "T1JIT-remove-$PID"
    $exportPath = Join-Path $temporaryDirectory "export.inf"
    $importPath = Join-Path $temporaryDirectory "import.inf"
    $databasePath = Join-Path $temporaryDirectory "security.sdb"
    $null = New-Item -Path $temporaryDirectory -ItemType Directory -Force
    try {
        secedit.exe /export /cfg $exportPath | Out-Null
        $lines = @(Get-Content -LiteralPath $exportPath)
        $updatedLines = foreach ($line in $lines) {
            if ($line -match '^SeBatchLogonRight\s*=') {
                $name, $value = $line -split '=', 2
                $entries = @($value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -and $_ -ne "*$Sid" -and $_ -ne $Sid })
                "$($name.Trim()) = $($entries -join ',')"
            }
            else {
                $line
            }
        }
        $updatedLines | Set-Content -LiteralPath $importPath -Encoding Unicode
        secedit.exe /configure /db $databasePath /cfg $importPath /areas USER_RIGHTS | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "secedit failed with exit code $LASTEXITCODE."
        }
    }
    finally {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$service = Get-Service -Name "KjitWeb" -ErrorAction SilentlyContinue
if ($service -and $PSCmdlet.ShouldProcess("KjitWeb", "Stop and delete Windows service")) {
    Stop-Service -Name "KjitWeb" -Force -ErrorAction SilentlyContinue
    sc.exe delete KjitWeb | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "The KjitWeb service could not be deleted. sc.exe exit code: $LASTEXITCODE"
    }
}

Get-NetFirewallRule -ErrorAction SilentlyContinue |
    Where-Object DisplayName -Like "KjitWeb Port * Client Restriction" |
    ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.DisplayName, "Remove firewall rule")) {
            $_ | Remove-NetFirewallRule
        }
    }

foreach ($taskName in @("Tier 1 Local Group Management", "Elevate User")) {
    $task = Get-ScheduledTask -TaskPath "\Just-In-Time-Privilege\" -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task -and $PSCmdlet.ShouldProcess($task.URI, "Unregister scheduled task")) {
        Unregister-ScheduledTask -InputObject $task -Confirm:$false
    }
}

if ($PSCmdlet.ShouldProcess("\Just-In-Time-Privilege", "Remove empty scheduled task folder")) {
    $taskScheduler = New-Object -ComObject "Schedule.Service"
    $taskScheduler.Connect()
    try {
        $taskScheduler.GetFolder("\").DeleteFolder("Just-In-Time-Privilege", 0)
    }
    catch [System.IO.FileNotFoundException] {
        Write-Verbose "The scheduled task folder does not exist."
    }
    catch [System.Runtime.InteropServices.COMException] {
        if ($_.Exception.HResult -ne -2147024894) {
            throw
        }
        Write-Verbose "The scheduled task folder does not exist."
    }
}

if (Get-EventLog -List | Where-Object LogDisplayName -EQ $configuration.EventLog) {
    if ($PSCmdlet.ShouldProcess($configuration.EventLog, "Remove JIT event log and registered sources")) {
        Remove-EventLog -LogName $configuration.EventLog
    }
}

$serviceAccount = $null
try {
    $serviceAccount = Get-ADServiceAccount -Identity $configuration.GroupManagedServiceAccountName @adParameters -ErrorAction Stop
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Verbose "The GMSA '$($configuration.GroupManagedServiceAccountName)' does not exist."
}
if ($serviceAccount) {
    Remove-BatchLogonRight -Sid $serviceAccount.SID.Value -WhatIf:$WhatIfPreference
    if ($PSCmdlet.ShouldProcess($serviceAccount.DistinguishedName, "Uninstall locally and remove group managed service account")) {
        $serviceAccountName = [string]$configuration.GroupManagedServiceAccountName
        $serviceAccountInstalled = Test-ADServiceAccount -Identity $serviceAccountName -ErrorAction SilentlyContinue
        if ($serviceAccountInstalled) {
            try {
                Uninstall-ADServiceAccount -Identity $serviceAccountName -Confirm:$false -ErrorAction Stop
            }
            catch {
                Write-Warning "Normal local GMSA removal failed; forcing removal of '$serviceAccountName': $($_.Exception.Message)"
                Uninstall-ADServiceAccount -Identity $serviceAccountName -ForceRemoveLocal -Confirm:$false -ErrorAction Stop
            }
        }
        else {
            Write-Verbose "The GMSA '$serviceAccountName' is not installed locally."
        }
        Remove-ADServiceAccount -Identity $serviceAccount -Confirm:$false @adParameters
    }
}

$administratorGroupsOu = $null
try {
    $administratorGroupsOu = Get-ADOrganizationalUnit -Identity $configuration.OU @adParameters -ErrorAction Stop
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Verbose "The JIT administrator groups OU '$($configuration.OU)' does not exist."
}
if ($administratorGroupsOu -and $PSCmdlet.ShouldProcess($administratorGroupsOu.DistinguishedName, "Remove generated JIT groups and organizational unit recursively")) {
    Set-ADOrganizationalUnit -Identity $administratorGroupsOu -ProtectedFromAccidentalDeletion $false @adParameters
    Remove-ADOrganizationalUnit -Identity $administratorGroupsOu -Recursive -Confirm:$false @adParameters
}

foreach ($path in @(
    $WebInstallFolder,
    $JitProgramFolder,
    $moduleInstallFolder,
    [string]$configuration.DelegationConfigPath,
    $ConfigurationFile
)) {
    if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path) -and $PSCmdlet.ShouldProcess($path, "Remove installation artifact")) {
        Remove-Item -LiteralPath $path -Recurse -Force
    }
}

$configurationDirectory = Split-Path -Path $ConfigurationFile -Parent
if ((Test-Path -LiteralPath $configurationDirectory -PathType Container) -and
    -not (Get-ChildItem -LiteralPath $configurationDirectory -Force) -and
    $PSCmdlet.ShouldProcess($configurationDirectory, "Remove empty JIT configuration directory")) {
    Remove-Item -LiteralPath $configurationDirectory -Force
}

if ($PSCmdlet.ShouldProcess("JustInTimeConfig", "Remove machine environment variable")) {
    [Environment]::SetEnvironmentVariable("JustInTimeConfig", $null, [EnvironmentVariableTarget]::Machine)
    Remove-Item Env:\JustInTimeConfig -ErrorAction SilentlyContinue
}

if ($WhatIfPreference) {
    Write-Host "T1JIT cleanup preview completed. No artifacts were removed." -ForegroundColor Cyan
}
else {
    Write-Host "T1JIT installation artifacts removed. OU=Servers and eligibility groups were preserved." -ForegroundColor Green
}