[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "\\bloedgelaber.de\SYSVOL\bloedgelaber.de\Just-In-Time\JIT.config",

    [Parameter(Mandatory = $false)]
    [string]$AdSource = "Jit-Configuration",

    [Parameter(Mandatory = $false)]
    [string]$DllPath = "..\..\C#\KjitCore\bin\debug\netstandard2.0\KjitCore.dll"
)

function Resolve-InputPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return (Resolve-Path -Path $Path -ErrorAction Stop)
    }

    return (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath $Path) -ErrorAction Stop)
}

function Get-CurrentDomainDnsName {
    $domain = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName
    if ([string]::IsNullOrWhiteSpace($domain)) {
        return $null
    }

    return $domain.Trim().ToLowerInvariant()
}

function Convert-DomainToDistinguishedName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DomainFqdn
    )

    $labels = $DomainFqdn.Split('.', [System.StringSplitOptions]::RemoveEmptyEntries)
    if ($labels.Count -eq 0) {
        return ''
    }

    return (($labels | ForEach-Object { "DC=$($_.Trim())" }) -join ',')
}

function Get-DomainFromDistinguishedName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistinguishedName
    )

    $parts = $DistinguishedName.Split(',', [System.StringSplitOptions]::RemoveEmptyEntries)
    $labels = New-Object System.Collections.Generic.List[string]
    foreach ($part in $parts) {
        $trimmed = $part.Trim()
        if ($trimmed -like 'DC=*') {
            $labels.Add($trimmed.Substring(3))
        }
    }

    if ($labels.Count -eq 0) {
        return $null
    }

    return ($labels -join '.').ToLowerInvariant()
}

function New-EmptyConfigObject {
    param(
        [Parameter(Mandatory = $false)]
        [string]$DomainFqdn
    )

    if ([string]::IsNullOrWhiteSpace($DomainFqdn)) {
        $DomainFqdn = Get-CurrentDomainDnsName
    }

    $domainDn = ''
    $defaultAdminGroupOu = ''
    $defaultDelegationConfigPath = ''
    $defaultDomain = @()

    if (-not [string]::IsNullOrWhiteSpace($DomainFqdn)) {
        $domainDn = Convert-DomainToDistinguishedName -DomainFqdn $DomainFqdn
        if ($domainDn -ne '') {
            $defaultAdminGroupOu = "OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin,$domainDn"
        }

        $defaultDelegationConfigPath = "\\$DomainFqdn\SYSVOL\$DomainFqdn\Just-In-Time\JITdelegation.config"
        $defaultDomain = @($DomainFqdn)
    }

    return [PSCustomObject]@{
        ConfigScriptVersion = '0.1.0'
        AdminPreFix = 'Admin_'
        DomainSeparator = '#'
        EventLog = 'Tier 1 Management'
        EventSource = 'T1Mgmt'
        EnableDelegation = $true
        ElevateEventID = 100
        AdminGroupOU = $defaultAdminGroupOu
        DelegationConfigPath = $defaultDelegationConfigPath
        MaxElevatedTime = 1440
        DefaultElevatedTime = 60
        EnableMultiDomainSupport = $true
        UseManagedByforDelegation = $true
        MaxConcurrentServer = 50
        GroupManagementTaskRerun = 5
        GroupManagedServiceAccountName = 'KjitGmsa'
        ExcludeServerGroupName = ''
        LDAPexcludeComputer = '(&(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))'
        ComputerSearch = '(&(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))'
        AuthorizedServer = @()
        TargetOU = @()
        ExcludeComputerOU = @()
        Domain = $defaultDomain
    }
}

function Get-Value {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    foreach ($name in $Names) {
        if ($Object.PSObject.Properties.Name -contains $name) {
            return $Object.$name
        }
    }

    return $null
}

