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
    Versions files staged for a Git commit.
.DESCRIPTION
    Runs build/Update-Version.ps1 in staged mode and adds the generated repository
    version metadata to the current commit. Any error stops the commit.
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

    Write-Host "Staged files and version metadata are ready for commit." -ForegroundColor Green
}
catch {
    Write-Error $_
    exit 1
}
