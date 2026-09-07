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
    Creates a complete T1JIT installation package.
.DESCRIPTION
    Copies every installation file from release into Installationspackage. Use
    BuildRelease to rebuild the release output before copying it.
.PARAMETER DestinationPath
    Package destination. The default is Installationspackage in the repository root.
.PARAMETER BuildRelease
    Runs release_build.ps1 before creating the installation package.
.EXAMPLE
    ./build/New-InstallationPackage.ps1
.EXAMPLE
    ./build/New-InstallationPackage.ps1 -BuildRelease
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationPath,

    [Parameter()]
    [switch]$BuildRelease
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$releasePath = Join-Path $repoRoot "release"
if ([string]::IsNullOrWhiteSpace($DestinationPath)) {
    $DestinationPath = Join-Path $repoRoot "Installationspackage"
}
elseif (-not [IO.Path]::IsPathRooted($DestinationPath)) {
    $DestinationPath = Join-Path $repoRoot $DestinationPath
}

if ($BuildRelease) {
    & (Join-Path $PSScriptRoot "release_build.ps1")
    if ($LASTEXITCODE -ne 0) {
        throw "Release build failed with exit code $LASTEXITCODE."
    }
}

if (-not (Test-Path -LiteralPath $releasePath -PathType Container)) {
    throw "Release folder not found: $releasePath"
}

if (Test-Path -LiteralPath $DestinationPath) {
    Remove-Item -LiteralPath $DestinationPath -Recurse -Force
}
New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
Copy-Item -Path (Join-Path $releasePath "*") -Destination $DestinationPath -Recurse -Force

$requiredFiles = @(
    "install-JIT.ps1",
    "VERSION",
    "file-versions.json",
    "modules/0.1/KjitCore.dll",
    "kjibweb/install-kjitweb.ps1",
    "kjibweb/publish-service/KjitWeb.dll"
)
foreach ($relativePath in $requiredFiles) {
    $packageFile = Join-Path $DestinationPath $relativePath
    if (-not (Test-Path -LiteralPath $packageFile -PathType Leaf)) {
        throw "Required installation file is missing: $packageFile"
    }
}

$fileCount = @(Get-ChildItem -LiteralPath $DestinationPath -File -Recurse).Count
Write-Host "Installation package created: $DestinationPath" -ForegroundColor Green
Write-Host "Files copied: $fileCount"
