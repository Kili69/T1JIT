
param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleRoot,

    [Parameter(Mandatory = $true)]
    [string]$ExpectedVersion
)

BeforeAll {
    $manifestPath = Join-Path $ModuleRoot "Just-In-time.psd1"
    $versionedModulePath = Join-Path $ModuleRoot "0.1"
    $releaseRoot = Split-Path -Path $ModuleRoot -Parent
}

Describe "Just-In-Time PowerShell module package" {
    It "contains a valid manifest with the release version" {
        Test-Path -LiteralPath $manifestPath -PathType Leaf | Should -BeTrue
        $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
        $manifest.Version.ToString() | Should -Be $ExpectedVersion
    }

    Describe "KjitWeb firewall configuration" {
        It "removes IPv6 scope IDs before creating firewall rules in <ScriptName>" -ForEach @(
            @{ ScriptName = "install-kjitweb.ps1" }
            @{ ScriptName = "update-kjitweb.ps1" }
            @{ ScriptName = "set-kjitweb-allowedclient.ps1" }
        ) {
            $scriptPath = Join-Path (Join-Path $releaseRoot "kJITWeb") $ScriptName
            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath,
                [ref]$tokens,
                [ref]$parseErrors
            )
            $firewallFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "Set-ClientAccessFirewallRule"
            }, $true)

            $firewallFunction | Should -Not -BeNullOrEmpty
            Invoke-Expression $firewallFunction.Extent.Text

            function Get-NetFirewallRule {
                [CmdletBinding()]
                param([string]$DisplayName)
            }
            function Remove-NetFirewallRule {
                [CmdletBinding()]
                param([Parameter(ValueFromPipeline = $true)]$InputObject)
            }
            function New-NetFirewallRule {
                [CmdletBinding()]
                param(
                    [string]$DisplayName,
                    [string]$Direction,
                    [string]$Action,
                    [string]$Protocol,
                    [int]$LocalPort,
                    [string[]]$RemoteAddress,
                    [string]$Profile
                )
            }

            $script:capturedRemoteAddresses = @()
            Mock Get-NetFirewallRule {}
            Mock Remove-NetFirewallRule {}
            Mock New-NetFirewallRule {
                $script:capturedRemoteAddresses = @($RemoteAddress)
            }

            Set-ClientAccessFirewallRule `
                -RuleName "KjitWeb test" `
                -RemoteAddresses @("127.0.0.1", "::1", "fe80::5995:5c07:83a6:41ed%5", "10.0.1.8") `
                -Port 5240

            Should -Invoke New-NetFirewallRule -Times 1 -Exactly
            $script:capturedRemoteAddresses | Should -Contain "fe80::5995:5c07:83a6:41ed"
            $script:capturedRemoteAddresses | Should -Contain "10.0.1.8"
            $script:capturedRemoteAddresses | Should -Not -Contain "fe80::5995:5c07:83a6:41ed%5"
            $script:capturedRemoteAddresses | Should -Not -Contain "127.0.0.1"
            $script:capturedRemoteAddresses | Should -Not -Contain "::1"
            $firewallFunction.Extent.Text | Should -Match '-ErrorAction Stop'
        }

        It "supports multiple clients and always includes the local system in <ScriptName>" -ForEach @(
            @{ ScriptName = "install-kjitweb.ps1" }
            @{ ScriptName = "update-kjitweb.ps1" }
            @{ ScriptName = "set-kjitweb-allowedclient.ps1" }
        ) {
            $scriptPath = Join-Path (Join-Path $releaseRoot "kJITWeb") $ScriptName
            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath,
                [ref]$tokens,
                [ref]$parseErrors
            )

            foreach ($functionName in @(
                "ConvertTo-AllowedClientEntries",
                "Get-LocalSystemAddresses",
                "Assert-AllowedClientHostName",
                "Resolve-AllowedClientAddresses"
            )) {
                $function = $ast.Find({
                    param($node)
                    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                        $node.Name -eq $functionName
                }, $true)
                $function | Should -Not -BeNullOrEmpty
                Invoke-Expression $function.Extent.Text
            }

            Mock Get-NetIPAddress {
                @(
                    [PSCustomObject]@{
                        AddressState = "Preferred"
                        IPAddress = "10.20.30.40"
                    },
                    [PSCustomObject]@{
                        AddressState = "Preferred"
                        IPAddress = "fe80::1234%12"
                    },
                    [PSCustomObject]@{
                        AddressState = "Deprecated"
                        IPAddress = "10.20.30.99"
                    }
                )
            }

            $addresses = @(Resolve-AllowedClientAddresses -Client @(
                "192.168.10.0/24",
                "192.168.11.0/26;192.168.12.15"
            ))

            $addresses | Should -Contain "192.168.10.0/24"
            $addresses | Should -Contain "192.168.11.0/26"
            $addresses | Should -Contain "192.168.12.15"
            $addresses | Should -Contain "127.0.0.1"
            $addresses | Should -Contain "::1"
            $addresses | Should -Contain "10.20.30.40"
            $addresses | Should -Contain "fe80::1234"
            $addresses | Should -Not -Contain "fe80::1234%12"
            $addresses | Should -Not -Contain "10.20.30.99"

            { Resolve-AllowedClientAddresses -Client "192.168." } |
                Should -Throw "*not a valid IPv4 address, IPv6 address, CIDR subnet, or DNS hostname*"
            { Resolve-AllowedClientAddresses -Client "2001:db8:::1" } |
                Should -Throw "*not a valid IPv4 address, IPv6 address, CIDR subnet, or DNS hostname*"
            { Resolve-AllowedClientAddresses -Client "bad_.example" } |
                Should -Throw "*not a valid IPv4 address, IPv6 address, CIDR subnet, or DNS hostname*"
        }

        It "binds HTTP.sys for local interface access in <ScriptName>" -ForEach @(
            @{ ScriptName = "install-kjitweb.ps1" }
            @{ ScriptName = "set-kjitweb-allowedclient.ps1" }
        ) {
            $scriptPath = Join-Path (Join-Path $releaseRoot "kJITWeb") $ScriptName
            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath,
                [ref]$tokens,
                [ref]$parseErrors
            )
            $serviceUrlFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "Get-ServiceUrlFromAllowedClient"
            }, $true)

            $serviceUrlFunction | Should -Not -BeNullOrEmpty
            Invoke-Expression $serviceUrlFunction.Extent.Text

            Get-ServiceUrlFromAllowedClient -Client "localhost" -Port 5240 |
                Should -Be "http://*:5240"
        }

        It "rejects a wildcard combined with restricted clients in <ScriptName>" -ForEach @(
            @{ ScriptName = "install-kjitweb.ps1" }
            @{ ScriptName = "update-kjitweb.ps1" }
            @{ ScriptName = "set-kjitweb-allowedclient.ps1" }
        ) {
            $scriptPath = Join-Path (Join-Path $releaseRoot "kJITWeb") $ScriptName
            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath,
                [ref]$tokens,
                [ref]$parseErrors
            )
            $conversionFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "ConvertTo-AllowedClientEntries"
            }, $true)

            $conversionFunction | Should -Not -BeNullOrEmpty
            Invoke-Expression $conversionFunction.Extent.Text

            { ConvertTo-AllowedClientEntries -Client @("*", "192.168.10.0/24") } |
                Should -Throw "*cannot be combined*"
        }

        It "accepts AllowedClient values through the pipeline" {
            $scriptPath = Join-Path (Join-Path $releaseRoot "kJITWeb") "set-kjitweb-allowedclient.ps1"
            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath,
                [ref]$tokens,
                [ref]$parseErrors
            )
            $allowedClientParameter = $ast.ParamBlock.Parameters |
                Where-Object { $_.Name.VariablePath.UserPath -eq "AllowedClient" }

            $allowedClientParameter | Should -Not -BeNullOrEmpty
            $allowedClientParameter.Extent.Text | Should -Match 'ValueFromPipeline\s*=\s*\$true'
            ($ast.ParamBlock.Parameters.Name.VariablePath.UserPath) | Should -Contain "Add"
            ($ast.ParamBlock.Parameters.Name.VariablePath.UserPath) | Should -Contain "Remove"
            $ast.ParamBlock.Attributes.Extent.Text | Should -Match 'SupportsShouldProcess\s*=\s*\$true'
            $ast.BeginBlock | Should -Not -BeNullOrEmpty
            $ast.ProcessBlock | Should -Not -BeNullOrEmpty
            $ast.EndBlock | Should -Not -BeNullOrEmpty
            $ast.EndBlock.Extent.Text | Should -Match '\$PSCmdlet\.ShouldProcess'
            $ast.Extent.Text | Should -Match 'KjitWeb\.AllowedClientConfiguration'
            $ast.Extent.Text | Should -Match 'Get-ConfiguredAllowedClient'
            $ast.Extent.Text | Should -Match 'IPv6Subnets'
            $ast.Extent.Text | Should -Match 'Write-Host\s+"set-kjitweb-allowedclient\.ps1 version \$scriptVersion"'
            $ast.Extent.Text | Should -Match '\$configuredAllowedClientValue\s*='
            $ast.Extent.Text | Should -Match '-AllowedClient\s+\$configuredAllowedClientValue'
            $ast.Extent.Text | Should -Not -Match '\$AllowedClient\s*='
        }

        It "packages a query script that classifies IPv4 and IPv6 addresses" {
            $scriptPath = Join-Path (Join-Path $releaseRoot "kJITWeb") "get-kjitweb-allowedclient.ps1"
            Test-Path -LiteralPath $scriptPath -PathType Leaf | Should -BeTrue

            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath,
                [ref]$tokens,
                [ref]$parseErrors
            )
            $parseErrors | Should -BeNullOrEmpty
            $addressFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "Get-AddressDetails"
            }, $true)

            $addressFunction | Should -Not -BeNullOrEmpty
            Invoke-Expression $addressFunction.Extent.Text
            $ast.Extent.Text | Should -Match 'Write-Host\s+"get-kjitweb-allowedclient\.ps1 version \$scriptVersion"'

            $ipv4 = Get-AddressDetails -RemoteAddress "192.168.10.0/24"
            $ipv4.AddressFamily | Should -Be "IPv4"
            $ipv4.AddressType | Should -Be "Subnet"
            $ipv4.PrefixLength | Should -Be 24
            $ipv4.RemoteAddress | Should -Be "192.168.10.0/24"

            $ipv4Mask = Get-AddressDetails -RemoteAddress "192.168.11.0/255.255.255.192"
            $ipv4Mask.AddressFamily | Should -Be "IPv4"
            $ipv4Mask.AddressType | Should -Be "Subnet"
            $ipv4Mask.PrefixLength | Should -Be 26
            $ipv4Mask.RemoteAddress | Should -Be "192.168.11.0/26"

            $ipv6 = Get-AddressDetails -RemoteAddress "2001:db8:10::/64"
            $ipv6.AddressFamily | Should -Be "IPv6"
            $ipv6.AddressType | Should -Be "Subnet"
            $ipv6.PrefixLength | Should -Be 64
        }

        It "returns the currently effective IPv4 and IPv6 firewall addresses as objects" {
            $scriptPath = Join-Path (Join-Path $releaseRoot "kJITWeb") "get-kjitweb-allowedclient.ps1"
            $installPath = Join-Path $TestDrive "KjitWeb"
            New-Item -Path $installPath -ItemType Directory -Force | Out-Null
            @{
                KjitWebInstall = @{
                    AllowedClient = "192.168.10.0/24;2001:db8:10::/64;localhost"
                    ServiceUrl = "http://*:5240"
                }
            } | ConvertTo-Json -Depth 5 |
                Set-Content -LiteralPath (Join-Path $installPath "appsettings.Production.json") -Encoding UTF8

            function Get-NetFirewallRule {
                [CmdletBinding()]
                param([string]$DisplayName)
                [PSCustomObject]@{ DisplayName = $DisplayName }
            }
            function Get-NetFirewallAddressFilter {
                [CmdletBinding()]
                param([Parameter(ValueFromPipeline = $true)]$InputObject)
                [PSCustomObject]@{
                    RemoteAddress = @("192.168.10.0/255.255.255.0", "2001:db8:10::/64")
                }
            }

            Mock Get-NetFirewallRule {
                [PSCustomObject]@{ DisplayName = $DisplayName }
            }
            Mock Get-NetFirewallAddressFilter {
                [PSCustomObject]@{
                    RemoteAddress = @("192.168.10.0/255.255.255.0", "2001:db8:10::/64")
                }
            }

            $result = @(& $scriptPath -InstallServiceFolder $installPath)

            $result.Count | Should -Be 4
            ($result | Where-Object RemoteAddress -eq "192.168.10.0/24").AddressFamily | Should -Be "IPv4"
            ($result | Where-Object RemoteAddress -eq "2001:db8:10::/64").AddressFamily | Should -Be "IPv6"
            ($result | Where-Object RemoteAddress -eq "::1").IsLoopback | Should -BeTrue
            $result[0].PSObject.TypeNames | Should -Contain "KjitWeb.AllowedClientAddress"
            $result[0].ConfiguredAllowList | Should -Contain "localhost"
        }
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

    It "provides complete comment-based help for every function" {
        $moduleFiles = @(Get-ChildItem -LiteralPath $versionedModulePath -Filter "*.psm1" -File)

        foreach ($moduleFile in $moduleFiles) {
            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $moduleFile.FullName,
                [ref]$tokens,
                [ref]$parseErrors
            )
            $functions = @($ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true))

            foreach ($function in $functions) {
                $help = $function.GetHelpContent()
                $help | Should -Not -BeNullOrEmpty -Because "$($function.Name) must provide comment-based help"

                foreach ($section in @("Synopsis", "Description", "Examples", "Inputs", "Outputs", "Notes")) {
                    @($help.$section).Count | Should -BeGreaterThan 0 `
                        -Because "$($function.Name) must document .$($section.ToUpperInvariant())"
                }

                $parameters = if ($null -ne $function.Body.ParamBlock) {
                    @($function.Body.ParamBlock.Parameters)
                }
                else {
                    @()
                }
                $documentedParameterNames = if ($null -ne $help.PSObject.Properties["Parameters"]) {
                    @($help.Parameters.Keys)
                }
                else {
                    @()
                }
                foreach ($parameter in $parameters) {
                    $parameterName = $parameter.Name.VariablePath.UserPath
                    $parameterName | Should -BeIn $documentedParameterNames `
                        -Because "$($function.Name) must document parameter $parameterName"
                }
            }
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
