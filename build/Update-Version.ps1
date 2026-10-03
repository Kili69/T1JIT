<#
.SYNOPSIS
    Creates or validates the repository version metadata for a commit.
.DESCRIPTION
    In update mode, determines files changed relative to BaseRef, creates a version in
    the format <Major>.<Minor>.<yyyyMMdd>.<counter>, and writes VERSION plus
    file-versions.json. Every changed file receives the same version and its current
    SHA-256 hash in the manifest.

    In check mode, validates the version format, manifest version, and changed-file
    versions and hashes. Generated files below bin and obj and the version metadata
    files themselves are excluded from changed-file tracking.
.PARAMETER Major
    Major component used when creating a version. The default is 0.
.PARAMETER Minor
    Minor component used when creating a version. The default is 2.
.PARAMETER BaseRef
    Git reference against which changed files are determined. Use HEAD before a local
    commit or the target branch when versioning several commits. The default is HEAD.
.PARAMETER Staged
    Versions only files currently staged for commit. This mode is intended for the
    repository pre-commit hook and cannot be combined with Check.
.PARAMETER Check
    Validates existing metadata without changing files.
.EXAMPLE
    ./build/Update-Version.ps1
    Creates metadata for uncommitted changes relative to HEAD.
.EXAMPLE
    ./build/Update-Version.ps1 -BaseRef origin/main
    Creates metadata for all changes relative to origin/main.
.EXAMPLE
    ./build/Update-Version.ps1 -Check -BaseRef HEAD^
    Validates the most recent commit and its changed files.
.EXAMPLE
    ./build/Update-Version.ps1 -Staged
    Creates metadata only for files currently staged for commit.
.OUTPUTS
    None. The script writes status information to the host and throws on validation
    or Git errors.
#>

[CmdletBinding(DefaultParameterSetName = "Update")]
param(
    [Parameter(ParameterSetName = "Update")]
    [ValidateRange(0, 2147483647)]
    [int]$Major = 0,

    [Parameter(ParameterSetName = "Update")]
    [ValidateRange(0, 2147483647)]
    [int]$Minor = 2,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$BaseRef = "HEAD",

    [Parameter(ParameterSetName = "Update")]
    [switch]$Staged,

    [Parameter(Mandatory = $true, ParameterSetName = "Check")]
    [switch]$Check
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$versionPath = Join-Path $repoRoot "VERSION"
$manifestPath = Join-Path $repoRoot "file-versions.json"
$moduleManifestRelativePath = "src/Powershell/modules/Just-In-time.psd1"
$moduleManifestPath = Join-Path $repoRoot $moduleManifestRelativePath
$versionPattern = '^(?<major>\d+)\.(?<minor>\d+)\.(?<date>\d{8})\.(?<counter>[1-9]\d*)$'
$metadataFiles = @("VERSION", "file-versions.json")

<#
.SYNOPSIS
    Returns versionable files changed relative to BaseRef.
.DESCRIPTION
    Combines tracked Git differences and untracked files, normalizes path separators,
    and excludes metadata plus generated bin and obj content.
#>
function Get-ChangedFiles {
    if ($Staged) {
        $trackedFiles = @(git -C $repoRoot diff --cached --name-only --diff-filter=ACMR)
    }
    else {
        $trackedFiles = @(git -C $repoRoot diff --name-only --diff-filter=ACMR $BaseRef)
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to determine changed files with git."
    }

    $untrackedFiles = @()
    if (-not $Staged) {
        $untrackedFiles = @(git -C $repoRoot ls-files --others --exclude-standard)
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to determine untracked files with git."
        }
    }

    @($trackedFiles + $untrackedFiles) |
        ForEach-Object { $_.Replace('\', '/') } |
        Where-Object { $_ -and $_ -notin $metadataFiles } |
        Where-Object { $_ -notmatch '(^|/)(bin|obj)/' } |
        Sort-Object -Unique
}

<#
.SYNOPSIS
    Validates the repository version syntax and calendar date.
#>
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

<#
.SYNOPSIS
    Returns the lowercase SHA-256 hash for a repository-relative file.
#>
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

    $moduleManifest = Import-PowerShellDataFile -LiteralPath $moduleManifestPath
    if ([string]$moduleManifest.ModuleVersion -ne $version) {
        throw "PowerShell module version '$($moduleManifest.ModuleVersion)' does not match repository version '$version'."
    }

    $invalidFiles = @()
    foreach ($file in @(Get-ChangedFiles)) {
        $entries = @($manifest.files | Where-Object { $_.path -eq $file })
        $currentHash = Get-FileHashValue -RelativePath $file
        if ($entries.Count -ne 1 -or
            $entries[0].version -ne $version -or
            $entries[0].sha256 -ne $currentHash) {
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
$moduleManifestContent = Get-Content -LiteralPath $moduleManifestPath -Raw
$updatedModuleManifestContent = $moduleManifestContent -replace "(?m)^ModuleVersion\s*=\s*'[^']+'", "ModuleVersion = '$version'"
if ($updatedModuleManifestContent -eq $moduleManifestContent -and
    $moduleManifestContent -notmatch "(?m)^ModuleVersion\s*=\s*'$([regex]::Escape($version))'") {
    throw "ModuleVersion was not found in '$moduleManifestRelativePath'."
}
[System.IO.File]::WriteAllText(
    $moduleManifestPath,
    $updatedModuleManifestContent,
    [System.Text.UTF8Encoding]::new($false)
)

$changedFiles = @(Get-ChangedFiles)
if ($moduleManifestRelativePath -notin $changedFiles) {
    $changedFiles += $moduleManifestRelativePath
}
if ($changedFiles.Count -eq 0) {
    throw "No changed files found."
}

Set-Content -Path $versionPath -Value $version -Encoding ASCII
[ordered]@{
    version = $version
    files = @($changedFiles | ForEach-Object {
        [ordered]@{
            path = $_
            version = $version
            sha256 = Get-FileHashValue -RelativePath $_
        }
    })
} | ConvertTo-Json -Depth 3 | Set-Content -Path $manifestPath -Encoding UTF8

Write-Host "Created version $version for $($changedFiles.Count) changed file(s)." -ForegroundColor Green