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
Event ID's
2000 Error Configuration file missing
2001
2002
2003
2004 Information The user is already user of this group. TTL will be updated
2005 Inf
#>
param(
    $eventRecordID,
    $eventChannel,
    [Parameter (Mandatory=$false)]
    $ConfigurationFile
    )

if ($null -eq $ConfigurationFile )
{
    $ConfigurationFile = (Get-Location).Path + '\JIT.config'
}

if (!(Test-Path $ConfigurationFile))
{
    Write-EventLog -LogName 'Tier 2000 Management' -Source 'T1Mgmt' -EventId 1 -EntryType Error -Message "Configuration file missing $configurationFile"
    return
}
$config = Get-Content $ConfigurationFile | ConvertFrom-Json
$eventLog = $config.EventLog
$ElevateEventID = $config.ElevateEventID
$RequestEvent = Get-WinEvent  -LogName $eventLog     -FilterXPath "<QueryList><Query Id='$ElevateEventID' Path='$eventLog'><Select Path='$eventLog'>*[System[(EventRecordID='$eventRecordID')]]</Select></Query></QueryList>"
$Request = ConvertFrom-Json $RequestEvent.Message
$ServerGroupName = $Request.ServerGroup
#$ServerDomain = $Request.ServerDomain
$UserDN = $Request.UserDN
$TTL = $Request.ElevationTime
$AdminGroup = Get-ADGroup -Filter {SamAccountName -eq $ServerGroupName} -Server $config.Domain
$User = Get-ADuser -Filter {DistinguishedName -eq $UserDN} -Properties MemberOf -Server $config.Domain
if ($null -eq $AdminGroup )
{
    Write-EventLog -Source $config.EventLog -EventId 2001 -EntryType Error -Message "Can not find $ServerGroupName"
    return
}

if ($null -eq $User ) 
{
    Write-EventLog -Source $config.EventLog -EventId 2002 -EntryType Error -Message "Invalid user in request $config"
    return
}
if ($TTL -gt $config.MaxElevatedTime)
{
    Write-EventLog -Source $config.EventSource -EventId 2003 -EntryType Error -Message "Invalid elevation time in request $config"
    return
}
if ($user.MemberOf -contains $AdminGroup)
{
    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EntryType Information -EventId 2004 -Message "$($user.SamAccountName) is member of $AdminGroup"
    Remove-ADGroupMember $AdminGroup -Members $User.DistinguishedName -Confirm:$false
}
Add-ADGroupMember -Identity $AdminGroup -Members $User -MemberTimeToLive (New-TimeSpan -Minutes $TTL)
Write-EventLog -Source $config.EventSource -LogName $config.EventLog -EventId 101 -EntryType Information -Message "User added to group $config"
