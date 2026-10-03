<#

.SYNOPSIS
    Versions staged files and refreshes the distributable release directory.
.DESCRIPTION
    Runs build/Update-Version.ps1 in staged mode, builds release from the current
    source tree with that version, and adds the generated metadata and release files
    plus the versioned README heading to the current commit. Any error stops the commit.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try {
    $repoRoot = (& git rev-parse --show-toplevel).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
        throw "Unable to determine the Git repository root."
    }

    & (Join-Path $repoRoot "build/Update-Version.ps1") -Staged
    git -C $repoRoot add -- VERSION file-versions.json README.md src/Powershell/modules/Just-In-time.psd1
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to stage version metadata and README.md."
    }

    & (Join-Path $repoRoot "build/release_build.ps1") -SkipVersionCheck

    git -C $repoRoot add -- release
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to stage the refreshed release directory."
    }

    $releaseVersion = (Get-Content (Join-Path $repoRoot "release/VERSION") -Raw).Trim()
    $repositoryVersion = (Get-Content (Join-Path $repoRoot "VERSION") -Raw).Trim()
    if ($releaseVersion -ne $repositoryVersion) {
        throw "Release version '$releaseVersion' does not match repository version '$repositoryVersion'."
    }

    $releaseDll = Join-Path $repoRoot "release/kJITWeb/publish-service/KjitWeb.dll"
    $productVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo($releaseDll).ProductVersion
    if ($productVersion -notlike "$repositoryVersion+*") {
        throw "Release KjitWeb version '$productVersion' does not match repository version '$repositoryVersion'."
    }

    Write-Host "Staged files, version metadata, and release $repositoryVersion are ready for commit." -ForegroundColor Green
}
catch {
    Write-Error $_
    exit 1
}
