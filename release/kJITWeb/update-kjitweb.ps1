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