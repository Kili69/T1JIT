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
    This script add the user object into a local group 

.DESCRIPTION
    This script adds users to the JIT administrators groups. The script is triggerd by the schedule 
    task in the context of the Group Managed service accounts.

.EXAMPLE
    .\ElevateUser.ps1   1000, xxx, .\jit.config
    $ConfigurationFile

.INPUTS
    -TargetDirectory
        Install the solution into another directory then the Windows Powershell script directory 
    -CreateGMSA [$true|$false]
        Create a new GMSA and install the GMSA on this computer
    -ServerEnumerationTime
        Rerun time for scheduled task
    -DebugOutput [$true|$false]
        For test purposes only, print out debug info.

.OUTPUTS
   none
.NOTES
    Version Tracking
    Version 0.1.20231031
        Support of delegation mode
#>
<#
Event ID's
2000 Error Configuration file missing
2001
2002
2003
2004 Information The user is already user of this group. TTL will be updated
2005 Inf
2100 Error can find the server object in AD
2101 Error The delegation JSON file is not available
2102 Error The Server OU path is not defined in the Delegation.config file
2103 Warning No SId mataches to the delegated OU
#>
[CmdletBinding(DefaultParameterSetName = 'DelegationModel')]
param(
    [Parameter (Mandatory, Position = 0)]
    #Record ID to identify the event
    [int]$eventRecordID,
    #[Parameter (Mandatory, Position = 1)]
    #The Windows Event Channel
    #$eventChannel,
    [Parameter (Mandatory = $false, Position = 2)]
    #The path to the configuration file
    [string]$ConfigurationFile,
    [Parameter (Mandatory = $false, Position = 3)]
    #If the script should use the Delegation Model this parameter must be set to true. The delegation model requires the delegation.config file
    [bool] $useDelegationModel = $false
    )
<#
.SYNOPSIS
    Evalutation of group membership of a user
.DESCRIPTION
    Evaluates recursive the group membership of a user and return a arry all SID where the user / group is member of
.INPUTS
    -DistinguishedName of the user / group
    -DomainDNS is the domain name where the user / group is located
.OUTPUTS
    - returns a string array of all SIDs
.NOTES
    This function uses the Active-Directory Powershell module
    The function depends on the memberof Backlink. While this attribute is calculated by the DC, it may take a while until 
    the group appears if the memberof attribute

    Version 20231108
        this version do not support mulit domain group memberships
#>
function Get-MemberofSID{
    param (
        [Parameter (Mandatory,Position= 0)]
        #Distinguishedname of the user / group
        [string]$DistinguishedName,
        [Parameter (Mandatory, Position=1)]
        #DNS of the user /group domain
        [string]$DomainDNS
    )
    $oADobject = Get-ADObject -filter {DistinguishedName -eq $DistinguishedName} -Properties ObjectSid, memberof
    $oSId = [System.Collections.ArrayList]::new()
    $oSid += $oADobject.ObjectSID.Value
    foreach ($membership in $oAdobject.MemberOf){
        $oSId += Get-MemberofSID $membership -DomainDNS $DomainDNS
    }
    $oSid = $oSId | Select-Object -Unique
    Return $oSId
}

#Main Programm starts here
#validate the configuration file is available and accessible
if ($ConfigurationFile -eq "")
{
    #if the parameter $configurationFile is null set the JIT.config path to current directory
    $ConfigurationFile = (Get-Location).Path + '\JIT.config'
}
#Validate the JIT.config file is available
if (!(Test-Path $ConfigurationFile))
{
    #Return a error if the JIT.config is not available
    Write-EventLog -LogName 'JIT Management' -Source 'T1Mgmt' -EventId 1 -EntryType Error -Message "Configuration file missing $configurationFile"
    Write-Host "Missing configuration file $configurationFile. Script aborted" -ForegroundColor Red
    return
}
#Read the configuration file from a JSON file
$config = Get-Content $ConfigurationFile | ConvertFrom-Json
#Search fpr the event record in the eventlog
#$eventLog = $config.EventLog
#$ElevateEventID = $config.ElevateEventID
#$RequestEvent = Get-WinEvent  -LogName $config.EventLog -FilterXPath "<QueryList><Query Id='$($config.ElevateEventID)' Path='$($config.EventLog)'><Select Path='$($config.EventLog))'>*[System[(EventRecordID='$eventRecordID')]]</Select></Query></QueryList>"
$RequestEvent = Get-WinEvent -FilterHashtable @{LogName = $config.EventLog; ID= $config.ElevateEventID} | Where-Object -Property RecordId -eq $eventRecordID
$Request = ConvertFrom-Json $RequestEvent.Message

