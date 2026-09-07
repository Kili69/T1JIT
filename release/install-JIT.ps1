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
    provide the web parameters to avoid interactive prompts.
.PARAMETER AllowedClient
    Hostname or IP address allowed to access KjitWeb.
.PARAMETER CompanyName
    Company name displayed by KjitWeb.
.PARAMETER Port
    TCP port used by KjitWeb.
.PARAMETER DebugLogPath
    Optional KjitWeb debug log path.
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

$TargetDir = $JitProgramFolder
if (!$silent) {
    Write-Host "Welcome the the Just-In-Time administration program installation"
    $requestedTargetDir = Read-Host "Installation Directory ($JitProgramFolder)"
    if (![string]::IsNullOrWhiteSpace($requestedTargetDir)) {
        $TargetDir = $requestedTargetDir
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
    Copy-Item .\modules\* -Destination "$($env:ProgramFiles)\WindowsPowerShell\Modules\Just-In-time" -Recurse -ErrorAction Stop -Force 
    Set-Location -Path $TargetDir
    $configArguments = @{}
    if ($silent) {
        $configArguments.quiet = $true
    }
    if (![string]::IsNullOrWhiteSpace($JitConfigFile)) {
        $configArguments.configurationFile = $JitConfigFile
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

    $installWebRequested = $InstallWeb
    if (!$silent) {
        $installWebResponse = Read-Host "Install the KjitWeb website as a Windows service? [Y/n]"
        $installWebRequested = [string]::IsNullOrWhiteSpace($installWebResponse) -or $installWebResponse.Trim() -match '^(?i:y|yes)$'
    }

    if ($installWebRequested) {
            $webInstallerCandidates = @(
                (Join-Path $PSScriptRoot "kjibweb\install-kjitweb.ps1"),
                (Join-Path $PSScriptRoot "..\..\C#\Kjitweb\install-kjitweb.ps1")
            )
            $webInstallerPath = $webInstallerCandidates |
                Where-Object { Test-Path -Path $_ -PathType Leaf } |
                Select-Object -First 1

            if ([string]::IsNullOrWhiteSpace($webInstallerPath)) {
                throw "KjitWeb installer not found. Expected: $($webInstallerCandidates -join ', ')"
            }

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
