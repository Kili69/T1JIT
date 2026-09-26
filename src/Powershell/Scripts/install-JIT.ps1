<#
Script Info 

Author: Andreas Lucas [MSFT]
Download: https://github.com/Kili69/T1JIT

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
    Installation of just in time solution
.DESCRIPTION
    This script install the Just-IN-Time Solution. The purpose of this script is to copy scripts into
    program files folder,the modules into the modules and run the configuration script. The resulting
    JIT configuration path is passed to the optional KjitWeb installation.
.PARAMETER JitConfigFile
    Existing JIT.config path used for unattended configuration. When omitted during an interactive
    installation, the path saved by Config-JIT.ps1 is used automatically.
.PARAMETER InstallWeb
    Installs KjitWeb after the PowerShell configuration completes. In silent mode,
    provide the web parameters to avoid interactive prompts. Ignored for
    AllowedClient/CompanyName/Port/DebugLogPath when an existing KjitWeb installation
    is detected, because that case runs update-kjitweb.ps1 instead, which updates the
    service in place without changing its configuration.
.PARAMETER AllowedClient
    Hostname or IP address allowed to access KjitWeb. Only used for a new KjitWeb
    installation; ignored when an existing installation is updated.
.PARAMETER CompanyName
    Company name displayed by KjitWeb. Only used for a new KjitWeb installation;
    ignored when an existing installation is updated.
.PARAMETER Port
    TCP port used by KjitWeb. Only used for a new KjitWeb installation; ignored when
    an existing installation is updated.
.PARAMETER DebugLogPath
    Optional KjitWeb debug log path. Only used for a new KjitWeb installation; ignored
    when an existing installation is updated.
Version 0.1.20240918
    Initial Version
Version 0.1.20241006
    Overwrites existing versions
    change the working folder to program folder
Version 0.1.20241227
    by Andreas Luy
    Fixing minor bugs
Version 0.1.20250830
    The delegation-config.ps1 is replaced with PS-Module command Add-JitDelegation
Version 0.1.20260925
    Detects an existing installation by locating a previously saved JIT.config
    (JitConfigFile parameter, JustInTimeConfig environment variable, or an existing
    Config-JIT.ps1 in the target folder). When found, the installation directory
    prompt is skipped and the resolved configuration file is passed automatically
    to Config-JIT.ps1, which then runs in update mode.
    Also detects an existing KjitWeb installation (a "KjitWeb" service backed by a
    deployed KjitWeb.exe) and runs update-kjitweb.ps1 instead of install-kjitweb.ps1,
    so the service is refreshed in place without asking for AllowedClient, CompanyName,
    Port, or DebugLogPath again. When updating an existing JIT installation that
    already has KjitWeb installed, the "Install the KjitWeb website...?" prompt is
    skipped entirely and KjitWeb is updated immediately.
    Fails fast with an actionable message if the Just-In-Time module (KjitCore.dll) is
    already loaded in the current PowerShell session, or if its files are locked by
    another PowerShell session/scheduled task, instead of a raw file-in-use error.
.NOTES
    The installation transcript is written to the current user's temporary directory.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$JitProgramFolder,
    [Parameter (Mandatory = $false)]
    [string]$JitConfigFile,
    [switch]$silent,
    [switch]$InstallWeb,
    [string]$AllowedClient,
    [string]$CompanyName,
    [int]$Port,
    [string]$DebugLogPath
)

$logPath = Join-Path ([IO.Path]::GetTempPath()) ("T1JIT-install-{0:yyyyMMdd-HHmmss}-{1}.log" -f (Get-Date), $PID)
$transcriptStarted = $false
Start-Transcript -Path $logPath -Force -ErrorAction Stop | Out-Null
$transcriptStarted = $true
Write-Host "Installation log: $logPath" -ForegroundColor Cyan

function Test-ActiveDirectoryRsat {
    $activeDirectoryModule = Get-Module -ListAvailable -Name ActiveDirectory |
        Select-Object -First 1
    if ($null -eq $activeDirectoryModule) {
        return $false
    }

    try {
        Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false
    }
    catch {
        Write-Warning "The Active Directory module was found but could not be loaded: $($_.Exception.Message)"
        return $false
    }

    $requiredCommands = @(
        "Get-ADComputer",
        "Get-ADDomain",
        "Get-ADForest",
        "Get-ADGroup",
        "Get-ADOptionalFeature",
        "Get-ADOrganizationalUnit",
        "Get-ADServiceAccount",
        "Install-ADServiceAccount",
        "New-ADOrganizationalUnit",
        "New-ADServiceAccount",
        "Set-ADServiceAccount",
        "Test-ADServiceAccount"
    )
    $missingCommands = @($requiredCommands | Where-Object {
        $null -eq (Get-Command -Name $_ -Module ActiveDirectory -ErrorAction SilentlyContinue)
    })

    if ($missingCommands.Count -gt 0) {
        Write-Warning "The Active Directory module is incomplete. Missing commands: $($missingCommands -join ', ')"
        return $false
    }

    return $true
}

