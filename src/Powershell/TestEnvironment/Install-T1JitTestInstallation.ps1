#requires -Version 5.1
#requires -PSEdition Desktop
#requires -RunAsAdministrator

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
    Installs T1JIT and KjitWeb for the existing Servers test hierarchy.
.DESCRIPTION
    Creates a JIT configuration in SYSVOL, ensures the dedicated OU for generated
    administrator groups exists, invokes install-JIT.ps1 in silent mode with web
    installation enabled, and configures the requested OU delegations.

    The script does not create OU=Servers, OU=SQL, or either eligibility group.
    Those objects must already exist. Run Remove-T1JitInstallation.ps1 before this
    script when a clean installation test is required.
.PARAMETER InstallerRoot
    Folder containing install-JIT.ps1, modules, and the kjibweb folder.
.PARAMETER DomainController
    Optional domain controller used for validation and OU creation.
.PARAMETER AllowedClient
    Hostname or IP address allowed to access KjitWeb. Defaults to localhost.
.PARAMETER Port
    TCP port used by KjitWeb. Defaults to 5240.
.EXAMPLE
    .\Install-T1JitTestInstallation.ps1 -WhatIf
.EXAMPLE
    .\Install-T1JitTestInstallation.ps1 -AllowedClient PAW01.contoso.com -Verbose
