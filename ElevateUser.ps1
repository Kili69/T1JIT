<#
Script Info

Author: Andreas Lucas [MSFT]
Download: https://github.com/Kili69/T1JIT

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

.INPUTS
.PARAMETER eventRecordID
    is the Event record ID 
.PARAMETER ConfigurationFile
    full qualified path to the configuration file
.EXAMPLE
    ElevateUser.ps1 -EventRecordID 1000 -Configurationfile \\contoso.com\SysVol\contoso.com\JIT\config.JIT

.OUTPUTS
   none
.NOTES
    Version Tracking
    Version 0.1.20231031
        Support of delegation mode
    Version 01.20231109
        Delegation mode activation
    Version 0.1.20231204
        Updated documentation
    Version 0.1.20240202
        Error handling
    Version 0.1.20240205
        Code documentation
    Version 0.1.20240206
        Users from child domain can enmumerate SID of allowed groups if the group is universal
        The request ID added to the error message
    Version 0.1.20240722
        Log files will be created in the %programdata%\Just-in-Time folder. 
        Bug fixing if the program is running in singedomain mode
        New Error Event ID 2105 occurs if the Global Catalog is down
    Version 0.1.20240731
        If the paramter configuration file is not provided, the global environment variable JustInTimeConfig will be used
        instead of the local directory
        Improved Monitoring


    Event ID's
    1    Error  Unhandled Error has occured
    
    2000 Error  Configuration file missing
                Validate the configuration file jit.config is available on the current directory or the parameter configurationFile is correct
    2001 Error  The required group in AD is missing
                 The AD group assinged to this server is missing. Validate the server is in the configured OU and the Tier1LocalAdminGroup.ps1 does not report any error
    2002 Warning The user cannot be found in the active directory
                The user in the Event-ID could not be found in the active directory forest 
    2003 Warning The requested time exceed the max elevation time. The value is set to maximum elevation time
                The requested time excced the maximum time configured in the jit.config file. The requested time will be update to the maximum allowed time
    2004 Information The user is already user of this group. 
                The requested user is already elevated to on this group. The time-to-live paramter will be updated
    2005 Error  Invalid configuration file version. 
                The configuration file is available but the build version is older the expected. run the jit-config.ps1
    2006 Warning The request ID is not available
                The event log entry with the requested ID is not available
    2007 Error  Issuficient access rights
                The current user cannot update the AD groups or has no access to the active dirctorx


    2100 Error  The requested server is not available in the Active Directory
                Validate the requested computer object exists in the active directory. Disconnected DNS namespaces are not supported 
    2101 Error  The delegation JSON file is not available
                The delegation.config file configured in the jit.config is not accessible. Validate the user can access the delegation.config file
    2102 Error  The Server OU path is not defined in the Delegation.config file
                The requested server object distinguishedname is not configured in the delegation.config
    2103 Warning No SId mataches to the delegated OU
                The requested user is not member of any configured delegation in the delegation.config
    2104 Information The user is added to the local administrators group
                The requested user is successfully added to the requested AD group
    2105 Error  Global catalog is down 
    2106 Information Script logging path
                This event provides information about the elevate user script and the debug logging path

#>
[CmdletBinding(DefaultParameterSetName = 'DelegationModel')]
param(
    [Parameter (Mandatory, Position = 0)]
    #Record ID to identify the event
    [int]$eventRecordID,
    [Parameter (Mandatory = $false, Position = 2)]
    #The path to the configuration file
    [string]$ConfigurationFile = $env:JustInTimeConfig
    )
<#
.SYNOPSIS
    Write status message to the console and to the log file
.DESCRIPTION
    the script status messages are writte to the log file located in the app folder. the the execution date and detailed error messages
    The log file syntax is [current data and time],[severity],[Message]
    On error message the current stack trace will be written to the log file
.PARAMETER Message
    status message written to the console and to the logfile
.PARAMETER Severity
    is the severity of the status message. Values are Error, Warning, Information and Debug. Except Debug all messages will be written 
    to the console
#>
function Write-Log {
    param (
        # status message
        [Parameter(Mandatory=$true)]
        [string]
        $Message,
        #Severity of the message
        [Parameter (Mandatory = $true)]
        [Validateset('Error', 'Warning', 'Information', 'Debug') ]
        $Severity
    )
    #Format the log message and write it to the log file
    $LogLine = "$(Get-Date -Format o), [$Severity],[$eventRecordID], $Message"
    Add-Content -Path $LogFile -Value $LogLine 
    switch ($Severity) {
        'Error'   { 
            Write-Host $Message -ForegroundColor Red
            Add-Content -Path $LogFile -Value $Error[0].ScriptStackTrace  
        }
        'Warning' { Write-Host $Message -ForegroundColor Yellow}
        'Information' { Write-Host $Message }
    }
}
<#
.SYNOPSIS 
    Writes the script output to the console and the Windows eventlog
