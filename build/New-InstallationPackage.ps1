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
    Creates a complete T1JIT installation package as a single ZIP archive.
.DESCRIPTION
    Optionally rebuilds the release output, runs the mandatory Pester unit tests against the
    PowerShell modules that will be packaged, stages every installation file from release,
    verifies that the required installation files are present, and compresses the staged
    content into a ZIP archive with a SHA-256 checksum file. Only the ZIP and checksum are
    placed in DestinationPath; the staged, uncompressed copy is removed afterwards. Use
    BuildRelease to rebuild the release output before testing and packaging it.
.PARAMETER DestinationPath
    Output folder that will contain the ZIP archive and checksum file. The default is
    Installationspackage in the repository root. The folder is cleared before the new archive
    is written, unless -ArchivePath is specified.
.PARAMETER BuildRelease
    Runs release_build.ps1 before creating the installation package.
.PARAMETER StagingPath
    Temporary folder used to assemble the package content before it is compressed. The
    default is a unique folder under the system temp directory, which is deleted afterwards.
    Provide -KeepStaging to keep it for inspection.
.PARAMETER KeepStaging
    Keeps the staging folder instead of deleting it after the archive has been created.
.PARAMETER ArchivePath
    Explicit path of the ZIP archive to create. Overrides the DestinationPath/Version/Branch
    based naming and does not clear DestinationPath.
.PARAMETER Version
    Version used to name the archive as T1JIT-<Version>-<Branch>[-test].zip. The default is
    read from the staged release's VERSION file. Ignored when -ArchivePath is specified.
.PARAMETER Branch
    Branch name used to name the archive as T1JIT-<Version>-<Branch>[-test].zip. The default
    is the current Git branch (git rev-parse --abbrev-ref HEAD). Ignored when -ArchivePath is
    specified.
.PARAMETER Prerelease
    Appends the -test suffix to the archive name for development releases.
.EXAMPLE
    ./build/New-InstallationPackage.ps1
.EXAMPLE
    ./build/New-InstallationPackage.ps1 -BuildRelease
.EXAMPLE
    ./build/New-InstallationPackage.ps1 -BuildRelease -Version 0.1.20260924.1 -Branch main -Prerelease
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$DestinationPath,

    [Parameter()]
    [switch]$BuildRelease,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$StagingPath,

    [Parameter()]
    [switch]$KeepStaging,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$ArchivePath,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Version,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Branch,

    [Parameter()]
    [switch]$Prerelease
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

$ownsStaging = [string]::IsNullOrWhiteSpace($StagingPath)
if ($ownsStaging) {
    $StagingPath = Join-Path ([IO.Path]::GetTempPath()) "T1JIT-package-$([Guid]::NewGuid().ToString('N'))"
}
elseif (-not [IO.Path]::IsPathRooted($StagingPath)) {
    $StagingPath = Join-Path $repoRoot $StagingPath
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

Write-Host "Running mandatory PowerShell module tests..." -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "Test-PowerShellModules.ps1") `
    -ModuleRoot (Join-Path $releasePath "modules") `
    -VersionPath (Join-Path $releasePath "VERSION")

try {
    if (Test-Path -LiteralPath $StagingPath) {
        Remove-Item -LiteralPath $StagingPath -Recurse -Force
    }
    New-Item -Path $StagingPath -ItemType Directory -Force | Out-Null
    Copy-Item -Path (Join-Path $releasePath "*") -Destination $StagingPath -Recurse -Force

    $requiredFiles = @(
        "install-JIT.ps1",
        "Register-WindowsAutopilotDevice.ps1",
        "VERSION",
        "file-versions.json",
        "modules/0.1/KjitCore.dll",
        "kJITWeb/install-kjitweb.ps1",
        "kJITWeb/get-kjitweb-allowedclient.ps1",
        "kJITWeb/publish-service/KjitWeb.dll"
    )
    foreach ($relativePath in $requiredFiles) {
        $packageFile = Join-Path $StagingPath $relativePath
        if (-not (Test-Path -LiteralPath $packageFile -PathType Leaf)) {
            throw "Required installation file is missing: $packageFile"
        }
    }

    $fileCount = @(Get-ChildItem -LiteralPath $StagingPath -File -Recurse).Count
    Write-Host "Installation package staged: $StagingPath" -ForegroundColor Green
    Write-Host "Files staged: $fileCount"

    if ([string]::IsNullOrWhiteSpace($ArchivePath)) {
        if ([string]::IsNullOrWhiteSpace($Version)) {
            $Version = (Get-Content -LiteralPath (Join-Path $StagingPath "VERSION") -Raw).Trim()
        }

        if ([string]::IsNullOrWhiteSpace($Branch)) {
            $Branch = (& git -C $repoRoot rev-parse --abbrev-ref HEAD 2>$null)
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($Branch) -or $Branch.Trim() -eq "HEAD") {
                $Branch = "local"
            }
            else {
                $Branch = $Branch.Trim()
            }
        }
        $safeBranch = ($Branch -replace '[\\/:*?"<>|\s]', '-')

        $suffix = if ($Prerelease) { "-test" } else { "" }
        $archiveFileName = "T1JIT-$Version-$safeBranch$suffix.zip"

        if (Test-Path -LiteralPath $DestinationPath) {
            Remove-Item -LiteralPath $DestinationPath -Recurse -Force
        }
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        $ArchivePath = Join-Path $DestinationPath $archiveFileName
    }
    else {
        if (-not [IO.Path]::IsPathRooted($ArchivePath)) {
            $ArchivePath = Join-Path $repoRoot $ArchivePath
        }
        $archiveDirectory = Split-Path -Path $ArchivePath -Parent
        if (-not [string]::IsNullOrWhiteSpace($archiveDirectory) -and -not (Test-Path -LiteralPath $archiveDirectory)) {
            New-Item -Path $archiveDirectory -ItemType Directory -Force | Out-Null
        }
        if (Test-Path -LiteralPath $ArchivePath) {
            Remove-Item -LiteralPath $ArchivePath -Force
        }
    }

    Compress-Archive -Path (Join-Path $StagingPath "*") -DestinationPath $ArchivePath -Force

    $checksumPath = "$ArchivePath.sha256"
    $hash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    "$hash  $(Split-Path -Path $ArchivePath -Leaf)" | Set-Content -LiteralPath $checksumPath -Encoding ASCII

    Write-Host "Installation archive created: $ArchivePath" -ForegroundColor Green
    Write-Host "Checksum file created: $checksumPath"
}
finally {
    if ($ownsStaging -and -not $KeepStaging -and (Test-Path -LiteralPath $StagingPath)) {
        Remove-Item -LiteralPath $StagingPath -Recurse -Force
    }
}
