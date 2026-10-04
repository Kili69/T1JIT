<#
.SYNOPSIS
    Creates or validates the repository version metadata for a commit.
.DESCRIPTION
    In update mode, determines files changed relative to BaseRef, creates a version in
    the format <Major>.<Minor>.<yyyyMMdd>.<counter>, and writes VERSION plus
    file-versions.json. It also writes the version to the README heading and includes
    the current branch name on branches other than main. Every changed file receives
    the same version and its current SHA-256 hash in the manifest. In staged mode,
    CHANGELOG.md must contain a staged entry below Unreleased; that entry is stamped
    with the generated version and date.

    In check mode, validates the version format, README heading, manifest version, and
    changed-file versions and hashes. Generated files below bin and obj and the version
    metadata files themselves are excluded from changed-file tracking.
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
$readmeRelativePath = "README.md"
$readmePath = Join-Path $repoRoot $readmeRelativePath
$changelogRelativePath = "CHANGELOG.md"
$changelogPath = Join-Path $repoRoot $changelogRelativePath
$moduleManifestRelativePath = "src/Powershell/modules/Just-In-time.psd1"
$moduleManifestPath = Join-Path $repoRoot $moduleManifestRelativePath
$versionPattern = '^(?<major>\d+)\.(?<minor>\d+)\.(?<date>\d{8})\.(?<counter>[1-9]\d*)$'
$metadataFiles = @("VERSION", "file-versions.json")
$readmeTitle = "Just-In-Time Solution for Active Directory Member Servers"

<#
.SYNOPSIS
    Returns the source branch used for README version labeling.
#>
function Get-CurrentBranchName {
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_HEAD_REF)) {
        return $env:GITHUB_HEAD_REF.Trim()
    }

    $branch = @(git -C $repoRoot branch --show-current)
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to determine the current branch with git."
    }
    if ($branch.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($branch[0])) {
        return $branch[0].Trim()
    }

    if ($env:GITHUB_REF_TYPE -eq "branch" -and
        -not [string]::IsNullOrWhiteSpace($env:GITHUB_REF_NAME)) {
        return $env:GITHUB_REF_NAME.Trim()
    }

    throw "Unable to determine the current branch for the README heading."
}

<#
.SYNOPSIS
    Returns the versioned README heading for a branch.
#>
function Get-ReadmeHeading {
    param(
        [Parameter(Mandatory = $true)][string]$Version,
        [Parameter(Mandatory = $true)][string]$Branch
    )

    $heading = "# $readmeTitle - Version $Version"
    if ($Branch -ne "main") {
        $heading += " ($Branch)"
    }

    $heading
}

<#
.SYNOPSIS
    Moves pending changelog entries into a section for the generated version.
#>
function Update-ChangelogVersion {
    param([Parameter(Mandatory = $true)][string]$Version)

    $content = Get-Content -LiteralPath $changelogPath -Raw
    $pattern = [regex]::new(
        '^(?<heading>## \[Unreleased\]\r?\n)(?<pending>.*?)(?=^## \[)',
        [Text.RegularExpressions.RegexOptions]::Multiline -bor
            [Text.RegularExpressions.RegexOptions]::Singleline
    )
    $match = $pattern.Match($content)
    if (-not $match.Success) {
        throw "CHANGELOG.md must contain an Unreleased section before the latest version."
    }
    if ([string]::IsNullOrWhiteSpace($match.Groups["pending"].Value)) {
        throw "CHANGELOG.md has no pending entry below Unreleased. Document this commit before committing."
    }

    $versionDate = [datetime]::ParseExact(
        $Version.Split('.')[2],
        "yyyyMMdd",
        [Globalization.CultureInfo]::InvariantCulture
    ).ToString("yyyy-MM-dd", [Globalization.CultureInfo]::InvariantCulture)
    $newline = if ($content.Contains("`r`n")) { "`r`n" } else { "`n" }
    $replacement = $match.Groups["heading"].Value +
        $newline +
        "## [$Version] - $versionDate" +
        $match.Groups["pending"].Value
    $updatedContent = $content.Substring(0, $match.Index) +
        $replacement +
        $content.Substring($match.Index + $match.Length)

    [System.IO.File]::WriteAllText(
        $changelogPath,
        $updatedContent,
        [System.Text.UTF8Encoding]::new($false)
    )
}

<#
.SYNOPSIS
    Verifies that the latest concrete changelog section matches the repository version.
#>
function Assert-ChangelogVersion {
    param([Parameter(Mandatory = $true)][string]$Version)

    $content = Get-Content -LiteralPath $changelogPath -Raw
    $match = [regex]::Match(
        $content,
        '(?m)^## \[(?<version>\d+\.\d+\.\d{8}\.\d+)\] - \d{4}-\d{2}-\d{2}\r?$'
    )
    if (-not $match.Success) {
        throw "CHANGELOG.md has no concrete version section."
    }
    if ($match.Groups["version"].Value -ne $Version) {
        throw "Latest CHANGELOG.md version '$($match.Groups["version"].Value)' does not match repository version '$Version'."
    }
}

<#
.SYNOPSIS
    Returns versionable files changed relative to BaseRef.
.DESCRIPTION
    Combines tracked Git differences and untracked files, normalizes path separators,
    and excludes metadata plus generated release, bin, and obj content.
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
        Where-Object { $_ -notmatch '^release/' } |
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
    if (-not (Test-Path $versionPath) -or
        -not (Test-Path $manifestPath) -or
        -not (Test-Path $readmePath) -or
        -not (Test-Path $changelogPath)) {
        throw "VERSION, file-versions.json, README.md, and CHANGELOG.md must exist. Run build/Update-Version.ps1 first."
    }

    $version = (Get-Content $versionPath -Raw).Trim()
    Assert-VersionFormat -Version $version
    $branch = Get-CurrentBranchName
    $expectedReadmeHeading = Get-ReadmeHeading -Version $version -Branch $branch
    $actualReadmeHeading = Get-Content -LiteralPath $readmePath -TotalCount 1
    if ($actualReadmeHeading -ne $expectedReadmeHeading) {
        throw "README heading '$actualReadmeHeading' does not match expected heading '$expectedReadmeHeading'."
    }
    Assert-ChangelogVersion -Version $version

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
$changedFiles = @(Get-ChangedFiles)
if ($Staged -and $changelogRelativePath -notin $changedFiles) {
    throw "CHANGELOG.md must be updated and staged for every commit."
}
Update-ChangelogVersion -Version $version

$branch = Get-CurrentBranchName
$expectedReadmeHeading = Get-ReadmeHeading -Version $version -Branch $branch
$readmeContent = Get-Content -LiteralPath $readmePath -Raw
$escapedReadmeTitle = [regex]::Escape($readmeTitle)
$updatedReadmeContent = $readmeContent -replace "(?m)^# $escapedReadmeTitle(?: - Version .*)?$", $expectedReadmeHeading
if ($updatedReadmeContent -eq $readmeContent -and
    $readmeContent -notmatch "(?m)^$([regex]::Escape($expectedReadmeHeading))$") {
    throw "Project heading was not found in '$readmeRelativePath'."
}
[System.IO.File]::WriteAllText(
    $readmePath,
    $updatedReadmeContent,
    [System.Text.UTF8Encoding]::new($false)
)

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

if ($moduleManifestRelativePath -notin $changedFiles) {
    $changedFiles += $moduleManifestRelativePath
}
if ($readmeRelativePath -notin $changedFiles) {
    $changedFiles += $readmeRelativePath
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