.PARAMETER EventID
    Is the JIT event ID
.PARAMETER Severity
    Is the severity level of the message. 
    Error will be displayed with red foreground color and wrnings as yellow
.PARAMETER Message
    Is the event message test
.EXAMPLE
    Write-ScriptMessage 1 Warning "Test"
    Write the Message "test" with a yellow foreground color to the terminal and a Windows event with ID 1 to the Tier 1 Management eventlog 
#>
    function Write-ScriptMessage{
    param(
        [Parameter (Mandatory, Position=0)]
        [int] $EventID,
        [Parameter (Mandatory, Position=1)]
        [ValidateSet ('Information','Warning','Error','Debug')]
        $Severity,
        [Parameter (Mandatory, Position=2)]
        [string] $Message
    )
    $WindowsEventLog = 'Tier 1 Management'
    switch ($Severity) {
        'Warning'{
            Write-Log -Message $Message -Severity Warning
            Write-EventLog -LogName $WindowsEventLog -EventId $EventID -EntryType $Severity -Message $Message -Source 'T1Mgmt'
        }
        'Error'{
            Write-Log -Message $Message -Severity Error
            Write-EventLog -LogName $WindowsEventLog -EventId $EventID -EntryType $Severity -Message $Message -Source 'T1Mgmt'
        }
        'Debug'{
            Write-Log -Message $Message -Severity Debug
        }
        Default{
            Write-Log -Message $Message -Severity Information
            Write-EventLog -LogName $WindowsEventLog -EventId $EventID -EntryType $Severity -Message $Message -Source 'T1Mgmt'
        }
    }
}
##############################################################################################################################
# Main Programm starts here                                                                                                  #
##############################################################################################################################
[int]$_ScriptVersion = "20240731"
[int]$_configBuildVersion = "20231108"
#region Manage log file
[int]$MaxLogFileSize = 1048576 #Maximum size of the log file
if (!(Test-Path -Path "$($env:ProgramData)\Just-In-Time")) {
    New-Item -Path "$($env:ProgramData)\Just-In-Time" -ItemType Directory
}
$LogFile = "$($env:ProgramData)\Just-In-Time\$($MyInvocation.MyCommand).log" #Name and path of the log file
#rename existing log files to *.sav if the currentlog file exceed the size of $MaxLogFileSize
if (Test-Path $LogFile){
    if ((Get-Item $LogFile ).Length -gt $MaxLogFileSize){
        if (Test-Path "$LogFile.sav"){
            Remove-Item "$LogFile.sav"
        }
        Rename-Item -Path $LogFile -NewName "$logFile.sav"
    }
}
#endregion
Write-ScriptMessage -Message "ElevateUser process started (RequestID $eventRecordID). Detailed logging available $LogFile" -EventID 2106 -Severity Information
Write-Log -Message "Script Version $_ScriptVersion. Minimum required config Version $_configBuildVersion" -Severity Information 
Write-Log -Message "Windows Event ID $($eventRecordID)" -Severity Debug
#validate the configuration file is available and accessible
if ($ConfigurationFile -eq "")
{
    #if the parameter $configurationFile is null set the JIT.config path to current directory
    $ConfigurationFile = (Get-Location).Path + '\JIT.config'
}
Write-Log -Message "configuration file: $ConfigurationFile " -Severity Debug
#Validate the JIT.config file is available
if (!(Test-Path $ConfigurationFile))
{
    #Return a error if the JIT.config is not available
    Write-ScriptMessage -EventID 2000 -Severity Error -Message "RequestID $eventRecordID : Configuration file missing $configurationFile Elevation aborted"
    return
} 
Write-Log -Severity Debug -Message "sucessfully read the $ConfigurationFile"
#Read the configuration file from a JSON file
$config = Get-Content $ConfigurationFile | ConvertFrom-Json
$configFileBuildVersion = [int]([regex]::Matches($config.ConfigScriptVersion,"[^\.]*$")).Groups[0].Value 
Write-Log -Severity Debug -Message "$configurationFile has build version $configFileBuildVersion"
#Validate the build version of the jit.config file is equal or higher then the tested jit.config file version
if ($_configBuildVersion -ge $configFileBuildVersion)
{
    Write-ScriptMessage -EventID 2005 -Severity Error -Message "RequestID $eventRecordID : Invalid configuration file version $configFileBuildVersion expected $_configBuildVersion or higher"
    return
}
Write-Log -Severity Debug -Message "The configuration file is valid. The configuration version is $configFileBuildVersion"
try{
    #Discover the next available Global catalog for queries
    $GlobalCatalogServer = "$((Get-ADDomainController -Discover -Service GlobalCatalog).HostName):3268"
    Write-Log -Severity Debug -Message "using global catalog $GlobalCatalogServer"
    #region Search for the event record in the eventlog, read the event and convert the event message from JSON into a PSobject
    $RequestEvent = Get-WinEvent -FilterHashtable @{LogName = $config.EventLog; ID= $config.ElevateEventID} | Where-Object -Property RecordId -eq $eventRecordID
    if ($null -eq $RequestEvent){
        Write-ScriptMessage -EventID 2006 -Severity Warning -Message "A event record with event ID $eventRecordID is not available in Eventlog $($config.EventLog)"
        return
    }
    Write-Log -Severity Debug -Message "Found eventID $eventRecordID"
    $Request = ConvertFrom-Json $RequestEvent.Message
    #endregion
    #check the elevation group is available. If not terminate the script
    $AdminGroup = Get-ADGroup -Filter "Name -eq '$($Request.ServerGroup)'"
    if ($null -eq $AdminGroup )
    {
        Write-ScriptMessage -EventID 2001 -Severity Error -Message "RequestID $eventRecordID :Can not find $ServerGroupName" 
        return
    }
    #region Search for the user in the entire AD Forest
    $oUser = Get-ADUser -Filter "DistinguishedName -eq '$($Request.UserDN)'" -Server $GlobalCatalogServer -Properties canonicalName
    #check the user object is available, If not terminate the script
    if ($null -eq $oUser ) 
    {
        Write-ScriptMessage -EventID 2002 -Severity Warning -Message "Can't find user $($Request.UserDN)"
        return
    }
    $userDomain = [regex]::Match($oUser.canonicalName,"[^/]+").value
    Write-Log -Severity Debug -Message "Found user $userDomain \ $($oUser.SamAccountName)"
    #endregion
    #region This scection check the permission for this user if the elevation version is enabled
    if ($config.EnableDelegation){
        #continue here if the delegation model is enabled 
        #Search and read the delegation.config file. If the file is not available terminate the script
        if (!(Test-path $config.DelegationConfigPath)){
            Write-ScriptMessage -EventID 2101 -Severity Error -Message "Can't find delegation JSON file $($config.DelegationConfigPath)"
        }
        $Delegation = Get-Content $config.DelegationConfigPath | ConvertFrom-Json
        Write-Log -Severity Debug -Message "Delegtion mode is enabled using $($config.DelegationConfigPath) as delegation file"
        #extract the server name from the group name
        if ($config.EnableMultiDomainSupport){
            $oServerName = [regex]::Match($Request.ServerGroup,"$($config.AdminPreFix)(\w+)$($config.DomainSeparator)(.+)").Groups[2].Value
        #extract the netbios name from the group name and convert it into the Domain DNS name
        $oServerDomainNetBiosName = [regex]::Match($Request.ServerGroup,"$($config.AdminPreFix)(\w+)$($config.DomainSeparator)(.+)").Groups[1].Value
        $oServerDNSDomain = (Get-ADObject -Filter "NetBiosName -eq '$oServerDomainNetBiosName'" -SearchBase "$((Get-ADRootDSE).ConfigurationNamingContext)" -Properties DNSRoot).DNSRoot
        $oServer = Get-ADComputer -Identity $oServerName -Server $oServerDNSDomain[0] -ErrorAction SilentlyContinue
        Write-Log -Severity Debug -Message "Multidomain support is enabled ServerName:$oServerName" 
        } else {
            $oServerName = [regex]::Match($Request.ServerGroup,"$($config.AdminPreFix)(.+)").Groups[1].Value
            Write-ScriptMessage -EventID 0 -Message "Multidomain support is disabled ServerName: $oServerName " -Severity Debug
            #$oServerDomainNetBiosName = (Get-ADDomain).NetBiosName
            #$oServerDNSDomain = (Get-ADDomain).DNSRoot
            $oserver = Get-ADComputer -Identity $oServerName -ErrorAction SilentlyContinue
        }    
        Write-Log -Message "oServerName = $oserverName oServerDomainNameBiosName = $oServerDomainNetBiosName oServerDNSDomain = $oServerDNSDomain" -Severity Debug
        #search for the member server object

        #if the server object cannot be found in the AD terminat the script
        if ($null -eq $oServer){
            Write-ScriptMessage -EventID 2100 -Severity Error -Message "RequestID $eventRecordID : Can't find $oServer in AD" 
            return
        } 
        Write-Debug -Message "Found $oServerName in $oServerDNSDomain"
        $ServerOU= [regex]::Match($oServer.DistinguishedName,"CN=[^,]+,(.+)").Groups[1].value
        $oDelegationOU = $Delegation | Where-Object {$ServerOU -like "*$($_.ComputerOU)"}
        if ($null -eq $oDelegationOU ){
            Write-ScriptMessage -EventID 2102 -Severity Warning -Message "We found the $($oServer.DistinguishedName) but the OU $ServerOU for Server is not defined in the $($config.DelegationConfigPath)"
            return
        } else {
            #validate the user SID is a assigned to this OU
            #compare all SID defined in the delegation.config for this ou with the pac of the user
            $bSidFound = $false
            #Query revursive all group memberships of the user
            $oUserSID = @()
            Foreach ($UserSID in (Get-ADUser -LDAPFilter '(ObjectClass=User)' -SearchBase $oUser.DistinguishedName -SearchScope Base -Server $UserDomain -Properties "TokenGroups").TokenGroups){
                $oUserSID += $UserSID.Value
            }
            $oUserSID += $oUser.SID.Value
            Write-Debug "User Token SID $oUserSID"       
            #$oUser contains all SID for the user PAC
            foreach ($DelegationSID in $oDelegationOU.ADObject){
                foreach ($UserSID in $oUserSID){
                    if ($DelegationSID -eq $UserSID){
                        $bSidFound = $true
                        break
                    }
                }
                if ($bSidFound){
                    break
                }
            }
            if (!$bSidFound){
                #Get all recurvise groups of the user
                Write-ScriptMessage -EventID 2103 -Message "User $($oUser.DistinguishedName) is not allowed to request privileged access on $($oServer.DistinguishedName) " -Severity Warning
                return
            }
        }
    #Terminate the script if the OU is not defined in the delegation.config file
    }
    #endregion
    #Region Add user to the local group"
    #if the timetolive in the request is higher then the maximum value. replace the ttl with the max evaluation time
    if ($Request.ElevationTime -gt $config.MaxElevatedTime)
    {
        Write-ScriptMessage -EventID 2003 -Severity Warning -Message "The requested time ($($Request.ElevationTime)))for user $($oUser.DistinguishedName) is higher the maximum time to live ($($config.MaxElevatedTime)). The time to live is replaced with ($($config.MaxElevatedTime))"
        $Request.ElevationTime = $config.MaxElevatedTime
    }
    if ($oUser.MemberOf -contains $AdminGroup)
    {
        Write-ScriptMessage -EventID 2004 -Severity Information -Message  "$($oUser.SamAccountName) is member of $AdminGroup the TTL will be updated"
        Remove-ADGroupMember $AdminGroup -Members $oUser.DistinguishedName -Confirm:$false
    }
    Add-ADGroupMember -Identity $AdminGroup.Name -Members $oUser -MemberTimeToLive (New-TimeSpan -Minutes $Request.ElevationTime)
    Write-ScriptMessage -EventID 2104 -Severity Information -Message "RequestID $eventRecordID User $($oUser.DistinguishedName) added to group $AdminGroup"
    #Endregion
}
catch [Microsoft.ActiveDirectory.Management.ADServerDownException]{
    Write-ScriptMessage -Severity Error -EventID 2105 -Message "RequestID $eventRecordID : A Server down exception occured. Validate the $GlobalCatalogServer is available" 
    return
}
catch [Microsoft.ActiveDirectory.Management.ADException]{
    Write-ScriptMessage -Severity Error -EventID 2007 -Message "RequestID $eventRecordID : A AD exception has occured. $($Error[0])"
}
catch{
    Write-ScriptMessage -Severity Error -EventID 1    -Message "RequestID $eventRecordID : a unexpected Error has occured $($Error[0].Exception) in line $($Error[0].InvocationInfo.ScriptLineNumber) "  
    return
}
