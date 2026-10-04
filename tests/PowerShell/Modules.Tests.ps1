
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
    $repoRoot = Split-Path -Path $releaseRoot -Parent
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

    Describe "T1JIT Group Policy provisioning" {
        It "packages a self-contained safe Local Administrators provisioning script" {
            $groupPolicyRoot = Join-Path $releaseRoot "GroupPolicy"
            $scriptPath = Join-Path $groupPolicyRoot "New-T1JitLocalAdministratorsGpo.ps1"

            Test-Path -LiteralPath $scriptPath -PathType Leaf | Should -BeTrue

            $installerPath = Join-Path $releaseRoot "install-JIT.ps1"
            $installerContent = Get-Content -LiteralPath $installerPath -Raw
            $installerContent | Should -Match 'GroupPolicy\\New-T1JitLocalAdministratorsGpo\.ps1'
            $installerContent | Should -Match 'Copy-Item\s+-LiteralPath\s+\$groupPolicyScriptSource\s+-Destination\s+\$groupPolicyScriptTarget'
            $installerContent | Should -Match 'IMPORTANT: Group Policy provisioning is still required'
            $installerContent | Should -Match 'Domain Administrator'
            $installerContent | Should -Match 'Group Policy Creator Owners'

            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $scriptPath,
                [ref]$tokens,
                [ref]$parseErrors
            )
            $parseErrors | Should -BeNullOrEmpty
            $ast.Extent.Text | Should -Match 'New-T1JitLocalAdministratorsGpo\.ps1 version \$scriptVersion'
            $ast.Extent.Text | Should -Match '\$scriptVersion\s*=\s*"0\.1\.\d{8}\.\d+"'
            $ast.ParamBlock.Attributes.Extent.Text | Should -Match 'SupportsShouldProcess\s*=\s*\$true'
            $ast.Extent.Text | Should -Match '(?s)if\s*\(\$Force\)\s*\{\s*\$ConfirmPreference\s*=\s*"None"\s*\}'
            $ast.Extent.Text | Should -Match "GPO '.+?' already exists .+? Confirm the following prompt to overwrite"
            $ast.Extent.Text | Should -Match "Overwrite existing GPO"
            $ast.Extent.Text | Should -Match '-ReplaceExisting:\$replaceExisting'
            $ast.Extent.Text | Should -Match 'Write-Verbose'
            $ast.Extent.Text | Should -Match '(?im)^\.PARAMETER Verbose\s*$'
            $ast.Extent.Text | Should -Match '(?im)^\.PARAMETER WhatIf\s*$'
            $ast.Extent.Text | Should -Match 'S-1-5-32-544'
            $ast.Extent.Text | Should -Match '17D89FEC-5C44-4972-B12D-241CAEF74509'
            $ast.Extent.Text | Should -Match 'New-GPLink'
            $ast.Extent.Text | Should -Match 'Get-JITConfig'
            $ast.Extent.Text | Should -Match 'Get-T1JitConfiguredDomains'
            $ast.Extent.Text | Should -Match 'Select-T1JitTargetDomains'
            $ast.Extent.Text | Should -Match 'Test-T1JitPermissionError'
            $ast.Extent.Text | Should -Match "Run the script again with credentials authorized in that domain"
            $ast.Extent.Text | Should -Match '-Domain\s+''\$domainDnsName'''
            $ast.Extent.Text | Should -Match 'Error\s*=\s*"PermissionDenied"'
            $ast.Extent.Text | Should -Match 'Get-T1JitDomainLinkTargets'
            $ast.Extent.Text | Should -Match 'Get-T1JitGroupDomain'
            $ast.Extent.Text | Should -Match 'Get-T1JitGroupMemberName'
            $ast.Extent.Text | Should -Match 'Install-T1JitDomainGpo'
            ($ast.ParamBlock.Parameters.Name.VariablePath.UserPath) | Should -Contain "AdminPrefix"
            ($ast.ParamBlock.Parameters.Name.VariablePath.UserPath) | Should -Contain "DomainSeparator"
            ($ast.ParamBlock.Parameters.Name.VariablePath.UserPath) | Should -Contain "Domain"
            ($ast.ParamBlock.Parameters.Name.VariablePath.UserPath) | Should -Contain "LinkDomainRoot"
            ($ast.ParamBlock.Parameters.Name.VariablePath.UserPath) | Should -Not -Contain "TargetOu"

            $documentedFunctions = @($ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true))
            $documentedFunctions.Count | Should -BeGreaterThan 0
            foreach ($documentedFunction in $documentedFunctions) {
                $functionHelp = $documentedFunction.GetHelpContent()
                $functionHelp | Should -Not -BeNullOrEmpty
                foreach ($helpSection in @("Synopsis", "Description", "Examples", "Inputs", "Outputs", "Notes")) {
                    @($functionHelp.$helpSection).Count | Should -BeGreaterThan 0 `
                        -Because "$($documentedFunction.Name) must document .$($helpSection.ToUpperInvariant())"
                }
            }

            $xmlFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "New-T1JitGroupsXml"
            }, $true)
            $xmlFunction | Should -Not -BeNullOrEmpty
            $xmlFunction.GetHelpContent() | Should -Not -BeNullOrEmpty
            Invoke-Expression $xmlFunction.Extent.Text

            $generatedXml = New-T1JitGroupsXml `
                -MemberName "CONTOSO\Admin_%AD-DNSDomainName%#%ComputerName%" `
                -Changed ([datetime]"2026-09-29T00:00:00Z") `
                -PreferenceUid ([guid]"96a31b3c-290a-42db-a0b4-162fd420d41d")
            $generatedProperties = $generatedXml.Groups.Group.Properties
            $generatedXml.Groups.clsid | Should -Be "{3125E937-EB16-4b4c-9934-544FC6D24D26}"
            $generatedXml.Groups.Group.clsid | Should -Be "{6D4A79E4-529C-4481-ABD0-F5BD7EA93BA7}"
            $generatedProperties.action | Should -Be "U"
            $generatedProperties.groupSid | Should -Be "S-1-5-32-544"
            $generatedProperties.deleteAllUsers | Should -Be "0"
            $generatedProperties.deleteAllGroups | Should -Be "0"
            $generatedProperties.Members.Member.action | Should -Be "ADD"
            $generatedProperties.Members.Member.name |
                Should -Be "CONTOSO\Admin_%AD-DNSDomainName%#%ComputerName%"

            $groupMemberNameFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "Get-T1JitGroupMemberName"
            }, $true)
            $groupMemberNameFunction | Should -Not -BeNullOrEmpty
            Invoke-Expression $groupMemberNameFunction.Extent.Text

            $multiDomainMemberName = Get-T1JitGroupMemberName `
                -Configuration ([PSCustomObject]@{ EnableMultiDomainSupport = $true }) `
                -AdminPrefix "Admin_" `
                -DomainSeparator "#" `
                -GroupDomainNetBIOSName "CONTOSO"
            $multiDomainMemberName |
                Should -Be "CONTOSO\Admin_%AD-DNSDomainName%#%ComputerName%"

            $singleDomainMemberName = Get-T1JitGroupMemberName `
                -Configuration ([PSCustomObject]@{ EnableMultiDomainSupport = $false }) `
                -AdminPrefix "Admin_" `
                -DomainSeparator "#" `
                -GroupDomainNetBIOSName "CONTOSO"
            $singleDomainMemberName | Should -Be "CONTOSO\Admin_%ComputerName%"

            $groupDomainFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "Get-T1JitGroupDomain"
            }, $true)
            $groupDomainFunction | Should -Not -BeNullOrEmpty
            Invoke-Expression $groupDomainFunction.Extent.Text

            function Get-ADDomain {
                [CmdletBinding()]
                param(
                    [string]$Identity,
                    [string]$Server,
                    [string]$Current
                )
            }
            Mock Get-ADDomain {
                [PSCustomObject]@{
                    DNSRoot = "groups.contoso.com"
                    NetBIOSName = "GROUPS"
                }
            }

            $resolvedGroupDomain = Get-T1JitGroupDomain -Configuration ([PSCustomObject]@{
                AdminGroupOU = "OU=JIT Groups,DC=groups,DC=contoso,DC=com"
            })
            $resolvedGroupDomain.DNSRoot | Should -Be "groups.contoso.com"
            $resolvedGroupDomain.NetBIOSName | Should -Be "GROUPS"
            Should -Invoke Get-ADDomain -Times 1 -Exactly -ParameterFilter {
                $Identity -eq "groups.contoso.com" -and
                $Server -eq "groups.contoso.com"
            }

            $linkTargetFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "Get-T1JitDomainLinkTargets"
            }, $true)
            $linkTargetFunction | Should -Not -BeNullOrEmpty
            Invoke-Expression $linkTargetFunction.Extent.Text

            function Get-ADOrganizationalUnit {
                [CmdletBinding()]
                param(
                    [string]$Identity,
                    [string]$Server
                )
            }
            Mock Get-ADOrganizationalUnit {
                [PSCustomObject]@{ DistinguishedName = $Identity }
            }

            $configuration = [PSCustomObject]@{
                T1Searchbase = @(
                    "<DomainRoot>",
                    "OU=Tier 1 Servers",
                    "OU=Apps,DC=contoso,DC=com",
                    "OU=Apps,DC=child,DC=contoso,DC=com"
                )
            }
            $domainInfo = [PSCustomObject]@{
                DNSRoot = "contoso.com"
                DistinguishedName = "DC=contoso,DC=com"
            }

            $ouTargets = @(Get-T1JitDomainLinkTargets `
                -Configuration $configuration `
                -DomainInfo $domainInfo)
            $ouTargets | Should -Contain "OU=Tier 1 Servers,DC=contoso,DC=com"
            $ouTargets | Should -Contain "OU=Apps,DC=contoso,DC=com"
            $ouTargets | Should -Not -Contain "DC=contoso,DC=com"
            $ouTargets | Should -Not -Contain "OU=Apps,DC=child,DC=contoso,DC=com"

            $rootTargets = @(Get-T1JitDomainLinkTargets `
                -Configuration $configuration `
                -DomainInfo $domainInfo `
                -IncludeDomainRoot)
            $rootTargets | Should -Contain "DC=contoso,DC=com"

            $versionFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "Get-T1JitNextComputerVersion"
            }, $true)
            $versionFunction | Should -Not -BeNullOrEmpty
            Invoke-Expression $versionFunction.Extent.Text

            $nextVersion = Get-T1JitNextComputerVersion -Version ((7 -shl 16) -bor 12)
            $nextVersion.User | Should -Be 7
            $nextVersion.Computer | Should -Be 13
            $nextVersion.Combined | Should -Be ((7 -shl 16) -bor 13)

            $configuredDomainsFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "Get-T1JitConfiguredDomains"
            }, $true)
            $configuredDomainsFunction | Should -Not -BeNullOrEmpty
            Invoke-Expression $configuredDomainsFunction.Extent.Text

            function Get-ADForest {
                [CmdletBinding()]
                param([string]$Identity)
            }
            Mock Get-ADForest {
                [PSCustomObject]@{
                    Domains = @("contoso.com", "child.contoso.com")
                }
            }

            $multiDomainConfiguration = [PSCustomObject]@{
                EnableMultiDomainSupport = $true
                Domain = @("contoso.com")
            }
            @(Get-T1JitConfiguredDomains -Configuration $multiDomainConfiguration) |
                Should -Be @("child.contoso.com", "contoso.com")

            $singleDomainConfiguration = [PSCustomObject]@{
                EnableMultiDomainSupport = $false
                Domain = @("contoso.com")
            }
            @(Get-T1JitConfiguredDomains -Configuration $singleDomainConfiguration) |
                Should -Be @("contoso.com")

            $targetDomainsFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "Select-T1JitTargetDomains"
            }, $true)
            $targetDomainsFunction | Should -Not -BeNullOrEmpty
            Invoke-Expression $targetDomainsFunction.Extent.Text

            @(Select-T1JitTargetDomains `
                -ConfiguredDomains @("contoso.com", "child.contoso.com")) |
                Should -Be @("contoso.com", "child.contoso.com")
            @(Select-T1JitTargetDomains `
                -ConfiguredDomains @("contoso.com", "child.contoso.com") `
                -RequestedDomain "CHILD.CONTOSO.COM") |
                Should -Be @("child.contoso.com")
            {
                Select-T1JitTargetDomains `
                    -ConfiguredDomains @("contoso.com", "child.contoso.com") `
                    -RequestedDomain "unknown.contoso.com"
            } | Should -Throw "*not part of the configured JIT domains*"

            $permissionErrorFunction = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                    $node.Name -eq "Test-T1JitPermissionError"
            }, $true)
            $permissionErrorFunction | Should -Not -BeNullOrEmpty
            Invoke-Expression $permissionErrorFunction.Extent.Text

            Test-T1JitPermissionError `
                -Exception ([System.UnauthorizedAccessException]::new("Access is denied.")) |
                Should -BeTrue
            Test-T1JitPermissionError `
                -Exception ([System.InvalidOperationException]::new("Insufficient access rights to perform the operation.")) |
                Should -BeTrue
            Test-T1JitPermissionError `
                -Exception ([System.InvalidOperationException]::new("The domain controller is unavailable.")) |
                Should -BeFalse
        }
    }

    It "registers and repairs scheduled tasks with a non-interactive GMSA principal" {
        $configScriptPath = Join-Path $repoRoot "src/Powershell/Scripts/Config-JIT.ps1"
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $configScriptPath,
            [ref]$tokens,
            [ref]$parseErrors
        )
        $scheduledTaskFunction = $ast.Find({
            param($node)
            $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
                $node.Name -eq "Set-JitScheduledTask"
        }, $true)

        $parseErrors | Should -BeNullOrEmpty
        $scheduledTaskFunction | Should -Not -BeNullOrEmpty
        $scheduledTaskFunction.Extent.Text |
            Should -Match 'New-ScheduledTaskPrincipal[\s\S]+-LogonType\s+Password'
        @([regex]::Matches(
            $scheduledTaskFunction.Extent.Text,
            'Register-ScheduledTask[\s\S]*?-Force'
        )).Count | Should -Be 2
    }

    It "requires and versions the changelog for every commit" {
        $versionScript = Get-Content -LiteralPath (Join-Path $repoRoot "build/Update-Version.ps1") -Raw
        $commitHook = Get-Content -LiteralPath (Join-Path $repoRoot ".githooks/pre-commit.ps1") -Raw
        $pushScript = Get-Content -LiteralPath (Join-Path $repoRoot "build/Push-GitHub.ps1") -Raw

        $versionScript | Should -Match 'CHANGELOG\.md must be updated and staged for every commit'
        $versionScript | Should -Match 'Update-ChangelogVersion -Version \$version'
        $versionScript | Should -Match 'Assert-ChangelogVersion -Version \$version'
        $versionScript | Should -Match "Where-Object \{ \`$_ -notmatch '\^release/' \}"
        "## [0.2.20261004.2] - 2026-10-04`r`n" |
            Should -Match '(?m)^## \[\d+\.\d+\.\d{8}\.\d+\] - \d{4}-\d{2}-\d{2}\r?$'
        $commitHook | Should -Match 'git -C \$repoRoot add -- VERSION file-versions\.json CHANGELOG\.md'
        $pushScript | Should -Match '"add", "--", "History\.md", "CHANGELOG\.md"'
        $prePushHook = Get-Content -LiteralPath (Join-Path $repoRoot ".githooks/pre-push.ps1") -Raw
        $prePushHook | Should -Match '"History\.md",\s+"CHANGELOG\.md",\s+"README\.md"'
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

if (($config.T1Searchbase -join ";") -ne "<DomainRoot>;OU=Servers") {
    throw "Unexpected T1Searchbase values: $($config.T1Searchbase -join ';')"
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
