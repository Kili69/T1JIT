<#
.SYNOPSIS
    Creates an Active Directory OU structure for T1JIT tests.
.DESCRIPTION
    Creates the Server base OU, role OUs, test computer accounts, and independent
    security groups. Existing objects are reused and computer attributes are updated.
    This script is intended only for disposable test environments.
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

Import-Module ActiveDirectory -ErrorAction Stop

$adParameters = @{}
if (-not [string]::IsNullOrWhiteSpace($DomainController)) {
    $adParameters.Server = $DomainController
}

$domain = Get-ADDomain @adParameters
$domainDistinguishedName = $domain.DistinguishedName
$domainDnsName = $domain.DNSRoot
$baseOUDistinguishedName = "OU=$BaseOUName,$domainDistinguishedName"
$operatingSystem = "Windows Server $WindowsServerVersion"
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

function Ensure-OrganizationalUnit {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $distinguishedName = "OU=$Name,$Path"
    $organizationalUnit = Get-ADOrganizationalUnit -Identity $distinguishedName @adParameters -ErrorAction SilentlyContinue
    if ($null -eq $organizationalUnit -and $PSCmdlet.ShouldProcess($distinguishedName, "Create organizational unit")) {
        $organizationalUnit = New-ADOrganizationalUnit -Name $Name -Path $Path -PassThru @adParameters
    }

    $organizationalUnit
}

function Ensure-SecurityGroup {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $group = Get-ADGroup -Filter "SamAccountName -eq '$Name'" @adParameters -ErrorAction SilentlyContinue
    if ($null -eq $group -and $PSCmdlet.ShouldProcess($Name, "Create security group in $Path")) {
        $group = New-ADGroup -Name $Name -SamAccountName $Name -GroupCategory Security -GroupScope Global -Path $Path -PassThru @adParameters
    }

    $group
}

Ensure-OrganizationalUnit -Name $BaseOUName -Path $domainDistinguishedName | Out-Null
Ensure-SecurityGroup -Name "Server-Administrator" -Path $baseOUDistinguishedName | Out-Null

foreach ($ouDefinition in $ouDefinitions) {
    $ouDistinguishedName = "OU=$($ouDefinition.Name),$baseOUDistinguishedName"
    Ensure-OrganizationalUnit -Name $ouDefinition.Name -Path $baseOUDistinguishedName | Out-Null
    Ensure-SecurityGroup -Name "Server-Administrator-$($ouDefinition.Name)" -Path $ouDistinguishedName | Out-Null

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