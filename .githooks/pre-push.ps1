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
    Rejects GitHub pushes whose commits are missing from History.md.
.DESCRIPTION
    Git invokes this hook before a push and supplies ref updates on standard input.
    Commits created by the history workflow are accepted because they modify History.md.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$RemoteName,

    [Parameter(Position = 1)]
    [string]$RemoteUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($RemoteUrl -notmatch '(?i)(github\.com[/:])') {
    exit 0
}

$repoRoot = (& git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Unable to determine the Git repository root."
}

$historyPath = Join-Path $repoRoot "History.md"
$history = Get-Content -LiteralPath $historyPath -Raw
if ($history -notmatch '<!-- history-enforcement-start:(?<hash>[0-9a-f]{40}) -->') {
    throw "History enforcement marker is missing from History.md."
}
$enforcementStart = $Matches.hash
$zeroHash = "0" * 40
$refUpdates = [Console]::In.ReadToEnd() -split "`r?`n" | Where-Object { $_ }
$undocumented = [Collections.Generic.List[string]]::new()

foreach ($update in $refUpdates) {
    $parts = $update -split '\s+'
    if ($parts.Count -lt 4 -or $parts[1] -eq $zeroHash) {
        continue
    }

    $localHash = $parts[1]
    $remoteHash = $parts[3]
    $candidates = @(& git -C $repoRoot rev-list --reverse "$enforcementStart..$localHash")
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to determine commits included in the push."
    }

    foreach ($commit in $candidates) {
        if ($remoteHash -ne $zeroHash) {
            & git -C $repoRoot merge-base --is-ancestor $commit $remoteHash 2>$null
            if ($LASTEXITCODE -eq 0) {
                continue
            }
        }

        $changedFiles = @(& git -C $repoRoot diff-tree --no-commit-id --name-only -r $commit)
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to inspect commit $commit."
        }
        $historyCommitFiles = @("History.md", "VERSION", "file-versions.json")
        $otherChangedFiles = @($changedFiles | Where-Object { $_ -notin $historyCommitFiles })
        if ($changedFiles -contains "History.md" -and $otherChangedFiles.Count -eq 0) {
            continue
        }
        if (-not $history.Contains("<!-- commit:$commit -->")) {
            $undocumented.Add($commit)
        }
    }
}

if ($undocumented.Count -gt 0) {
    Write-Error "GitHub push rejected: $($undocumented.Count) commit(s) are not documented in History.md. Run ./build/Push-GitHub.ps1 instead of git push."
    exit 1
}

exit 0
