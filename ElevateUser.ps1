<#

#>
param($eventRecordID,$eventChannel)


#    [Parameter (Mandatory=$false)]
    $ConfigurationFile="C:\Program Files\WindowsPowershell\Scripts\JIT.config"


if (!(Test-Path $ConfigurationFile))
{
    Write-EventLog -LogName 'Tier 1 Management' -Source 'T1Mgmt' -EventId 1 -EntryType Error -Message "Configuratin file missing $configurationFile"
}
$config = Get-Content $ConfigurationFile | ConvertFrom-Json
$eventLog = $config.EventLog
$ElevateEventID = $config.ElevateEventID
$Event = Get-WinEvent  -LogName $eventLog     -FilterXPath "<QueryList><Query Id='$ElevateEventID' Path='$eventLog'><Select Path='$eventLog'>*[System[(EventRecordID='$eventRecordID')]]</Select></Query></QueryList>"
#$event = Get-winevent -LogName $eventChannel -FilterXPath "<QueryList><Query Id='0'               Path='$eventChannel'><Select Path='$eventChannel'>*[System [(EventRecordID=$eventRecordID)]]</Select></Query></QueryList>"
$Request = ConvertFrom-Json $Event.Message
$ServerGroupName = $Request.ServerGroup
$ServerDomain = $Request.ServerDomain
$UserDN = $Request.UserDN
$TTL = $Request.ElevationTime
$AdminGroup = Get-ADGroup -Filter {SamAccountName -eq $ServerGroupName} -Server $ServerDomain
$User = Get-ADuser -Filter {DistinguishedName -eq $UserDN} -Properties MemberOf
if ($AdminGroup -eq $null)
{
    Write-EventLog -Source $config.EventLog -EventId 1000 -EntryType Error -Message "Invalid group in request $config"
    return
}

if ($User -eq $null) 
{
    Write-EventLog -Source $config.EventLog -EventId 1100 -EntryType Error -Message "Invalid user in request $config"
    return
}
if ($TTL -gt $config.MaxElevatedTime)
{
    Write-EventLog -Source $config.EventLog -EventId 1200 -EntryType Error -Message "Invalid elevation time in request $config"
    return
}
if ($user.MemberOf -contains $AdminGroup)
{
    Remove-ADGroupMember $AdminGroup -Members $User.DistinguishedName
}
Add-ADGroupMember -Identity $AdminGroup -Members $User -MemberTimeToLive (New-TimeSpan -Minutes $TTL)
Write-EventLog -Source $config.EventSource -LogName $config.EventLog -EventId 101 -EntryType Information -Message "User added to group $config"