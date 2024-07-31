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
.PARAMETER action
    ShowCurrentDelegation
        Displays the current delegation file
    AddDelegation
        Adds a new OU delegation configuration. This parameter requres the OU path and the user/group name
    RemoveDelegation
        Removes a OU path from the delegation configuration
    RemoveUserOrGroup
        Remove a existing user / group from a OU delegation. This paramter support 
            UPN (myuser@contoso.com)
            SAM account names (contoso\mygroup)
            CommonName (mygroup)
.PARAMETER OU
    Is the distinguised name of the JIT delegation OU. this parameter is used on the actions:
        AddDelegation
        RemoveDelegation
        RemoveUserOrGroup
.PARAMETER ADUserOrGroup
    is the user / group name which should be added / remvoed from the delegation configuration. This parameter is used on the actions:
        AddDelegation
        RemoveUserOrGroup
.PARAMETER configFileName
    is the path to the delegation.config file. If this parameter should be used if the jit.config file is not located in the current directory

.OUTPUTS
   delegation.config
.EXAMPLE
    delegationconfig.ps1
        shows the current delegation configuration
    delegationconfig.ps1 -action showCurrentDelegation
        shows the current delegation configuration
    delegationconfig.ps1 -action AddDelegation -OU "OU=Servers,DC=contoso,DC=com" -ADUserOrGroup "contoso\mygroup"
        add the mygroup to OU=Servers,DC=contoso,DC=com delegation. mygroup can now get access to any computer in this OU
    delegationconfig.ps1 -action RemoveDelegation .OU "OU=Servers,DC=contoso,DC=com"
        removes the entire OU from the configuration
    delegationconfig.ps1 -action RemoveUserOrGroup -OU "OU=Servers,DC=contoso,DC=com" -ADUserOrGroup "myuser@contoso.com"
        removes the access for myuser@contoso.com from O=Servers,DC=contoso,DC=com
.NOTES
    Version Tracking
    20231029 
    Version 0.1
        - First internal release
    0.1.20240122
        - Bug fix
        -interactive support
    0.1.20240126
        - Bug fix on JSON writing
    0.1.20240726
        - Using the environment variable $end:JustIntimeConfig if the parameter configFileName is not provided
    
#>
<#
    script parameters
#>
[CmdletBinding(DefaultParameterSetName = 'ShowCurrentDelegation')]
param (
    [Parameter(Position = 1)]
    [ValidateSet('ShowCurrentDelegation', 'AddDelegation', 'RemoveDelegation', 'RemoveUserOrGroup')]
    [string]$action,
    [Parameter(Position = 2)]
    [string]$OU = "",
    [Parameter(Position = 2)]
    [string]$ADUserOrGroup,
    [Parameter (Position = 3)]
    [string]$configFileName    
)