function To-StringList {
    param(
        [Parameter(Mandatory = $false)]$Values
    )

    $list = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $Values) {
        return ,$list
    }

    if ($Values -is [System.Array] -or $Values -is [System.Collections.IEnumerable] -and -not ($Values -is [string])) {
        foreach ($entry in $Values) {
            if ($null -ne $entry -and [string]$entry -ne '') {
                $list.Add([string]$entry)
            }
        }

        return ,$list
    }

    if ([string]$Values -ne '') {
        $list.Add([string]$Values)
    }

    return ,$list
}

function Convert-JsonToKjitConfigurationObject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $raw = Get-Content -Raw -Path $Path -ErrorAction Stop
    $json = $raw | ConvertFrom-Json

    $defaultDomain = Get-Value -Object $json -Names @('Domain')
    $domainSeed = $null
    if ($defaultDomain -is [System.Array] -and $defaultDomain.Count -gt 0) {
        $domainSeed = [string]$defaultDomain[0]
    }
    elseif ($null -ne $defaultDomain) {
        $domainSeed = [string]$defaultDomain
    }

    $cfg = New-EmptyConfigObject -DomainFqdn $domainSeed

    $value = Get-Value -Object $json -Names @('ConfigScriptVersion')
    if ($null -ne $value) { $cfg.ConfigScriptVersion = [string]$value }

    $value = Get-Value -Object $json -Names @('AdminPreFix')
    if ($null -ne $value) { $cfg.AdminPreFix = [string]$value }

    $value = Get-Value -Object $json -Names @('AdminGroupOU', 'OU')
    if ($null -ne $value -and $value -is [string]) { $cfg.AdminGroupOU = [string]$value }

    $value = Get-Value -Object $json -Names @('DelegationConfigPath')
    if ($null -ne $value) { $cfg.DelegationConfigPath = [string]$value }

    $value = Get-Value -Object $json -Names @('MaxElevatedTime')
    if ($null -ne $value) { $cfg.MaxElevatedTime = [int]$value }

    $value = Get-Value -Object $json -Names @('DefaultElevatedTime')
    if ($null -ne $value) { $cfg.DefaultElevatedTime = [int]$value }

    $value = Get-Value -Object $json -Names @('EventLog')
    if ($null -ne $value) { $cfg.EventLog = [string]$value }

    $value = Get-Value -Object $json -Names @('EventSource')
    if ($null -ne $value) { $cfg.EventSource = [string]$value }

    $value = Get-Value -Object $json -Names @('EnableDelegation')
    if ($null -ne $value) { $cfg.EnableDelegation = [bool]$value }

    $value = Get-Value -Object $json -Names @('ElevateEventID')
    if ($null -ne $value) { $cfg.ElevateEventID = [int]$value }

    $value = Get-Value -Object $json -Names @('EnableMultiDomainSupport')
    if ($null -ne $value) { $cfg.EnableMultiDomainSupport = [bool]$value }

    $value = Get-Value -Object $json -Names @('UseManagedByforDelegation')
    if ($null -ne $value) { $cfg.UseManagedByforDelegation = [bool]$value }

    $value = Get-Value -Object $json -Names @('MaxConcurrentServer')
    if ($null -ne $value) { $cfg.MaxConcurrentServer = [int]$value }

    $value = Get-Value -Object $json -Names @('GroupManagementTaskRerun')
    if ($null -ne $value) { $cfg.GroupManagementTaskRerun = [int]$value }

    $value = Get-Value -Object $json -Names @('GroupManagedServiceAccountName')
    if ($null -ne $value) {
        $gmsa = [string]$value
        if (-not $gmsa.EndsWith('$')) { $gmsa = "$gmsa$" }
        $cfg.GroupManagedServiceAccountName = $gmsa
    }

    $value = Get-Value -Object $json -Names @('ExcludeServerGroupName', 'Tier0ServerGroupName')
    if ($null -ne $value) { $cfg.ExcludeServerGroupName = [string]$value }

    $value = Get-Value -Object $json -Names @('LDAPexcludeComputer', 'LDAPT0Computers')
    if ($null -ne $value) { $cfg.LDAPexcludeComputer = [string]$value }

    $value = Get-Value -Object $json -Names @('ComputerSearch', 'LDAPT1Computers')
    if ($null -ne $value) { $cfg.ComputerSearch = [string]$value }

    $value = Get-Value -Object $json -Names @('DomainSeparator')
    if ($null -ne $value -and [string]$value -ne '') { $cfg.DomainSeparator = ([string]$value)[0] }

    $value = Get-Value -Object $json -Names @('Domain')
    if ($null -ne $value) {
        $cfg.Domain = To-StringList -Values $value
    }

    $value = Get-Value -Object $json -Names @('T1Searchbase')
    if ($null -ne $value) {
        $cfg.TargetOU = To-StringList -Values $value
    }

    $value = Get-Value -Object $json -Names @('ExcludeComputerOU')
    if ($null -ne $value) {
        $cfg.ExcludeComputerOU = To-StringList -Values $value
    }

    return $cfg
}

