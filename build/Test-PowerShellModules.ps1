<#

.SYNOPSIS
    Runs the Pester unit tests for the packaged PowerShell modules.
.DESCRIPTION
    Uses PowerShell 7 and Pester 5 to validate the module manifest, parse every packaged
    module file, and execute Get-JITConfig in Windows PowerShell 5.1. A missing compatible
    Pester installation or any failed test terminates the script with an error.
.PARAMETER ModuleRoot
    Module directory to test. Defaults to release\modules.
.PARAMETER VersionPath
    VERSION file whose value the module manifest must report. Defaults to release\VERSION.
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ModuleRoot,

    [Parameter()]
    [string]$VersionPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ([string]::IsNullOrWhiteSpace($ModuleRoot)) {
    $ModuleRoot = Join-Path $repoRoot "release\modules"
}
if ([string]::IsNullOrWhiteSpace($VersionPath)) {
    $VersionPath = Join-Path $repoRoot "release\VERSION"
}

if ($PSVersionTable.PSEdition -ne "Core") {
    $pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
    if ([string]::IsNullOrWhiteSpace($pwsh)) {
        throw "PowerShell 7 is required to run the Pester 5 module tests."
    }

    & $pwsh -NoProfile -NonInteractive -File $PSCommandPath -ModuleRoot $ModuleRoot -VersionPath $VersionPath
    if ($LASTEXITCODE -ne 0) {
        throw "PowerShell module tests failed with exit code $LASTEXITCODE."
    }
    return
}

$pester = Get-Module -ListAvailable -Name Pester |
    Where-Object Version -GE ([version]"5.0.0") |
    Sort-Object Version -Descending |
    Select-Object -First 1
if ($null -eq $pester) {
    throw "Pester 5 or newer is required. Install it with: Install-Module Pester -MinimumVersion 5.0.0 -Scope CurrentUser"
}

if (-not (Test-Path -LiteralPath $ModuleRoot -PathType Container)) {
    throw "PowerShell module directory not found: $ModuleRoot"
}
if (-not (Test-Path -LiteralPath $VersionPath -PathType Leaf)) {
    throw "Release VERSION file not found: $VersionPath"
}

Import-Module $pester.Path -Force
$expectedVersion = (Get-Content -LiteralPath $VersionPath -Raw).Trim()
$testPath = Join-Path $repoRoot "tests\PowerShell\Modules.Tests.ps1"
$container = New-PesterContainer -Path $testPath -Data @{
    ModuleRoot = (Resolve-Path -LiteralPath $ModuleRoot).Path
    ExpectedVersion = $expectedVersion
}

$configuration = New-PesterConfiguration
$configuration.Run.Container = $container
$configuration.Run.PassThru = $true
$configuration.Output.Verbosity = "Detailed"
$result = Invoke-Pester -Configuration $configuration

if ($result.FailedCount -gt 0 -or $result.Result -ne "Passed") {
    throw "PowerShell module tests failed. Passed: $($result.PassedCount); Failed: $($result.FailedCount)."
}
