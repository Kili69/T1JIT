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

<#
.SYNOPSIS
    Creates an Active Directory OU structure for T1JIT tests.
.DESCRIPTION
    Creates the Server base OU, role OUs, test computer accounts, and independent
    security groups. If the base OU does not exist, it is created below the domain
    root before any child objects are processed. Created OUs are not protected from
    accidental deletion. Security groups are stored in a Groups OU below the base
    OU. Existing objects are reused and computer attributes are updated. This script
    is intended only for disposable test environments.
.PARAMETER DomainController
    Optional domain controller used for all Active Directory operations.
.PARAMETER BaseOUName
    Name of the base OU created below the domain root.
.PARAMETER ComputerCountPerOU
    Number of computer accounts created in each role OU.
.PARAMETER WindowsServerVersion
    Windows Server year used for the OperatingSystem attribute.
.EXAMPLE
    .\New-T1JitTestEnvironment.ps1 -WhatIf
.EXAMPLE
    .\New-T1JitTestEnvironment.ps1 -DomainController dc01.contoso.com
.NOTES
    Script version: 0.1.20260824
    Requires the ActiveDirectory PowerShell module and permissions to create or
    update organizational units, groups, and computer accounts.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
param(
    [Parameter()]
    [string]$DomainController,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$BaseOUName = "Server",

    [Parameter()]
    [ValidateRange(1, 99)]
    [int]$ComputerCountPerOU = 3,

    [Parameter()]
    [ValidatePattern('^20\d{2}$')]
    [string]$WindowsServerVersion = "2022"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$scriptVersion = "0.1.20260824"

Write-Host "New-T1JitTestEnvironment script version $scriptVersion"

Import-Module ActiveDirectory -ErrorAction Stop

# Reused splat for routing every AD cmdlet to the optional domain controller.
$adParameters = @{}
if (-not [string]::IsNullOrWhiteSpace($DomainController)) {
    $adParameters.Server = $DomainController
}

# Domain metadata supplies the LDAP root and DNS suffix used by all generated objects.
$domain = Get-ADDomain @adParameters
$domainDistinguishedName = $domain.DistinguishedName
$domainDnsName = $domain.DNSRoot

# Fully qualified parent OU path used when creating groups, role OUs, and computers.
$baseOUDistinguishedName = "OU=$BaseOUName,$domainDistinguishedName"

# Dedicated container below the base OU for all security groups created by this script.
$groupsOUDistinguishedName = "OU=Groups,$baseOUDistinguishedName"

# OperatingSystem attribute value assigned to every created or updated computer account.
$operatingSystem = "Windows Server $WindowsServerVersion"

# Child OU names and their matching prefixes for generated computer account names.
$ouDefinitions = @(
    1..10 | ForEach-Object {
        [pscustomobject]@{
            Name = "Application$_"
            ComputerPrefix = "APP$_"
        }
    }
    [pscustomobject]@{ Name = "File-Server"; ComputerPrefix = "FILE" }
    [pscustomobject]@{ Name = "Terminal-Server"; ComputerPrefix = "TERM" }
    [pscustomobject]@{ Name = "SQL"; ComputerPrefix = "SQL" }
)

<#
.SYNOPSIS
    Returns an existing organizational unit or creates it when it is missing.
.DESCRIPTION
    Builds the distinguished name from Name and Path and queries Active Directory
    for that exact organizational unit. A missing object is treated as an expected
    condition. The function creates the OU without accidental-deletion protection
    only after ShouldProcess approves the operation, which preserves support for
    -WhatIf on the calling script.

    Active Directory errors other than an object not being found are not suppressed.
.PARAMETER Name
    Name of the organizational unit without the OU= prefix.
.PARAMETER Path
    Distinguished name of the parent container in which the OU is expected.
.OUTPUTS
    Microsoft.ActiveDirectory.Management.ADOrganizationalUnit when the OU exists or
    is created. No object is returned when creation is skipped by -WhatIf.
#>
function Initialize-OrganizationalUnit {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $distinguishedName = "OU=$Name,$Path"
    try {
        $organizationalUnit = Get-ADOrganizationalUnit -Identity $distinguishedName @adParameters -ErrorAction Stop
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        $organizationalUnit = $null
    }

    if ($null -eq $organizationalUnit -and $PSCmdlet.ShouldProcess($distinguishedName, "Create organizational unit")) {
        $organizationalUnit = New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $false -PassThru @adParameters
        Write-Information "Created organizational unit: $distinguishedName" -InformationAction Continue
    }

    $organizationalUnit
}

<#
.SYNOPSIS
    Returns an existing security group or creates it when it is missing.
.DESCRIPTION
    Searches for a security group by SamAccountName. If no matching group exists,
    the function creates a global security group in Path after ShouldProcess approves
    the operation. This preserves support for -WhatIf on the calling script.
.PARAMETER Name
    Name and SamAccountName of the security group.
.PARAMETER Path
    Distinguished name of the organizational unit in which a new group is created.
.OUTPUTS
    Microsoft.ActiveDirectory.Management.ADGroup when the group exists or is
    created. No object is returned when creation is skipped by -WhatIf.
#>
function Initialize-SecurityGroup {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $group = Get-ADGroup -Filter "SamAccountName -eq '$Name'" @adParameters -ErrorAction SilentlyContinue
    if ($null -eq $group -and $PSCmdlet.ShouldProcess($Name, "Create security group in $Path")) {
        $group = New-ADGroup -Name $Name -SamAccountName $Name -GroupCategory Security -GroupScope Global -Path $Path -PassThru @adParameters
        Write-Information "Created security group: CN=$Name,$Path" -InformationAction Continue
    }

    $group
}

Initialize-OrganizationalUnit -Name $BaseOUName -Path $domainDistinguishedName | Out-Null
Initialize-OrganizationalUnit -Name "Groups" -Path $baseOUDistinguishedName | Out-Null
Initialize-SecurityGroup -Name "Server-Administrator" -Path $groupsOUDistinguishedName | Out-Null

foreach ($ouDefinition in $ouDefinitions) {
    $ouDistinguishedName = "OU=$($ouDefinition.Name),$baseOUDistinguishedName"
    Initialize-OrganizationalUnit -Name $ouDefinition.Name -Path $baseOUDistinguishedName | Out-Null
    Initialize-SecurityGroup -Name "Server-Administrator-$($ouDefinition.Name)" -Path $groupsOUDistinguishedName | Out-Null

    foreach ($computerNumber in 1..$ComputerCountPerOU) {
        $computerName = "{0}-SRV{1:D2}" -f $ouDefinition.ComputerPrefix, $computerNumber
        $dnsHostName = "$computerName.$domainDnsName".ToLowerInvariant()
        $computer = Get-ADComputer -Filter "SamAccountName -eq '$computerName`$'" @adParameters -Properties DNSHostName, OperatingSystem -ErrorAction SilentlyContinue

        if ($null -eq $computer) {
            if ($PSCmdlet.ShouldProcess($computerName, "Create computer in $ouDistinguishedName")) {
                New-ADComputer -Name $computerName -SamAccountName "$computerName`$" -DNSHostName $dnsHostName -OperatingSystem $operatingSystem -Path $ouDistinguishedName -Enabled $false @adParameters
            }
        }
        elseif ($PSCmdlet.ShouldProcess($computerName, "Update DNSHostName and OperatingSystem")) {
            Set-ADComputer -Identity $computer -DNSHostName $dnsHostName -OperatingSystem $operatingSystem @adParameters
        }
    }
}

Write-Host "T1JIT test environment created below $baseOUDistinguishedName." -ForegroundColor Green