function Get-AdsiPropertyValue {
    param(
        [Parameter(Mandatory = $true)]$Properties,
        [Parameter(Mandatory = $true)][string[]]$Names,
        [switch]$AsList
    )

    foreach ($name in $Names) {
        if ($Properties.Contains($name) -and $Properties[$name].Count -gt 0) {
            $raw = @($Properties[$name])
            if ($AsList) {
                return (To-StringList -Values $raw)
            }

            return [string]$raw[0]
        }
    }

    if ($AsList) {
        return (To-StringList -Values @())
    }

    return $null
}

function Resolve-AdEntry {
    param(
        [Parameter(Mandatory = $true)][string]$Source
    )

    if ($Source.Contains('=') -and $Source.Contains(',')) {
        return [ADSI]("LDAP://$Source")
    }

    $rootDse = [ADSI]"LDAP://RootDSE"
    $configNc = [string]$rootDse.configurationNamingContext
    $searchBases = @(
        "CN=Just-In-Time Administration,CN=Services,$configNc",
        $configNc
    )

    foreach ($baseDn in $searchBases) {
        $searchRoot = [ADSI]("LDAP://$baseDn")
        $searcher = New-Object System.DirectoryServices.DirectorySearcher($searchRoot)
        $searcher.Filter = "(&(objectClass=*)(cn=$Source))"
        $result = $searcher.FindOne()
        if ($null -ne $result) {
            return $result.GetDirectoryEntry()
        }
    }

    throw "AD object '$Source' not found in configuration naming context."
}