$ServerGroupName = $Request.ServerGroup
#$ServerDomain = $Request.ServerDomain
$UserDN = $Request.UserDN
#$TTL = $Request.ElevationTime
#$AdminGroup = Get-ADGroup -Filter {SamAccountName -eq $($Request.ServerGroupName)} -Server $config.Domain
$AdminGroup = Get-ADObject -Filter {(SamAccountName -eq $ServerGroupName) -and (ObjectClass -eq "Group")}
#check the elevation group is available. If not terminate the script
if ($null -eq $AdminGroup )
{
    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 2001 -EntryType Error -Message "Can not find $ServerGroupName"
    return
}
#$User = Get-ADuser -Filter {DistinguishedName -eq $($Request.UserDN)} -Properties MemberOf,ObjectSID -Server $config.Domain
$User = Get-ADObject -Filter{(DistinguishedName -eq $UserDN) -and (ObjectClass -eq "User")} -Properties MemberOf, ObjectSID -Server $config.Domain
#check the user object is available, If not terminate the script
if ($null -eq $User ) 
{
    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 2002 -EntryType Error -Message "Invalid user in request $config"
    return
}
#This scection check the permission for this user if the elevation version is enabled
if ($useDelegationModel){
    #continue here if the delegation model is enabled 
    #Search and read the delegation.config file. If the file is not available terminate the script
    if (!(Test-path $config.DelegationConfigPath)){
        Write-EventLog -source $config.EventLog -EventId 2101 -EntryType Error -Message "Can't find delegation JSON file $($config.DelegationConfigPath)"
        return
    }
    $Delegation = Get-Content $config.DelegationConfigPath | ConvertFrom-Json
    #extract the server name from the group name
    $oServerName = $Request.ServerGroupName.replace($config.AdminPreFix,"")
    #search for the member server object
    $oServer = Get-ADObject -Filter {(SamAccountName = $oServerName) -and (ObjectClass -eq Computer)} -Server $Request.ServerDomain
    #if the server object cannot be found in the AD terminat the script
    if ($null -eq $oServer){
        Write-EventLog -source $config.EventLog -EventID 2100 -EntryType Error -Message "Can't find $oServer in AD" 
        return
    } 
    #Search the computer OU path in the delegation.config file
    $foundOU = $false
    for($ouCounter = 0; $ouCounter = $Delegation.count, $ouCounter++){
        if ($oServer.DistinguishedName -contains $Delegation[$ouCounter].ComputerOU){
            $foundOU = $true
            $oDelegation  = $Delegation[$ouCounter]
            break
        }
    }
    #Terminate the script if the OU is not defined in the delegation.config file
    if (!$foundOU){
        Write-EventLog -source $config.EventLog -EventId 2102 -EntryType Error -Message "The server OU $($oServer.DistinguishedName)is not defined in the Delegation configuration"
    }
    #Validate the user group membership
    $userSID = Get-MemberofSID -DistinguishedName $user.DistinguishedName
    $foundSid = $false
    Foreach ($oSID in $userSID){
        if ($oDelegation.SID -contains $oSID){
            $foundSid = $true
            break
        }
    }
    #if none of the SID defined for this OU terminate the script
    if (!$foundSid){
        Write-EventLog -Source $config.EventSource -EventId 2103 -EntryType Warning -Message "The user $($User.DistinguishedName) doesn't match to the server OU $($oServer.DistinguishedName)"
        Return
    }
}
#region Add user to the local group"
#if the timetolive in the request is higher then the maximum value. replace the ttl with the max evaluation time
if ($Request.ElevationTime -gt $config.MaxElevatedTime)
{
    Write-EventLog -Source $config.EventSource -EventId 2003 -EntryType Warning -Message "The requested time ($($Request.ElevationTime)))for user $($User.DistinguishedName) is higher the maximum time to live ($($config.MaxElevatedTime)). The time to live is replaced with ($($config.MaxElevatedTime))"
    $Request.ElevationTime = $config.MaxElevatedTime
}
if ($user.MemberOf -contains $AdminGroup)
{
    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EntryType Information -EventId 2004 -Message "$($user.SamAccountName) is member of $AdminGroup the TTL will be updated"
    Remove-ADGroupMember $AdminGroup -Members $User.DistinguishedName -Confirm:$false
}
Add-ADGroupMember -Identity $AdminGroup -Members $User -MemberTimeToLive (New-TimeSpan -Minutes $Request.ElevationTime)
Write-EventLog -Source $config.EventSource -LogName $config.EventLog -EventId 101 -EntryType Information -Message "User $($User.DistinguishedName) added to group $AdminGroup"
#Endregion