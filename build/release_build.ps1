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
    This script builds the Just-In-Time solution's and copy all required files into the relase folder.
.DESCRIPTION 
    This copy all powershell scripts and modules to the release folder, builds the KjitWeb service as a Windows Service, and copies the published output along with necessary assets (install script, logo, sanitized config) to the release directory. 
    The resulting structure is ready for distribution.
.NOTES
    Script Version 0.1.20260427
    Script Version 0.1.20260507
        changed the Get-Config command from Get-JITConfig to Get-JitConfiguration to match the new function name in the module.
        The new function now support the configuration from the AD or JSON file
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region variable definitions
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$versionScriptPath = Join-Path $PSScriptRoot "Update-Version.ps1"
$versionPath = Join-Path $repoRoot "VERSION"
$fileVersionsPath = Join-Path $repoRoot "file-versions.json"
$kjitWebRoot = Join-Path $repoRoot "src/C#/Kjitweb"
$csprojPath = Join-Path $kjitWebRoot "KjitWeb.csproj"
$publishOutputDir = Join-Path $kjitWebRoot "publish-service"

$kjitCoreRoot = Join-Path $repoRoot "src/C#/KjitCore"
$kjitCoreProjPath = Join-Path $kjitCoreRoot "KjitCore.csproj"
$kjitCoreNet48BuildDir = Join-Path $kjitCoreRoot "bin/Release/net48"
$kjitCoreDllSource = Join-Path $kjitCoreNet48BuildDir "KjitCore.dll"

$psSourceRoot = Join-Path $repoRoot "src/PowerShell"
$psModulesSourceDir = Join-Path $psSourceRoot "modules"
$psScriptsSourceDir = Join-Path $psSourceRoot "Scripts"

# Requested target folder name: release/kjibweb
$releaseRoot = Join-Path $repoRoot "release"
$releaseKjibwebDir = Join-Path $releaseRoot "kjibweb"
$releasePublishDir = Join-Path $releaseKjibwebDir "publish-service"
$releaseModulesDir = Join-Path $releaseRoot "modules"
$releaseModulesVersionDir = Join-Path $releaseModulesDir "0.1"

$installScriptSource = Join-Path $kjitWebRoot "install-kjitweb.ps1"
$logoSource = Join-Path $kjitWebRoot "kjitlogo.png"
$appSettingsSource = Join-Path $kjitWebRoot "appsettings.json"
$appSettingsProdSource = Join-Path $kjitWebRoot "appsettings.Production.json"
#endregion

<#
.SYNOPSIS
    Copies a JSON configuration file while removing sensitive or environment-specific properties.   
.DESCRIPTION
    This function reads a JSON config file, removes properties that may contain sensitive information (like 'AllowedHosts' and 'DebugLog.Path'), and writes the sanitized config to a new location. This is useful for preparing configuration files for distribution without exposing sensitive details.
.PARAMETER SourcePath
    The file path of the source JSON configuration file to be sanitized and copied. This should be a valid path to an existing JSON file.
.PARAMETER DestinationPath
    The file path where the sanitized JSON configuration file will be saved. This should be a valid path where the script has write permissions.    
.EXAMPLE
    Copy-SanitizedJsonConfig -SourcePath "C:\Configs\appsettings.json" -DestinationPath "C:\Release\appsettings.json"
    This command copies the 'appsettings.json' file from 'C:\Configs', removes the 'AllowedHosts' and 'DebugLog.Path' properties, and saves the sanitized config to 'C:\Release\appsettings.json'.
.NOTES  
#>
function Copy-SanitizedJsonConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    $config = Get-Content $SourcePath -Raw | ConvertFrom-Json
    if ($null -ne $config.PSObject.Properties['AllowedHosts']) {
        $config.PSObject.Properties.Remove('AllowedHosts')
    }

    if ($null -ne $config.PSObject.Properties['DebugLog']) {
        if ($null -ne $config.DebugLog.PSObject.Properties['Path']) {
            $config.DebugLog.PSObject.Properties.Remove('Path')
        }

        if (@($config.DebugLog.PSObject.Properties).Count -eq 0) {
            $config.PSObject.Properties.Remove('DebugLog')
        }
    }

    $config | ConvertTo-Json -Depth 20 | Set-Content $DestinationPath -Encoding UTF8
}