function Convert-AdToKjitConfigurationObject {
    param(
        [Parameter(Mandatory = $true)][string]$Source
    )

    $entry = Resolve-AdEntry -Source $Source
    $props = $entry.Properties

    $entryDn = [string](Get-AdsiPropertyValue -Properties $props -Names @('distinguishedName'))
    $domainSeed = $null
    if (-not [string]::IsNullOrWhiteSpace($entryDn)) {
        $domainSeed = Get-DomainFromDistinguishedName -DistinguishedName $entryDn
    }

    $cfg = New-EmptyConfigObject -DomainFqdn $domainSeed

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-ConfigScriptVersion', 'ConfigScriptVersion')
    if ($null -ne $value) { $cfg.ConfigScriptVersion = $value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-AdminPreFix', 'AdminPreFix')
    if ($null -ne $value) { $cfg.AdminPreFix = $value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-JitAdmGroupOU', 'AdminGroupOU', 'OU')
    if ($null -ne $value) { $cfg.AdminGroupOU = $value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('DelegationConfigPath')
    if ($null -ne $value) { $cfg.DelegationConfigPath = $value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-MaxElevatedTime', 'MaxElevatedTime')
    if ($null -ne $value -and $value -match '^\d+$') { $cfg.MaxElevatedTime = [int]$value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-DefaultElevatedTime', 'DefaultElevatedTime')
    if ($null -ne $value -and $value -match '^\d+$') { $cfg.DefaultElevatedTime = [int]$value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-EventLog', 'EventLog')
    if ($null -ne $value) { $cfg.EventLog = $value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-EventSource', 'EventSource')
    if ($null -ne $value) { $cfg.EventSource = $value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-EnableDelegation', 'EnableDelegation')
    if ($null -ne $value) { $cfg.EnableDelegation = [bool]::Parse($value) }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-ElevateEventID', 'ElevateEventID')
    if ($null -ne $value -and $value -match '^\d+$') { $cfg.ElevateEventID = [int]$value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-EnableMultiDomainSupport', 'EnableMultiDomainSupport')
    if ($null -ne $value) { $cfg.EnableMultiDomainSupport = [bool]::Parse($value) }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('UseManagedByforDelegation')
    if ($null -ne $value) { $cfg.UseManagedByforDelegation = [bool]::Parse($value) }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-MaxConcurrentServer', 'MaxConcurrentServer')
    if ($null -ne $value -and $value -match '^\d+$') { $cfg.MaxConcurrentServer = [int]$value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('GroupManagementTaskRerun')
    if ($null -ne $value -and $value -match '^\d+$') { $cfg.GroupManagementTaskRerun = [int]$value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-GroupManagedServiceAccountName', 'GroupManagedServiceAccountName')
    if ($null -ne $value) {
        $gmsa = [string]$value
        if (-not $gmsa.EndsWith('$')) { $gmsa = "$gmsa$" }
        $cfg.GroupManagedServiceAccountName = $gmsa
    }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('ExcludeServerGroupName', 'Tier0ServerGroupName')
    if ($null -ne $value) { $cfg.ExcludeServerGroupName = $value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('LDAPexcludeComputer', 'LDAPT0Computers')
    if ($null -ne $value) { $cfg.LDAPexcludeComputer = $value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-LDAPT1Computers', 'ComputerSearch', 'LDAPT1Computers')
    if ($null -ne $value) { $cfg.ComputerSearch = $value }

    $value = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-DomainSeparator', 'DomainSeparator')
    if ($null -ne $value -and [string]$value -ne '') { $cfg.DomainSeparator = ([string]$value)[0] }

    $cfg.Domain = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-Domain', 'Domain') -AsList
    $cfg.AuthorizedServer = Get-AdsiPropertyValue -Properties $props -Names @('AuthorizedServer') -AsList
    $cfg.TargetOU = Get-AdsiPropertyValue -Properties $props -Names @('JitCnfg-T1Searchbase', 'T1Searchbase') -AsList
    $cfg.ExcludeComputerOU = Get-AdsiPropertyValue -Properties $props -Names @('ExcludeComputerOU', 'LDAPT0ComputerPath') -AsList

    return $cfg
}

function Normalize-ListForCompare {
    param([Parameter(Mandatory = $false)]$Value)
    $items = To-StringList -Values $Value
    return ($items | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' } | Sort-Object -Unique) -join ';'
}

function Normalize-PathForCompare {
    param([Parameter(Mandatory = $false)][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ''
    }

    return $Value.Trim().ToLowerInvariant()
}

function Convert-ToComparableRecord {
    param([Parameter(Mandatory = $true)]$Config)

    $targetOu = Get-Value -Object $Config -Names @('TargetOU', 'T1Searchbase', 'OU')

    return [ordered]@{
        ConfigScriptVersion = [string](Get-Value -Object $Config -Names @('ConfigScriptVersion'))
        AdminPreFix = [string](Get-Value -Object $Config -Names @('AdminPreFix'))
        AdminGroupOU = [string](Get-Value -Object $Config -Names @('AdminGroupOU', 'OU'))
        DelegationConfigPath = Normalize-PathForCompare -Value ([string](Get-Value -Object $Config -Names @('DelegationConfigPath')))
        MaxElevatedTime = [string](Get-Value -Object $Config -Names @('MaxElevatedTime'))
        DefaultElevatedTime = [string](Get-Value -Object $Config -Names @('DefaultElevatedTime'))
        EventLog = [string](Get-Value -Object $Config -Names @('EventLog'))
        EventSource = [string](Get-Value -Object $Config -Names @('EventSource'))
        EnableDelegation = [string](Get-Value -Object $Config -Names @('EnableDelegation'))
        ElevateEventID = [string](Get-Value -Object $Config -Names @('ElevateEventID'))
        EnableMultiDomainSupport = [string](Get-Value -Object $Config -Names @('EnableMultiDomainSupport'))
        UseManagedByforDelegation = [string](Get-Value -Object $Config -Names @('UseManagedByforDelegation'))
        MaxConcurrentServer = [string](Get-Value -Object $Config -Names @('MaxConcurrentServer'))
        GroupManagementTaskRerun = [string](Get-Value -Object $Config -Names @('GroupManagementTaskRerun'))
        GroupManagedServiceAccountName = [string](Get-Value -Object $Config -Names @('GroupManagedServiceAccountName'))
        ExcludeServerGroupName = [string](Get-Value -Object $Config -Names @('ExcludeServerGroupName', 'Tier0ServerGroupName'))
        LDAPexcludeComputer = [string](Get-Value -Object $Config -Names @('LDAPexcludeComputer', 'LDAPT0Computers'))
        ComputerSearch = [string](Get-Value -Object $Config -Names @('ComputerSearch', 'LDAPT1Computers'))
        DomainSeparator = [string](Get-Value -Object $Config -Names @('DomainSeparator'))
        Domain = Normalize-ListForCompare -Value (Get-Value -Object $Config -Names @('Domain'))
        AuthorizedServer = Normalize-ListForCompare -Value (Get-Value -Object $Config -Names @('AuthorizedServer'))
        TargetOU = Normalize-ListForCompare -Value $targetOu
        ExcludeComputerOU = Normalize-ListForCompare -Value (Get-Value -Object $Config -Names @('ExcludeComputerOU'))
    }
}

$resolvedConfigPath = Resolve-InputPath -Path $ConfigPath
$resolvedDllPath = Resolve-InputPath -Path $DllPath

$kjitCoreTypesAvailable = $false
try {
    Add-Type -Path $resolvedDllPath -ErrorAction Stop
    $kjitCoreTypesAvailable = $true
}
catch {
    Write-Warning "KjitCore.dll could not be loaded in this host. Using pure PowerShell fallback. Error: $($_.Exception.Message)"
}

if ($kjitCoreTypesAvailable) {
    $jsonConfig = [KjitCore.KjitCore]::LoadJitConfiguration($resolvedConfigPath.Path)
    $adConfig = [KjitCore.KjitCore]::LoadJitConfiguration($AdSource)
}
else {
    $jsonConfig = Convert-JsonToKjitConfigurationObject -Path $resolvedConfigPath.Path
    $adConfig = Convert-AdToKjitConfigurationObject -Source $AdSource
}

$jsonRecord = Convert-ToComparableRecord -Config $jsonConfig
$adRecord = Convert-ToComparableRecord -Config $adConfig

$differences = foreach ($key in $jsonRecord.Keys) {
    if ([string]$jsonRecord[$key] -cne [string]$adRecord[$key]) {
        [PSCustomObject]@{
            Property = $key
            JsonValue = [string]$jsonRecord[$key]
            AdValue = [string]$adRecord[$key]
        }
    }
}

Write-Host "JSON configuration:" -ForegroundColor Cyan
[PSCustomObject]$jsonRecord | Format-List

Write-Host "AD configuration:" -ForegroundColor Cyan
[PSCustomObject]$adRecord | Format-List

if ($differences.Count -eq 0) {
    Write-Host "Result: JSON and AD configuration objects are equal." -ForegroundColor Green
}
else {
    Write-Warning "Result: JSON and AD configuration objects differ."
    $differences | Format-Table -AutoSize
}