if ([string]::IsNullOrWhiteSpace($JitProgramFolder)) {
    $JitProgramFolder = Join-Path $env:ProgramFiles "Just-In-Time"
}

# Resolve an existing JIT.config so an update reuses it automatically instead of
# re-asking questions that were already answered during a previous installation.
$resolvedJitConfigFile = $JitConfigFile
if ([string]::IsNullOrWhiteSpace($resolvedJitConfigFile)) {
    $resolvedJitConfigFile = $env:JustInTimeConfig
}
if ([string]::IsNullOrWhiteSpace($resolvedJitConfigFile)) {
    $resolvedJitConfigFile = [Environment]::GetEnvironmentVariable("JustInTimeConfig", [EnvironmentVariableTarget]::Machine)
}
$hasExistingConfigFile = (-not [string]::IsNullOrWhiteSpace($resolvedJitConfigFile)) -and (Test-Path -LiteralPath $resolvedJitConfigFile -PathType Leaf)
$hasExistingInstallation = $hasExistingConfigFile -or (Test-Path -LiteralPath (Join-Path $JitProgramFolder "Config-JIT.ps1") -PathType Leaf)

$TargetDir = $JitProgramFolder
if (!$silent) {
    Write-Host "Welcome the the Just-In-Time administration program installation"
    if ($hasExistingInstallation) {
        Write-Host "Existing Just-In-Time installation detected in '$TargetDir'. Updating this installation." -ForegroundColor Cyan
    } else {
        $requestedTargetDir = Read-Host "Installation Directory ($JitProgramFolder)"
        if (![string]::IsNullOrWhiteSpace($requestedTargetDir)) {
            $TargetDir = $requestedTargetDir
        }
    }
}
try {
    if (-not (Test-ActiveDirectoryRsat)) {
        Write-Host "The Active Directory RSAT PowerShell module is required but is not installed or usable." -ForegroundColor Red
        Write-Host "Windows Server: Install-WindowsFeature RSAT-AD-PowerShell" -ForegroundColor Cyan
        Write-Host "Windows 10/11: Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0" -ForegroundColor Cyan
        Write-Host "Installation aborted." -ForegroundColor Red
        return
    }

    # KjitCore.dll is loaded into the process with Add-Type and cannot be unloaded from a
    # running PowerShell session. If an earlier command in this session (e.g. Add-JitDelegation,
    # Get-JITconfig, or a previous Config-JIT.ps1 run) already loaded the Just-In-Time module,
    # overwriting its files below would fail with a file-in-use error. Detect this up front and
    # fail fast with an actionable message instead of leaving a half-completed update behind.
    $loadedKjitCore = [AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq "KjitCore" } | Select-Object -First 1
    if ($null -ne $loadedKjitCore) {
        throw "The Just-In-Time module (KjitCore.dll) is already loaded in this PowerShell session (from '$($loadedKjitCore.Location)'). Close this PowerShell window, open a new one, and run install-JIT.ps1 again."
    }

    if (!(Test-Path -Path $TargetDir)) {
        New-Item -Path $TargetDir -ItemType Directory -ErrorAction Stop
    }
    #copy program files
    Copy-Item .\Config-JIT.ps1 $TargetDir -ErrorAction Stop -Force -Verbose
    Copy-Item .\Config-JITUI.ps1 $TargetDir -ErrorAction Stop -Force -Verbose
    Copy-Item .\ElevateUser.ps1 $TargetDir -ErrorAction Stop -Force -Verbose
    Copy-Item .\RequestAdminAccessUI.ps1 $TargetDir -ErrorAction Stop -Force -Verbose
    Copy-Item .\Tier1LocalAdminGroup.ps1 $TargetDir -ErrorAction Stop -Force -Verbose
    if (!(Test-Path "$($env:ProgramFiles)\WindowsPowerShell\Modules\Just-In-Time") ){
        New-Item "$($env:ProgramFiles)\WindowsPowerShell\Modules\Just-In-Time" -ItemType Directory -ErrorAction Stop -Verbose
    }
    try {
        Copy-Item .\modules\* -Destination "$($env:ProgramFiles)\WindowsPowerShell\Modules\Just-In-time" -Recurse -ErrorAction Stop -Force
    }
    catch {
        # A locked KjitCore.dll almost always means another PowerShell session (or a
        # currently running Just-In-Time scheduled task, e.g. ElevateUser.ps1) still has the
        # module loaded. Surface an actionable message instead of the raw IO exception.
        throw "Could not update the Just-In-Time PowerShell module files (e.g. KjitCore.dll). This usually means the module is still loaded in another PowerShell window, or a Just-In-Time scheduled task (e.g. ElevateUser.ps1) is currently running. Close all other PowerShell sessions using the Just-In-Time module, wait for any running Just-In-Time scheduled task to finish, and run install-JIT.ps1 again. Details: $($_.Exception.Message)"
    }
    Set-Location -Path $TargetDir
    $configArguments = @{}
    if ($silent) {
        $configArguments.quiet = $true
    }
    if (![string]::IsNullOrWhiteSpace($resolvedJitConfigFile)) {
        # Passing the resolved path lets Config-JIT.ps1 detect an update and only
        # prompt for settings introduced since this installation was last configured.
        $configArguments.configurationFile = $resolvedJitConfigFile
    }
    if (!$silent) {
        Write-Host "Start the configuration: $TargetDir\config-JIT.ps1"
    }

    $configuration = & "$TargetDir\config-JIT.ps1" @configArguments
    if ($null -eq $configuration) {
        if ($silent) {
            throw "JIT configuration did not complete successfully. Review the preceding errors."
        }
        return
    }

    # An existing service backed by an already-deployed binary means KjitWeb was
    # installed before. Detected up-front so an update to the JIT installation can
    # silently update KjitWeb too, without asking again whether to install it.
    $kjitWebInstallFolder = Join-Path $env:ProgramFiles "KJITWEB"
    $kjitWebAlreadyInstalled = (Test-Path -LiteralPath (Join-Path $kjitWebInstallFolder "KjitWeb.exe") -PathType Leaf) -and
        ($null -ne (Get-Service -Name "KjitWeb" -ErrorAction SilentlyContinue))

    $installWebRequested = $InstallWeb
    if ($hasExistingInstallation -and $kjitWebAlreadyInstalled) {
        # Updating an existing JIT installation that already has KjitWeb installed:
        # update it immediately, without asking whether to (re)install it.
        $installWebRequested = $true
    } elseif (!$silent) {
        $installWebResponse = Read-Host "Install the KjitWeb website as a Windows service? [Y/n]"
        $installWebRequested = [string]::IsNullOrWhiteSpace($installWebResponse) -or $installWebResponse.Trim() -match '^(?i:y|yes)$'
    }

    if ($installWebRequested) {
            $webInstallerCandidates = @(
                (Join-Path $PSScriptRoot "kJITWeb\install-kjitweb.ps1"),
                (Join-Path $PSScriptRoot "..\..\C#\Kjitweb\install-kjitweb.ps1")
            )
            $webInstallerPath = $webInstallerCandidates |
                Where-Object { Test-Path -Path $_ -PathType Leaf } |
                Select-Object -First 1

            if ([string]::IsNullOrWhiteSpace($webInstallerPath)) {
                throw "KjitWeb installer not found. Expected: $($webInstallerCandidates -join ', ')"
            }

            # Prefer update-kjitweb.ps1 when KjitWeb is already installed, so the
            # running installation is refreshed in place without asking again for
            # AllowedClient/CompanyName/Port.
            $webUpdaterCandidates = @(
                (Join-Path $PSScriptRoot "kJITWeb\update-kjitweb.ps1"),
                (Join-Path $PSScriptRoot "..\..\C#\Kjitweb\update-kjitweb.ps1")
            )
            $webUpdaterPath = $webUpdaterCandidates |
                Where-Object { Test-Path -Path $_ -PathType Leaf } |
                Select-Object -First 1

            if ($kjitWebAlreadyInstalled -and -not [string]::IsNullOrWhiteSpace($webUpdaterPath)) {
                if (!$silent) {
                    Write-Host "Existing KjitWeb installation detected. Updating the service in place; no configuration parameters are asked." -ForegroundColor Cyan
                }
                & $webUpdaterPath
            } else {
                $effectiveJitConfigFile = $JitConfigFile
                if ([string]::IsNullOrWhiteSpace($effectiveJitConfigFile)) {
                    $effectiveJitConfigFile = $env:JustInTimeConfig
                }
                if ([string]::IsNullOrWhiteSpace($effectiveJitConfigFile)) {
                    $effectiveJitConfigFile = [Environment]::GetEnvironmentVariable("JustInTimeConfig", [EnvironmentVariableTarget]::Machine)
                }
                if ([string]::IsNullOrWhiteSpace($effectiveJitConfigFile) -or
                    -not (Test-Path -LiteralPath $effectiveJitConfigFile -PathType Leaf)) {
                    throw "KjitWeb installation requires the JIT configuration file created by Config-JIT.ps1. Run the configuration again or provide -JitConfigFile."
                }

                $webInstallerArguments = @{ JitConfig = $effectiveJitConfigFile }
                if (![string]::IsNullOrWhiteSpace($AllowedClient)) {
                    $webInstallerArguments.AllowedClient = $AllowedClient
                }
                if (![string]::IsNullOrWhiteSpace($CompanyName)) {
                    $webInstallerArguments.CompanyName = $CompanyName
                }
                if ($Port -gt 0) {
                    $webInstallerArguments.Port = $Port
                }
                if (![string]::IsNullOrWhiteSpace($DebugLogPath)) {
                    $webInstallerArguments.DebugLogPath = $DebugLogPath
                }

                & $webInstallerPath @webInstallerArguments
            }
    }
} 
catch [System.UnauthorizedAccessException] {
    throw "Access denied. Run the installation as administrator. $($_.Exception.Message)"
}
catch{
    throw "Installation failed: $($_.Exception.Message)"
}
finally {
    if ($transcriptStarted) {
        Stop-Transcript | Out-Null
    }
    Write-Host "Installation log: $logPath" -ForegroundColor Cyan
}
