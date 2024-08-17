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

This module file contains the user functions to request the administrator privileges
#>

#region global variables
[int]$_configBuildVersion = "20231108"
$GlobalCatalogServer = "$((Get-ADDomainController -Discover -Service GlobalCatalog).HostName):3268"

#endregion

function Write-ScriptMessage {
    param (
        [Parameter (Mandatory, Position=0)]
        [string] $Message,
        [Parameter (Mandatory=$false, Position=1)]
        [ValidateSet('Information','Warning','Error')]
        [string] $Severity = 'Information',
        [Parameter (Mandatory=$false, Position=2)]
        [switch]$UIused
    )
    If ($UIused){
        Write-Output $Message
    } else {
        switch ($Severity) {
            'Warning' { $ForegroundColor = 'Yellow'}
            'Error'   { $ForegroundColor = 'Red'}
            Default   { $ForegroundColor = 'Gray'}
        }
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
}
<#
.SYNOPSIS
    Import the configuration from JIT.config file
.DESCRIPTION
    Reading the JIT.config from the System variable or a expicite JIT configuration file. 
    The function return the configuration as JIT config object
    This is a module private function
.PARAMETER configurationFile
    this is a optional parameter to use a dedicated configuration file.
    If this parameter is not available the function read the configuration files
    from the in the $env:JustInTimeConfig varaible or from the current directory
.INPUTS
    The path to the configuration file as string
.OUTPUTS
    JIT config object as PSObject 
.EXAMPLE
    Get-JITConfig
    Tries to read the JIT configuration from the path in the SYSTEM variable JustInTimeConfig. 
    If the environement is not available or the file doesn't exist, the function tries to read 
    the configuration file from the current directory
    Get-JITConfig .\jit.config
        Read the configuration from the path
    Get-JITConfig -ConfigurationFile .\jit.config
        Read the configuration from the path
#>
function Get-JITconfig{
    param(
        [Parameter (Mandatory=$false, Position=0)]
        [string]$configurationFile
    )
    #region parameter validation
    #If the parameter configurationFile is null or empty, change the variable to the value of
    #the system environment JustInTimeConfig 
    if ($null -eq $configurationFile){
        if ($env:JustInTimeConfig -eq ""){
            $configurationFile = ".\jit.config"
        } else {
            if ($null -eq $env:JustInTimeConfig){
                throw "Configuration enviroment variable missing"
                return
            } else {
                $configurationFile = $env:JustInTimeConfig
            }

        }
    }
    #endregion
    if (!(Test-Path $configurationFile))
    {
        throw "Configuration $configurationFile missing"
        Return
    }
    try{
        $config = Get-Content $configurationFile | ConvertFrom-Json
    }
    catch{
        throw "Invalid configuration file $configurationFile"
        return
    }
    #extracting and converting the build version of the script and the configuration file
    $configFileBuildVersion = [int]([regex]::Matches($config.ConfigScriptVersion,"[^\.]*$")).Groups[0].Value 
    #Validate the build version of the jit.config file is equal or higher then the tested jit.config file version
    if ($_configBuildVersion -ge $configFileBuildVersion)
    {
        throw "Invalid configuration file version"
        return
    }
    return $config
}

<#
.SYNOPSIS
    Searching the user object in the entire forest with the user PAC
.DESCRIPTION
    This function searches a user in the entire forest and add the all group membership
    SID as a hashtable to the object
.PARAMETER USER
    If the name of the user. The username can be in the UPN or Domain\Name format. if the
    domain name is not part of the parameter, the user will be searched in the current domain
.INPUTS
    The name of the user
.OUTPUTS
    ActiveDirectoy.ADUser object
.EXAMPLE
    Get-User
        return the current user object
.EXAMPLE 
    Get-User myuser@contoso.com
        searches for the user with the user principal name myuser@contoso.com in the forest
.EXAMPLE
    Get-User contos\myuser
        searches for the user myuser in the contos domain
.EXAMPLE
    Get-User myuser
        searches for the user myuser in the current domain
#>
function Get-User{
    param(
        # Username
        [Parameter(Mandatory=$false,Position=0)]
        [string]
        $User
    )
    #determine the user parameter format. The function support the format UPN, Domain\UserName, UserName
    switch ($user){
        ""{
            #searching for the current user object in AD
            $oUser = get-ADuser $env:UserName -Properties ObjectSID  
        }
        ({$_ -like "*@*"}){
            #searching for the user in the UPN format
            $oUser = get-ADUser -Filter "UserPrincipalName -eq '$User'" -Server $GlobalCatalogServer -Properties ObjectSID
        }
        ({$_ -like "*\*"}){
            #searching for the user in a specified domain
            #enumerate all domains in the forest and compare the domain netbios name with the parameter domain
            foreach ($DomainDNS in (GEt-ADForest).Domains){
                $Domain == Get-ADDomain -Server $DomainDNS
                if ($Domain.NetBIOSName -eq $user.split("\")[0]){
                    $oUser = get-aduser -Filter "SamAccountName -eq $($user.split("\")[1])" -Server $DomainDNS -Properties ObjectSID
                    break
                }
            }
        }
        Default {
            $oUser = Get-aduser -Filter "SamAccountName -eq '$User'"
        }
    }
    #To enumerate the recursive memberof SID of the user a 2nd LDAP query is needed. The recursive memberof SID stored in the TokenGroups 
    # attribute
    #extrating the domain component from the user distinguishedname
    $UserDomainDN = [regex]::Match($oUser.DistinguishedName,"DC=.*").value
    #enumerating the Domain DNS name from the user distinguished name
    $UserDomainDNSName = (Get-ADForest).domains | Where-Object {(Get-ADDomain -Server $_).DistinguishedName -eq $UserDomainDN}
    #searching the user with the TokenGroups attribute
    $oUser = Get-ADUser -LDAPFilter "(ObjectClass=user)" -SearchBase $ouser.DistinguishedName -SearchScope Base -Server $userDomainDNSName -Properties "TokenGroups"
    return $oUser
}

#region Exported functions
<#
New-JITRequestAdminRequest
.SYNOPSIS
    requesting administrator privileges to a server
.DESCRIPTION
    The New-JITRequestAdminAccess creates a new Event to request administrator privileges on a server.
    This function validates the parameters and create the required event log entry
.PARAMETER Server
    Is the name of the server. The server can be in the format hostname or FQDN. This parameter is mandatory
.PARAMETER Minutes
    Is the requested a mount of administrator time in minutes. If the parameter is 0 or empty the configured
    default value time will be used. The parameter cannot exceed the maximum elevation time. If the parameter
    is greater the configured maximum elevation time, the time will be reduced to the maximum elevation time
.PARAMETER User
    This parameter is used if the request is for a different user then the calling user
.PARAMETER UIused
    This is a optional parameter to use the output for the PS GUID. If this parameter is $false (Default value)
    the output will formated
.INPUTS
    The name of the server on postion 0
    the amount of minutes on position 1
.OUTPUTS
    None
.EXAMPLE
    New-JITRequestAdminAccess myhost.contoso.com
        Create a administrator request for the current user for server myhost.compunter.com
    New-JetRequestAdminAccess myhost
        Create a administrator request for the current user for the server myhost. My host must exists
        in the forest necessarily in the current domain
    New-JITRequestAdminAccess myhost.contoso.com 30
        Request administrator privileges for myhost.contoso.com for 30 minutes
    New-JITRequestAdminAccess -Server myhost.contoso.com -Minutes 30 -user myuser@contoso.com
        Request administrator privileges for myhost.contoso.com for 30 minutes for user myuser@contoso.com
#>
function New-JITRequestAdminAccess{
    param(
        # The name of the server requesting administrator privileges
        [Parameter(Mandatory = $true, Position=0 )]
        [string]
        $Server,
        # The amount of minutes to request administrator privileges
        [Parameter(Mandatory = $false, Position=1)]
        [int]
        $Minutes = 0,
        #If the request is for a different user
        [Parameter(Mandatory = $false)]
        [string]
        $User,
        [Parameter (Mandatory = $false)]
        [bool] $UIused = $false
    )
    #reading the current configuration
    $config = Get-JITconfig
    #region validation of minutes
    #if the vlaue must be between 5 and the maximum configured value. If the value is lower then 5
    #then the minutes variable will be set to 5
    #if the parameter is 0 the parameter will be changed to the configured default value 
    switch ($Minutes) {
        0 {
            $Minutes = $config.DefaultElevatedTime
          }
        ({$_ -lt 5}){
            $Minutes = 5
        }
        ({$_ -gt $config.MaxElevatedTime}){
            $Minutes = $config.MaxElevatedTime
        }
    }
    #endregion
    #region user elvalutation
    #terminate the function of the user object is not available in the AD forest
   $oUser = Get-User $User
    if ($Null -eq $oUser){
        Write-ScriptMessage "Can find the user object." -Severity Warning -UIused $UIused
        exit
    }
    #endregion
    #if the server variable contains a . the hostname is FQDN. The function searches for the computer
    #object with this DNSHostName attribute. This function does not query the DNS it self. It is mandatory
    #the primary DNS name is registered.
    #if the server parameter is not as FQDN the function searches for the computername in the AD forest
    #If mulitple computers with the same name exists if the forest the function return a $null object
    if ($server -like "*.*"){
        $oServer = Get-ADcomputer -Filter "DNSHostName -eq '$Server'" -Server $GlobalCatalogServer
    } else {
        $oServer = Get-ADComputer -Filter "Name -eq '$Server'" -Server $GlobalCatalogServer
    }
    #validate the server object exists. If the serverobject doesn't exists terminate the function
    if ($null -eq $oServer){
        Write-ScriptMessage -Message "Can't find a server $server in the forest" -Severity Warning -UIused $UIused
        exit
    }
    #if multiple server object with the same name exists in the forest, terminate the function
    if ($oServer.GetType().Name -eq "Object[]"){
        Write-ScriptMessage -Message "Multiple computer found with this name $Server in the current forest. Please use the DNS hostname in stead" -Severity Warning -UIused $UIused
        exit
    }
    #region build the group name
    #the group name in mulitdomain mode is
    #   <AdminPreFix><Domain NetBIOS Name><Seperator><server short name>
    # in single mode
    #   <AdminPreFix><Server name>
    if ($config.EnableMultiDomainSupport){
        $ServerDomainDN = [regex]::Match($oserver.DistinguishedName,"DC=.*").value
        $ServerDomainDNSName = (Get-ADForest).domains | Where-Object {(Get-ADDomain -Server $_).DistinguishedName -eq $ServerDomainDN}
        $ServerDomainNetBiosName = (GEt-ADdomain -Server $ServerDomainDNSName).NetBIOSName
        $ServerGroupName = "$($config.AdminPreFix)$serverDomainNetBiosName$($config.DomainSeparator)$($oServer.Name)"
    } else {
        $ServerGroupName = "$($config.AdminPreFix)$oServer.Name"
    }
    #endregion
    #if delegation mode is activated, the function validate the user is allowed to request access to this server
    if ($config.DelegationMode){
        #reading the delegation repository defined in the JIT configuration
        $DelegationConfig = Get-Content $config.DelegationConfigPath | ConvertFrom-Json
        $userIsAllowed = $false
        #searching for any DN in the delegation configuration where the server object DN matches
        $DelegationOU = $DelegationConfig | Where-Object {$oServer.distinguishedname -like "*$($_.ComputerOU)"}
        #searching for matching user SIDs in the server object OUs. On the forst match change the variable userIsAllowed
        # to $true and stop the loop
        if ($DelegationOU | Where-Object {$_.ADObject -contains $oUser.ObjectSID}){
            $userIsAllowed = $true
        } else {
            foreach ($SID in $oUser.TokenGroups){
                if ($null -ne ($DelegationOU | Where-Object {$_.ADObject -contains $SID}) ){
                    $userIsAllowed  =$true
                    break
                }
            }
        }
        #If a matching delegation can not be found, write a error message and exit the function
        if (!$userIsAllowed){
            Write-ScriptMessage -Message "User is not allowed to request administrator privileges" -Severity Warning -UIused $UIused
            exit
        }
    }
    #Prepare the eventlog entry and write the JIT request to the Jit eventlog
    $ElevateUser = New-Object PSObject
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "UserDN" -Value $oUser.DistinguishedName
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerGroup" -Value $ServerGroupName
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerDomain" -Value $ServerDomainDNSName
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "ElevationTime" -Value $Minutes
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "CallingUser" -Value "$($env:USERNAME)@$($env:USERDNSDOMAIN)"
    $EventMessage = ConvertTo-Json $ElevateUser
    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId $config.ElevateEventID -Message $EventMessage
    Write-ScriptMessage -Message  "The $user will be elevated soon" -Severity Information -UIused $UIused
}

<#
Show the current request status for a user
#>
function Get-JITRequestStatus{
    param(
    # Name of the user
    [Parameter(Mandatory=$False, Position=0)]
    [string]$User,
    [Parameter(Mandatory=$False)]
    [bool]$UIused = $False
    )
    $config = Get-JITconfig
    $oUser = Get-JITUser $User
    if ($null -eq $oUser){
        Write-ScriptMessage -Message "cannot find user " -Severity Warning -UIused $UIused
        Return
    }
    foreach ($Group in (Get-ADGroup -Filter * -SearchBase $config.OU -Properties Members -ShowMemberTimeToLive)){
        $UserisMember = $Group.Members | Where-Object {$_ -like "*$($oUser.DistinguishedName)"}
        If ($null -ne $UserisMember){            
            if ($config.EnableMultiDomainSupport){
                $Domain = [regex]::Match($Group.Name,"$($config.AdminPreFix)([^#]+)").Groups[1].Value
                $Server = [regex]::Match($Group.Name,"$($config.AdminPreFix)[^#]+#(.+)").Groups[1].Value
                $TTLsec = [regex]::Match($UserisMember, "\d+").Value
            } else {
                $Server = [regex]::Match($Group.Name,"$($config.AdminPreFix)(.+)").Groups[1].Value
                $TTLsec = [regex]::Match($UserisMember, "\d+").Value
            }
            if ($TTLsec -eq ""){
                $TimeValue = "permanent"    
            } else {
                $TimeValue = [math]::Floor($TTLsec / 60)
            }   
            Write-ScriptMessage -Message  "$($oUser.DistinguishedName ) Is Member elevated on $Domain\$Server for $TimeValue minutes" -Severity Information -UIused $UIused
        }
    }
}
#endregion