.OUTPUTS
    System.Management.Automation.PSCustomObject describing the installed scenario.
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
param(
    [string]$InstallerRoot = (Join-Path $PSScriptRoot "..\..\..\release"),
    [string]$DomainController,
    [ValidateNotNullOrEmpty()]
    [string]$GlobalEligibilityGroup = "Global Server Administrators",
    [ValidateNotNullOrEmpty()]
    [string]$SqlEligibilityGroup = "SQL-Admins",
    [ValidateNotNullOrEmpty()]
    [string]$AllowedClient = "localhost",
    [ValidateRange(1, 65535)]
    [int]$Port = 5240,
    [ValidateNotNullOrEmpty()]
    [string]$CompanyName = "T1JIT Test Installation"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$installerRootPath = (Resolve-Path -LiteralPath $InstallerRoot).Path
$installerPath = Join-Path $installerRootPath "install-JIT.ps1"
if (-not (Test-Path -LiteralPath $installerPath -PathType Leaf)) {
    throw "Installer not found: $installerPath"
}

Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false
Import-Module ScheduledTasks -ErrorAction Stop -Verbose:$false
$adParameters = @{}
if (-not [string]::IsNullOrWhiteSpace($DomainController)) {
    $adParameters.Server = $DomainController
}

$domain = Get-ADDomain @adParameters
$forest = Get-ADForest @adParameters
if (-not (Get-ADOptionalFeature -Filter "name -eq 'Privileged Access Management Feature'" @adParameters).EnabledScopes) {
    throw "The Active Directory Privileged Access Management Feature is not enabled in forest '$($forest.Name)'."
}

$serversOu = "OU=Servers,$($domain.DistinguishedName)"
$sqlOu = "OU=SQL,$serversOu"
$adminGroupsOu = "OU=JIT-Administrator Groups,$($domain.DistinguishedName)"
$globalGroup = Get-ADGroup -Identity $GlobalEligibilityGroup @adParameters
$sqlGroup = Get-ADGroup -Identity $SqlEligibilityGroup @adParameters
$null = Get-ADOrganizationalUnit -Identity $serversOu @adParameters
$null = Get-ADOrganizationalUnit -Identity $sqlOu @adParameters

$administratorGroupsOu = $null
try {
    $administratorGroupsOu = Get-ADOrganizationalUnit -Identity $adminGroupsOu @adParameters -ErrorAction Stop
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Verbose "The JIT administrator groups OU does not exist and will be created."
}

if ($null -eq $administratorGroupsOu) {
    if ($PSCmdlet.ShouldProcess($adminGroupsOu, "Create OU for generated JIT administrator groups")) {
        $null = New-ADOrganizationalUnit -Name "JIT-Administrator Groups" -Path $domain.DistinguishedName -ProtectedFromAccidentalDeletion $false @adParameters
    }
}

$configurationDirectory = "\\$($domain.DNSRoot)\SYSVOL\$($domain.DNSRoot)\Just-In-Time"
$configurationPath = Join-Path $configurationDirectory "JIT.config"
$delegationPath = Join-Path $configurationDirectory "Tier1delegation.config"
$configuration = [ordered]@{
    ConfigScriptVersion            = "0.1.20260824"
    AdminPreFix                    = "Admin_"
    OU                             = $adminGroupsOu
    MaxElevatedTime                = 1440
    DefaultElevatedTime            = 60
    ElevateEventID                 = 100
    LDAPT0Computers                = "(&(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))"
    LDAPT0ComputerPath             = "OU=Tier 0,OU=Admin"
    LDAPT1Computers                = "(&(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))"
    EventSource                    = "T1Mgmt"
    EventLog                       = "Tier 1 Management"
    GroupManagementTaskRerun       = 5
    GroupManagedServiceAccountName = "T1GroupMgmt"
    Domain                         = $domain.DNSRoot
    DelegationConfigPath           = $delegationPath
    EnableDelegation               = $true
    EnableMultiDomainSupport       = $false
    T1Searchbase                   = @($serversOu)
    DomainSeparator                = "#"
    UseManagedByforDelegation      = $true
    MaxConcurrentServer            = 50
}

if ($PSCmdlet.ShouldProcess($configurationPath, "Create JIT and delegation configuration files")) {
    $null = New-Item -Path $configurationDirectory -ItemType Directory -Force
    $configuration | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $configurationPath -Encoding UTF8
    "[]" | Set-Content -LiteralPath $delegationPath -Encoding UTF8
}

if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Install T1JIT and KjitWeb from $installerPath")) {
    Push-Location $installerRootPath
    try {
        & $installerPath -silent -JitConfigFile $configurationPath -InstallWeb -AllowedClient $AllowedClient -CompanyName $CompanyName -Port $Port
        if (-not $?) {
            throw "install-JIT.ps1 returned an unsuccessful exit state."
        }
    }
    finally {
        Pop-Location
    }

    $globalAccountName = "$($domain.NetBIOSName)\$($globalGroup.SamAccountName)"
    $sqlAccountName = "$($domain.NetBIOSName)\$($sqlGroup.SamAccountName)"
    $modulePath = Join-Path $env:ProgramFiles "WindowsPowerShell\Modules\Just-In-Time\Just-In-Time.psd1"
    $delegationEnvironment = @{
        T1JIT_MODULE_PATH    = $modulePath
        T1JIT_SERVERS_OU     = $serversOu
        T1JIT_SQL_OU         = $sqlOu
        T1JIT_GLOBAL_ACCOUNT = $globalAccountName
        T1JIT_SQL_ACCOUNT    = $sqlAccountName
    }
    $delegationScriptPath = Join-Path ([IO.Path]::GetTempPath()) "T1JIT-delegation-$PID.ps1"
    try {
        foreach ($entry in $delegationEnvironment.GetEnumerator()) {
            [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, [EnvironmentVariableTarget]::Process)
        }
        @'
$ErrorActionPreference = "Stop"
try {
    Import-Module $env:T1JIT_MODULE_PATH -Force -ErrorAction Stop -Verbose:$false
    Add-JitDelegation -OU $env:T1JIT_SERVERS_OU -ADobject $env:T1JIT_GLOBAL_ACCOUNT | Out-Null
    Add-JitDelegation -OU $env:T1JIT_SQL_OU -ADobject $env:T1JIT_SQL_ACCOUNT | Out-Null

    $delegations = @(Get-JitDelegation)
    $serversDelegation = $delegations | Where-Object OU -EQ $env:T1JIT_SERVERS_OU
    $sqlDelegation = $delegations | Where-Object OU -EQ $env:T1JIT_SQL_OU
    if (-not $serversDelegation -or $serversDelegation.SID -notcontains $env:T1JIT_GLOBAL_ACCOUNT) {
        throw "Delegation for '$($env:T1JIT_GLOBAL_ACCOUNT)' on '$($env:T1JIT_SERVERS_OU)' was not persisted."
    }
    if (-not $sqlDelegation -or $sqlDelegation.SID -notcontains $env:T1JIT_SQL_ACCOUNT) {
        throw "Delegation for '$($env:T1JIT_SQL_ACCOUNT)' on '$($env:T1JIT_SQL_OU)' was not persisted."
    }
}
catch {
    Write-Error $_
    exit 1
}
'@ | Set-Content -LiteralPath $delegationScriptPath -Encoding UTF8
        & powershell.exe -NoProfile -NonInteractive -File $delegationScriptPath
        if ($LASTEXITCODE -ne 0) {
            throw "JIT delegation configuration failed in the isolated Windows PowerShell process."
        }
    }
    finally {
        Remove-Item -LiteralPath $delegationScriptPath -Force -ErrorAction SilentlyContinue
        foreach ($name in $delegationEnvironment.Keys) {
            [Environment]::SetEnvironmentVariable($name, $null, [EnvironmentVariableTarget]::Process)
        }
    }

    $service = Get-Service -Name "KjitWeb" -ErrorAction Stop
    if ($service.Status -ne "Running") {
        throw "KjitWeb was installed but is not running. Current state: $($service.Status)."
    }
    $null = Get-ADServiceAccount -Identity $configuration.GroupManagedServiceAccountName @adParameters
    $null = Get-ScheduledTask -TaskPath "\Just-In-Time-Privilege\" -TaskName "Tier 1 Local Group Management" -ErrorAction Stop
    $null = Get-ScheduledTask -TaskPath "\Just-In-Time-Privilege\" -TaskName "Elevate User" -ErrorAction Stop

}

$webUrl = if ($AllowedClient -ieq "localhost") {
    "http://localhost:$Port"
}
else {
    "http://$($env:COMPUTERNAME).$($domain.DNSRoot):$Port"
}

[pscustomobject]@{
    InstallationValidated    = -not $WhatIfPreference
    ConfigurationPath       = $configurationPath
    DelegationPath          = $delegationPath
    ServersOU               = $serversOu
    ServersEligibilityGroup = $globalGroup.DistinguishedName
    SqlOU                   = $sqlOu
    SqlEligibilityGroup     = $sqlGroup.DistinguishedName
    WebUrl                  = $webUrl
}