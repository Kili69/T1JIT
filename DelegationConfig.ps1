<#
Script Info

Author: Andreas Lucas [MSFT]
Download: 

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
.Synopsis
    This script configures the delegation configuration 

.DESCRIPTION
    This script creates or updates a delegation configuration 

.EXAMPLE
    .\DelegationConfig.ps1

.INPUTS
    -Showconfig
        shows the current delegation
    -Add delegation
        add a new delegation to the configuration
    -Remove 
        removes a delegation from a OU
    -OU
        the delegated OU
    -Group
        The group of the delegation
.OUTPUTS
   none
.NOTES
    Version Tracking
    20231029 
    Version 0.1
        - First internal release
    
#>
<#
    script parameters
#>
[CmdletBinding(DefaultParameterSetName = 'ShowCurrentDelegation')]
param (
    [Parameter(Mandatory, ParameterSetName = 'ShowCurrentDelegation'   , Position = 0)]
    [switch]$ShowcurrentDelegation,
    [Parameter(Mandatory, ParameterSetName = 'AddDelegation'   , Position = 0)]
    [switch]$AddDelegation,
    [Parameter(Mandatory, ParameterSetName = 'RemoveDelegationFromOU', Position = 0)]
    [switch]$RemoveDelegation,
    [Parameter(Mandatory, ParameterSetName = 'RemoveOU', Position = 0)]
    [switch]$RemoveOU,
    [Parameter(Mandatory = $false, ParameterSetName = 'AddDelegation'  , Position = 1)]
    [Parameter(Mandatory = $false, ParameterSetName = 'RemoveDelegationFromOU', Position = 1)]
    [string]$Domain = $env:USERDNSDOMAIN,
    [Parameter(Mandatory, ParameterSetName = 'AddDelegation'   , Position = 2)]
    [Parameter(Mandatory, ParameterSetName = 'RemoveDelegationFromOU', Position = 2)]
    [string]$ADUserOrGroup,
    [Parameter(Mandatory, ParameterSetName = 'AddDelegation'   , Position = 3)]
    [Parameter(Mandatory, ParameterSetName = 'RemoveDelegationFromOU', Position = 3)]
    [Parameter(Mandatory, ParameterSetName = 'RemoveOU', Position = 1)]
    [String]$ComputerOU,
    [Parameter(Mandatory = $false, ParameterSetName = 'AddDelegation'   , Position = 4)]
    [Parameter(Mandatory = $false, ParameterSetName = 'RemoveDelegationFromOU', Position = 4)]
    [Parameter(Mandatory = $false, ParameterSetName = 'ShowCurrentDeletation'   , Position = 1)]
    [string]$configFileName = "$((Get-Location).Path)\JIT.config",
    [Parameter(Mandatory = $false, ParameterSetName = 'AddDelegation'   , Position = 5)]
    [Parameter(Mandatory = $false, ParameterSetName = 'RemoveDelegationFromOU', Position = 5)]
    [Parameter(Mandatory = $false, ParameterSetName = 'ShowCurrentDeletation'   , Position = 2)]
    [string[]]$InstallationDirectory = (Get-Location).Path
)


$Script_Version = "0.1.20231029"
Write-Host "Configure JIT delegation (script version $Script_Version)"
if ((Test-Path "$configFileName") -eq $true){
    $config = Get-Content "$configFileName" | ConvertFrom-Json
    if ((Test-Path $config.DelegationConfigPath) -eq $true){
        #$CurrentDelegation = Get-Content $config.DelegationConfigPath | ConvertFrom-Json
        $CurrentDelegation = Get-Content .\Delegation.config | ConvertFrom-Json
        $CurrentDelegation
    } else {
        $CurrentDelegation = @()
    }
} else {
    Write-Host "Missing JIT configurtion file"
    Return
}

if ($ShowcurrentDelegation) {
   $CurrentDelegation
   Return
}
if ($ComputerOU -eq ""){
    Write-Host "Missing orgnizational unit"
    Return
}
if ($ADUserOrGroup -eq ""){
    Write-Host "Missing Active Directory object"
    Return
}
#Seaching the AD object SID
$oSID = (Get-ADObject -Filter {SamAccountName -eq $ADUserOrGroup} -Properties ObjectSID -Server $Domain).ObjectSID.Value
if ($null -eq $oSID){
    Write-Host "Can't find $AduserOrGroup in $domain"
    Return
}
if (!(Get-ADObject -Filter {(DistinguishedName -eq $ComputerOU) -and (ObjectClass -eq "organizationalUnit")} -Server $Domain)){
    Write-Host "Can't find $computerOU in $Domain"
    Return
}
if ($AddDelegation) {
    $NewEntry = $true
    if ($CurrentDelegation.Count -gt 0){
        for ($i = 0; $i -lt $CurrentDelegation.Count; $i++){
            if ($CurrentDelegation[$i].ComputerOU -eq $ComputerOU){
                $NewEntry = $false 
                if (!($CurrentDelegation[$i].ADObject -contains $oSID)){
                    $CurrentDelegation[$i].ADObject += $oSID
                        #Writing configuration file
                        ConvertTo-Json $CurrentDelegation -AsArray -Depth 3 | Out-File $config.DelegationConfigPath -Confirm:$false
                }
                break
            }
        }
    }
    if ($NewEntry){
        $Delegation = New-Object psobject
        $Delegation | Add-Member NoteProperty "ComputerOU" -Value $ComputerOU 
        $Delegation | Add-Member NoteProperty "ADObject" -Value @($oSID)
        $CurrentDelegation += $Delegation
        #Writing configuration file
        ConvertTo-Json $CurrentDelegation -AsArray -Depth 3 | Out-File $config.DelegationConfigPath -Confirm:$false
        Return
    }
}
if ($RemoveDelegation){
    for ($i = 0; $i -lt $CurrentDelegation.Count; $i++){
        if ($CurrentDelegation[$i].ComputerOU -eq $ComputerOU){
            $tempSid = @()
            for ($iSID = 0; $iSID -lt $CurrentDelegation.Count; $i++){
                if ($CurrentDelegation[$i].ADObject[$iSID] -ne $oSID){
                    $tempSid += $CurrentDelegation[$i].ADObject[$iSID]
                }
            }
            $CurrentDelegation[$i].ADObject = $tempSid
            #Writing configuration file
            ConvertTo-Json $CurrentDelegation -AsArray -Depth 3 | Out-File $config.DelegationConfigPath -Confirm:$false
            Return
        }
    }
}
if ($RemoveOU){
    $tempOU = @()
    for ($i = 0; $i -lt $cursorColumn.count; $i++){
        if ($CurrentDelegation[$i].ComputerOU -ne $ComputerOU){
            $tempOU += $CurrentDelegation[$i]
        }
        #Writing configuration file
        ConvertTo-Json $CurrentDelegation -AsArray -Depth 3 | Out-File $config.DelegationConfigPath -Confirm:$false
        Return
    }
}
