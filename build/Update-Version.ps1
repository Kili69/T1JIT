[CmdletBinding(DefaultParameterSetName = "Update")]
param(
    [Parameter(ParameterSetName = "Update")]
    [ValidateRange(0, 2147483647)]
    [int]$Major = 0,

    [Parameter(ParameterSetName = "Update")]
    [ValidateRange(0, 2147483647)]
    [int]$Minor = 1,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$BaseRef = "HEAD",

    [Parameter(Mandatory = $true, ParameterSetName = "Check")]
    [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$versionPath = Join-Path $repoRoot "VERSION"
$manifestPath = Join-Path $repoRoot "file-versions.json"
$versionPattern = '^(?<major>\d+)\.(?<minor>\d+)\.(?<date>\d{8})\.(?<counter>[1-9]\d*)$'
$metadataFiles = @("VERSION", "file-versions.json")

function Get-ChangedFiles {
    $trackedFiles = @(git -C $repoRoot diff --name-only $BaseRef)
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to determine changed files with git."
    }

    $untrackedFiles = @(git -C $repoRoot ls-files --others --exclude-standard)
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to determine untracked files with git."
    }

    @($trackedFiles + $untrackedFiles) |
        ForEach-Object { $_.Replace('\', '/') } |
        Where-Object { $_ -and $_ -notin $metadataFiles } |
        Where-Object { $_ -notmatch '(^|/)(bin|obj)/' } |
        Sort-Object -Unique
}

function Assert-VersionFormat {
    param([Parameter(Mandatory = $true)][string]$Version)

    if ($Version -notmatch $versionPattern) {
        throw "Version '$Version' does not match <Major>.<Minor>.<yyyyMMdd>.<counter>."
    }

    $parsedDate = [datetime]::MinValue
    if (-not [datetime]::TryParseExact(
        $Matches.date,
        "yyyyMMdd",
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::None,
        [ref]$parsedDate
    )) {
        throw "Version '$Version' contains an invalid calendar date."
    }
}

function Get-FileHashValue {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $absolutePath = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        return $null
    }

    (Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
}

if ($Check) {
    if (-not (Test-Path $versionPath) -or -not (Test-Path $manifestPath)) {
        throw "VERSION and file-versions.json must exist. Run build/Update-Version.ps1 first."
    }

    $version = (Get-Content $versionPath -Raw).Trim()
    Assert-VersionFormat -Version $version
    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

    if ($manifest.version -ne $version) {
        throw "VERSION and file-versions.json contain different versions."
    }

    $invalidFiles = @()
    foreach ($file in @(Get-ChangedFiles)) {
        $entries = @($manifest.files | Where-Object { $_.path -eq $file })
        $currentHash = Get-FileHashValue -RelativePath $file
        if ($entries.Count -ne 1 -or $entries[0].sha256 -ne $currentHash) {
            $invalidFiles += $file
        }
    }

    if ($invalidFiles.Count -gt 0) {
        throw "Changed files are missing or stale in file-versions.json: $($invalidFiles -join ', '). Run build/Update-Version.ps1."
    }

    Write-Host "Version $version is valid and covers all changed files." -ForegroundColor Green
    return
}

$date = Get-Date -Format "yyyyMMdd"
$counter = 1
if (Test-Path $versionPath) {
    $currentVersion = (Get-Content $versionPath -Raw).Trim()
    Assert-VersionFormat -Version $currentVersion
    if ($currentVersion -match $versionPattern -and
        [int]$Matches.major -eq $Major -and
        [int]$Matches.minor -eq $Minor -and
        $Matches.date -eq $date) {
        $counter = [int]$Matches.counter + 1
    }
}

$version = "$Major.$Minor.$date.$counter"
$changedFiles = @(Get-ChangedFiles)
if ($changedFiles.Count -eq 0) {
    throw "No changed files found."
}

Set-Content -Path $versionPath -Value $version -Encoding ASCII
[ordered]@{
    version = $version
    files = @($changedFiles | ForEach-Object {
        [ordered]@{
            path = $_
            sha256 = Get-FileHashValue -RelativePath $_
        }
    })
} | ConvertTo-Json -Depth 3 | Set-Content -Path $manifestPath -Encoding UTF8

Write-Host "Created version $version for $($changedFiles.Count) changed file(s)." -ForegroundColor Green