function ValidateOU {
    param(
        [Parameter (Position = 1)]
        [String]$OU
    )  
    $DomainDNS = ""    
    Do {
        if ($OU -eq ""){
            $OU=Read-Host "OU path"
        }
        if (!($OU -match "^(OU=[^,]+,)+(DC=[^,]+,)+DC=.+")){
            Write-Host "Invalid OU path" -ForegroundColor Red
            $OU= ""
        } else {
            $DomainDN = $OU -replace "^(OU=[^,]+,)+"
            Foreach ($ForestDomain in (Get-ADForest).Domains){
                if ((Get-ADDomain -Server $ForestDomain).DistinguishedName -eq $domainDN){
                    $DomainDNS = $ForestDomain
                    break
                }
            }
            #$ComputerDomainDNS = (Get-ADForest).domains | Where-Object {(Get-ADDomain -Server $_).DistinguishedName -like "$domainDN"}    
            if ($DomainDNS -eq ""){
                Write-Host "Invalid domain" -ForegroundColor Red
                $OU=""
            } else {
                If ($Null -eq (Get-ADObject -Filter 'DistinguishedName -eq $OU' -Server $DomainDNS)){
                    Write-Host "Invalid OU path" -ForegroundColor Red
                    $OU=""
                }
            }
        }
    } while ($OU -eq "")
    return $OU
}
function Get-Sid{
    param (
        [Parameter ()]
        [string] $Name
    )
    $OSID = ""
    $GC = (Get-ADDomainController -Discover -Service GlobalCatalog)
    do{
        if ($Name -eq ""){
            $Name = Read-Host "Domain user or Group"
        }
        switch -Wildcard ($Name){
            "*@*" { 
                $OSID= (Get-ADObject -Filter{UserprincipalName -eq $Name} -Server $GC -Properties ObjectSID).ObjectSid.Value
            }
            "*\*" {
                $UserNetBiosName = $Name.Split("\")
                $UserName = $UserNetBiosName[1]
                $DomainDNS = (Get-ADForest).Domains | Where-Object {(Get-ADDomain -Server $_).NetBiosName -eq $userNetBiosName[0]}
                $OSID= (Get-ADObject -Filter{SamAccountName -like $UserName} -Server $DomainDNS -Properties ObjectSId).ObjectSID.Value
            }
            Default {
                $OSID = (Get-ADObject -Filter {cn -eq $Name} -Properties ObjectSID).ObjectSid.Value
            }
        }
        if ($Null -eq $OSID ){
            $Name = ""
        }
    } while ($Name -eq "")
    return $OSID
}

$Script_Version = "0.1.20240726"
$CurrentDelegation = @()
Write-Host "Configure JIT delegation (script version $Script_Version)"
#validate the jit.cofig exists. Load the delelgation.config is the file exists
if ($configFileName -eq ""){
    $configFileName = $env:JustInTimeConfig
}
if ((Test-Path "$configFileName") -eq $true){
    $config = Get-Content "$configFileName" | ConvertFrom-Json
    if ((Test-Path $config.DelegationConfigPath)){
        $CurrentDelegation += Get-Content "$($config.DelegationConfigPath)" | ConvertFrom-Json 
    }
} else {
    Write-Host "Missing JIT configurtion file"
    Return
}
switch ($action) {
    'AddDelegation' {
        $OU= ValidateOU -OU $OU
        $ObjectSId = Get-Sid $ADUserOrGroup
        $NewEntry = $true
        if ($CurrentDelegation.Count -gt 0){
            for ($i = 0; $i -lt $CurrentDelegation.Count; $i++){
                if ($CurrentDelegation[$i].ComputerOU -eq $OU){
                    $NewEntry = $false 
                    if (!($CurrentDelegation[$i].ADObject -contains $objectSId)){
                        $CurrentDelegation[$i].ADObject += $objectSId
                    }
                    break
                }
            }
        }
        if ($NewEntry){
            $Delegation = New-Object psobject
            $Delegation | Add-Member NoteProperty "ComputerOU" -Value $OU 
            $Delegation | Add-Member NoteProperty "ADObject" -Value @($ObjectSID)
            $CurrentDelegation += $Delegation
        }
        #Writing configuration file
        #ConvertTo-Json $CurrentDelegation -AsArray -Depth 3 | Out-File "$($config.DelegationConfigPath)\$DelegationFilename" -Confirm:$false
        ConvertTo-Json $CurrentDelegation  | Out-File $config.DelegationConfigPath -Confirm:$false
        Write-Host "configuration updated"
    }
    'RemoveDelegation'{
        $tempDelegation = @()
        for ($i = 0; $i -lt $CurrentDelegation.count; $i++){
            if ($CurrentDelegation[$i].ComputerOU -ne $OU){
                $tempDelegation += $CurrentDelegation[$i]
            }
        }
        #Writing configuration file
        ConvertTo-Json $tempDelegation | Out-File $config.DelegationConfigPath -Confirm:$false
        Write-Host "configuration updated"
      }
    'RemoveUserOrGroup'{
        $ObjectSID = Get-Sid $ADUserOrGroup
        for ($i = 0; $i -lt $CurrentDelegation.count;$i++){
            if ($CurrentDelegation[$i].ComputerOU -eq $OU){
                $tempSIDList = @()
                Foreach ($SID in $CurrentDelegation[$i].ADObject){
                    if ($SID -ne $ObjectSId){
                        $tempSIDList +=  $SID
                    }
                }
                $CurrentDelegation[$i].ADObject = $tempSIDList
                #Writing configuration file
                ConvertTo-Json $CurrentDelegation | Out-File $config.DelegationConfigPath -Confirm:$false
                Write-Host "configuration updated"
                break    
            }
        }
    }
    Default {
        For($iOU= 0; $iOU -lt $CurrentDelegation.Count; $iOU++){
            Write-Host "Path: $($CurrentDelegation[$iOU].ComputerOU)" -ForegroundColor Green
            For($iSID = 0; $iSID -lt $CurrentDelegation[$iOU].ADObject.count;$iSID++){
                $SID = New-Object System.Security.Principal.SecurityIdentifier($CurrentDelegation[$iOU].ADObject[$iSID])
                Write-Host "    $($SID.Translate([System.Security.Principal.NTAccount]))" -ForegroundColor Yellow
            }
        }
    }
}

