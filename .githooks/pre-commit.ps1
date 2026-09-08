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
    Versions staged files and refreshes the distributable release directory.
.DESCRIPTION
    Runs build/Update-Version.ps1 in staged mode, builds release from the current
    source tree with that version, and adds the generated metadata and release files
    to the current commit. Any error stops the commit.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

try {
    $repoRoot = (& git rev-parse --show-toplevel).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
        throw "Unable to determine the Git repository root."
    }

    & (Join-Path $repoRoot "build/Update-Version.ps1") -Staged
    git -C $repoRoot add -- VERSION file-versions.json
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to stage VERSION and file-versions.json."
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

    $releaseDll = Join-Path $repoRoot "release/kjibweb/publish-service/KjitWeb.dll"
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
