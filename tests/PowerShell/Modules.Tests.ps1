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
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleRoot,

    [Parameter(Mandatory = $true)]
    [string]$ExpectedVersion
)

BeforeAll {
    $manifestPath = Join-Path $ModuleRoot "Just-In-time.psd1"
    $versionedModulePath = Join-Path $ModuleRoot "0.1"
}

Describe "Just-In-Time PowerShell module package" {
    It "contains a valid manifest with the release version" {
        Test-Path -LiteralPath $manifestPath -PathType Leaf | Should -BeTrue
        $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
        $manifest.Version.ToString() | Should -Be $ExpectedVersion
    }

    It "contains syntactically valid module files" {
        $moduleFiles = @(Get-ChildItem -LiteralPath $versionedModulePath -Filter "*.psm1" -File)
        $moduleFiles.Count | Should -BeGreaterThan 0

        foreach ($moduleFile in $moduleFiles) {
            $tokens = $null
            $parseErrors = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile(
                $moduleFile.FullName,
                [ref]$tokens,
                [ref]$parseErrors
            )

            $parseErrors | Should -BeNullOrEmpty -Because "$($moduleFile.Name) must parse successfully"
        }
    }

    It "loads domain-root and relative search bases through Get-JITConfig" {
        $testModulePath = Join-Path $TestDrive "module"
        $testVersionedModulePath = Join-Path $testModulePath "0.1"
        New-Item -Path $testVersionedModulePath -ItemType Directory -Force | Out-Null

        Copy-Item -LiteralPath (Join-Path $versionedModulePath "just-in-time-configuration.psm1") -Destination $testVersionedModulePath
        Copy-Item -LiteralPath (Join-Path $versionedModulePath "KjitCore.dll") -Destination $testVersionedModulePath

        $configurationPath = Join-Path $TestDrive "JIT.config"
        @{
            ConfigScriptVersion = "0.1.20260925"
            AdminPreFix = "Admin_"
            OU = "OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin,DC=example,DC=com"
            MaxElevatedTime = 1440
            DefaultElevatedTime = 60
            ElevateEventID = 100
            Tier0ServerGroupName = "Tier 0 Computers"
            LDAPT0Computers = "(&(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))"
            LDAPT0ComputerPath = "OU=Tier 0,OU=Admin"
            LDAPT1Computers = "(&(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))"
            EventSource = "T1Mgmt"
            EventLog = "Tier 1 Management"
            DebugLogPath = "%TEMP%"
            GroupManagementTaskRerun = 5
            GroupManagedServiceAccountName = "T1GroupMgmt"
            Domain = "example.com"
            DelegationConfigPath = "\\example.com\SYSVOL\example.com\Just-In-Time\Tier1delegation.config"
            EnableDelegation = $true
            EnableMultiDomainSupport = $false
            T1Searchbase = @("<DomainRoot>", "OU=Servers")
            DomainSeparator = "#"
            UseManagedByforDelegation = $true
            MaxConcurrentServer = 50
        } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $configurationPath -Encoding UTF8

        $verificationScriptPath = Join-Path $TestDrive "Verify-GetJitConfig.ps1"
        @'
param(
    [string]$ModulePath,
    [string]$ConfigurationPath
)

$ErrorActionPreference = "Stop"
Import-Module -Name $ModulePath -Force
$config = Get-JITConfig -ConfigurationFile $ConfigurationPath

if (($config.TargetOU -join ";") -ne "DC=example,DC=com;OU=Servers,DC=example,DC=com") {
    throw "Unexpected TargetOU values: $($config.TargetOU -join ';')"
}

if (($config.ExcludeComputerOU -join ";") -ne "OU=Tier 0,OU=Admin,DC=example,DC=com") {
    throw "Unexpected ExcludeComputerOU values: $($config.ExcludeComputerOU -join ';')"
}

if ($config.ExcludeServerGroupName -ne "Tier 0 Computers") {
    throw "Unexpected ExcludeServerGroupName value: $($config.ExcludeServerGroupName)"
}
'@ | Set-Content -LiteralPath $verificationScriptPath -Encoding UTF8

        $windowsPowerShell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
        & $windowsPowerShell -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $verificationScriptPath `
            -ModulePath (Join-Path $testVersionedModulePath "just-in-time-configuration.psm1") `
            -ConfigurationPath $configurationPath

        $LASTEXITCODE | Should -Be 0
    }
}