# Main script execution starts here

& $versionScriptPath -Check
$releaseVersion = (Get-Content $versionPath -Raw).Trim()

Remove-Item $releaseRoot -Recurse -Force -ErrorAction SilentlyContinue # Clean up any existing release folder to ensure a fresh start.

Write-Host "Copying PowerShell scripts and modules to release..."
if (-not (Test-Path $psScriptsSourceDir)) {
    throw "PowerShell scripts source directory not found: $psScriptsSourceDir"
}
if (-not (Test-Path $psModulesSourceDir)) {
    throw "PowerShell modules source directory not found: $psModulesSourceDir"
}

New-Item -Path $releaseRoot -ItemType Directory -Force | Out-Null
New-Item -Path $releaseModulesDir -ItemType Directory -Force | Out-Null
Copy-Item $versionPath $releaseRoot -Force
Copy-Item $fileVersionsPath $releaseRoot -Force
Copy-Item (Join-Path $psScriptsSourceDir "*.ps1") $releaseRoot -Force
Copy-Item (Join-Path $psModulesSourceDir "*") $releaseModulesDir -Recurse -Force

Write-Host "Building KjitCore (net48)..."
dotnet build $kjitCoreProjPath -c Release -f net48
if ($LASTEXITCODE -ne 0) {
    throw "KjitCore build failed (dotnet build exit code: $LASTEXITCODE)."
}

if (-not (Test-Path $kjitCoreDllSource)) {
    throw "KjitCore.dll not found after build: $kjitCoreDllSource"
}

Write-Host "Copying KjitCore.dll to release modules..."
New-Item -Path $releaseModulesVersionDir -ItemType Directory -Force | Out-Null
Copy-Item $kjitCoreDllSource (Join-Path $releaseModulesVersionDir "KjitCore.dll") -Force

Write-Host "Building KjitWeb service..."
dotnet publish $csprojPath -c Release -r win-x64 --self-contained false -o $publishOutputDir "-p:InformationalVersion=$releaseVersion"
if ($LASTEXITCODE -ne 0) {
    throw "KjitWeb build failed (dotnet publish exit code: $LASTEXITCODE)."
}

Write-Host "Preparing release folder: $releaseKjibwebDir"
if (Test-Path $releaseKjibwebDir) {
    Remove-Item $releaseKjibwebDir -Recurse -Force
}
New-Item -Path $releaseKjibwebDir -ItemType Directory -Force | Out-Null

Write-Host "Copying published service files..."
Copy-Item $publishOutputDir $releasePublishDir -Recurse -Force

if (-not (Test-Path $installScriptSource)) {
    throw "Install script not found: $installScriptSource"
}
if (-not (Test-Path $logoSource)) {
    throw "Logo file not found: $logoSource"
}

Write-Host "Copying installation assets..."
Copy-Item $installScriptSource (Join-Path $releaseKjibwebDir "install-kjitweb.ps1") -Force
Copy-Item $logoSource (Join-Path $releaseKjibwebDir "kjitlogo.png") -Force

# Keep appsettings next to install script (used by install-kjitweb.ps1 for DebugLog path fallback).
if (Test-Path $appSettingsSource) {
    Copy-SanitizedJsonConfig $appSettingsSource (Join-Path $releaseKjibwebDir "appsettings.json")
    copy-SanitizedJsonConfig $appSettingsProdSource (Join-Path $releaseKjibwebDir "appsettings.Production.json")
    Remove-Item (Join-Path $releaseKjibwebDir "appsettings.Development.json") -ErrorAction SilentlyContinue
}   

Write-Host "Release package created: $releaseKjibwebDir" -ForegroundColor Green
