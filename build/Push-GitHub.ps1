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
    Documents and pushes all commits not yet present on a GitHub remote branch.
.DESCRIPTION
    Fetches the selected remote branch, writes the outgoing commits and changed files
    to History.md, creates a versioned history commit, and pushes the complete branch.
.PARAMETER Remote
    Git remote name. The default is origin.
.PARAMETER Branch
    Local and remote branch name. The default is the current branch.
.EXAMPLE
    ./build/Push-GitHub.ps1
.EXAMPLE
    ./build/Push-GitHub.ps1 -Remote origin -Branch dev
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Remote = "origin",

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Branch
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$historyPath = Join-Path $repoRoot "History.md"
$entryMarker = "<!-- history-entries -->"

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $output = @(& git -C $repoRoot @Arguments)
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')"
    }

    $output
}

if ([string]::IsNullOrWhiteSpace($Branch)) {
    $Branch = (Invoke-Git -Arguments @("branch", "--show-current") | Select-Object -First 1).Trim()
}
if ([string]::IsNullOrWhiteSpace($Branch)) {
    throw "Unable to determine the current branch. Specify -Branch explicitly."
}

$remoteUrl = (Invoke-Git -Arguments @("remote", "get-url", "--push", $Remote) | Select-Object -First 1).Trim()
if ($remoteUrl -notmatch '(?i)(github\.com[/:])') {
    throw "Remote '$Remote' is not a GitHub remote: $remoteUrl"
}

$workingChanges = @(Invoke-Git -Arguments @("status", "--porcelain"))
if ($workingChanges.Count -gt 0) {
    throw "The working tree must be clean before preparing a documented push."
}

Invoke-Git -Arguments @("fetch", "--quiet", $Remote, $Branch) | Out-Null
$remoteRef = "refs/remotes/$Remote/$Branch"
$localTip = (Invoke-Git -Arguments @("rev-parse", "HEAD") | Select-Object -First 1).Trim()
$outgoingCommits = @(Invoke-Git -Arguments @("rev-list", "--reverse", "$remoteRef..$localTip"))

if ($outgoingCommits.Count -eq 0) {
    Write-Host "No commits to push to $Remote/$Branch." -ForegroundColor Yellow
    return
}

$history = Get-Content -LiteralPath $historyPath -Raw
if (-not $history.Contains($entryMarker)) {
    throw "History entry marker not found in $historyPath."
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
$entryLines = @(
    "",
    "## $timestamp - ``$Branch`` to ``$Remote/$Branch``",
    "",
    "Commits:",
    ""
)

foreach ($commit in $outgoingCommits) {
    $shortHash = (Invoke-Git -Arguments @("rev-parse", "--short=7", $commit) | Select-Object -First 1).Trim()
    $subject = (Invoke-Git -Arguments @("show", "-s", "--format=%s", $commit) | Select-Object -First 1).Trim()
    $entryLines += "<!-- commit:$commit -->"
    $entryLines += "- ``$shortHash`` $subject"
}

$entryLines += @("", "Changed files:", "")
$changedFiles = @(Invoke-Git -Arguments @(
    "diff", "--name-status", "$remoteRef..$localTip", "--", ".",
    ":(exclude)History.md", ":(exclude)**/bin/**", ":(exclude)**/obj/**"
))
foreach ($change in $changedFiles) {
    $entryLines += "- ``$($change -replace "`t", ' -> ')``"
}
$entryLines += ""

$entry = $entryLines -join [Environment]::NewLine
$updatedHistory = $history.Replace($entryMarker, "$entryMarker$entry")
Set-Content -LiteralPath $historyPath -Value $updatedHistory -Encoding UTF8

Invoke-Git -Arguments @("add", "--", "History.md") | Out-Null
Invoke-Git -Arguments @("commit", "-m", "Document GitHub push history") | Out-Null
Invoke-Git -Arguments @("push", $Remote, "HEAD:$Branch") | Out-Null

$pushedTip = (Invoke-Git -Arguments @("rev-parse", "HEAD") | Select-Object -First 1).Trim()
Write-Host "Documented and pushed $($outgoingCommits.Count) commit(s) to $Remote/$Branch." -ForegroundColor Green
Write-Host "Remote tip: $pushedTip"
