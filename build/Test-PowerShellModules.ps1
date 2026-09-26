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
