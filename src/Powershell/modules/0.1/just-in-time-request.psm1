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

Version 0.1.20240825
    initial Version

Version 0.1.20240907
    The server format can be in FQDN, HostName, NetBiosName\HostName or DNSname\HostName
Version 0.1.20241004
    New function Get-UserElevationStatus added. 
        This function validate the user is allowed to request administrator privileges on a server
    New-AdminRequest changed to use the Get-UserelevationStatus
Version 0.1.20241023
    New function to convert a distinguishedname into the correspongind DNS Name
version 0.1.20241219 by Andreas Luy
    Changed group naming from NetBios to full Dns naming scheme
    moved Get-Jitconfig to Just-in-time-configuration.psm1
version 0.1.2025016 by Kili
    Fix a eroor if the DNS name of a server is assigned to more the one computer object

#>

#region global variables
[int]$_configBuildVersion = "20241003"
$GC = Get-ADDomainController -Discover -Service "GlobalCatalog" -ForceDiscover
$GlobalCatalogServer = "$($GC.HostName):3268"

#endregion
function ConvertFrom-DN2Dns {
    param(
        [Parameter(Mandatory= $true, ValueFromPipeline)]
        [string]$DistinguishedName
    )

    $DistinguishedName = [regex]::Match($DistinguishedName,"(dc=[^,]+,)*dc=.+$",[System.Text.RegularExpressions.RegexOptions]::IgnoreCase).Value
    return (Get-ADObject -Filter "nCname -eq '$DistinguishedName'" -Searchbase (Get-ADForest).PartitionsContainer -Properties dnsroot).DnsRoot
}

function Write-ScriptMessage {
    param (
        [Parameter (Mandatory, Position=0)]
        [string] $Message,
        [Parameter (Mandatory=$false, Position=1)]
        [ValidateSet('Information','Warning','Error')]
        [string] $Severity = 'Information',
        [Parameter (Mandatory=$false, Position=2)]
        [bool]$UIused = $false
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
        [Parameter(Mandatory=$true,Position=0)]
        $User
    )
    if ($User -is [string]){
        #determine the user parameter format. The function support the format UPN, Domain\UserName, UserName
        switch ($user){
            ""{
                #searching for the current user object in AD
                $oUser = get-ADuser $env:UserName -Properties ObjectSID,CanonicalName  
                break
            }
            ({$_ -like "*@*"}){
                #searching for the user in the UPN format
                $oUser = get-ADUser -Filter "UserPrincipalName -eq '$User'" -Server $GlobalCatalogServer -Properties ObjectSID,CanonicalName
                break
            }
            ({$_ -like "*\*"}){
                #searching for the user in a specified domain
                #enumerate all domains in the forest and compare the domain netbios name with the parameter domain
                foreach ($DomainDNS in (GEt-ADForest).Domains){
                    $Domain == Get-ADDomain -Server $DomainDNS
                    if ($Domain.NetBIOSName -eq $user.split("\")[0]){
                        $oUser = get-aduser -Filter "SamAccountName -eq $($user.split("\")[1])" -Server $DomainDNS -Properties ObjectSID,CanonicalName
                        break
                    }
                }
                breaK
            }
            Default {
                $oUser = Get-aduser -Filter "SamAccountName -eq '$User'" -Properties ObjectSID,CanonicalName
            }
        }
    } else {
        $oUser = $User
    }
    #To enumerate the recursive memberof SID of the user a 2nd LDAP query is needed. The recursive memberof SID stored in the TokenGroups 
    # attribute
    #extrating the domain component from the user distinguishedname
    if ($null -eq $oUser){
        #can't find user object in the global catalog
        return $null
    } else {   
            #enumerating the Domain DNS name from the user distinguished name
            $userDomainDNSName = $oUser.CanonicalName.split("/")[0]
            #searching the user with the TokenGroups attribute
            $oUser = Get-ADUser -LDAPFilter "(ObjectClass=user)" -SearchBase $ouser.DistinguishedName -SearchScope Base -Server $userDomainDNSName -Properties "TokenGroups"
            return $oUser    
     }
}

#region Exported functions
<#
.DESCRIPTION
    This command validate a user is allowed to get acces to a server. It compares the user SID and the groups the user is member of
    with the managedby attribute and the delegation config
.PARAMETER ServerName
    Is the name of the target computer. This parameter support the format
    - as DNS Hostname
    - as server name of the local domain
    - as NetBiosName in the format <domain>\<servername>
    - as canonical name in the format <DNS domain>/<ou>/<servername>
.PARAMETER UserName
    is the name ob the user. This paramter support the format
    -as User principal name
    -as user name of the local domain
    -as netbios name in the format <domain>\<servername>
    -as canonical name in the format <DNS>/<OU>/<serverName>
.PARAMETER Delegationconfig
    The full qualified path to the delegation.config JSON file
.PARAMETER AllowManagedbyAttribute
    if this parameter is $true, the computer attribute "ManagedBy" will be used to validate a server
.OUTPUTS
    Return $true if the user is allowed to be elevated on the given computer
.EXAMPLE
    Get-UserElevationStatus -ServerName "Server0" -UserName "AA" -DelegationConfig "\\contoso.com\SYSVOL\contoso.com\Just-In-Time\Delegation.config"
.EXAMPLE
    Get-UserElevationStatus -ServerName "Server0.contoso.com" -UserName "AA@contoso.com" -DelegationConfig "\\contoso.com\SYSVOL\contoso.com\Just-In-Time\Delegation.config"
.EXAMPLE
    Get-UserElevationStatus -ServerName "Server0" -UserName "AA" 

#>
function Get-UserElevationStatus{
    param(
        [Parameter (mandatory=$true, Position=0)]
        [string]$ServerName,
        [Parameter (Mandatory=$true, Position=1)]
        [string]$UserName,
        [Parameter (Mandatory=$false, Position=2)]
        [string]$DelegationConfig,
        [Parameter (Mandatory=$false)]
        [bool]$AllowManagebyAttribute = $true
    )
    #Import the delegation.config file
    try {
        #region user
        $user = $null
        switch -Wildcard ($UserName) {
            #the parameter UserName is formated as user principal name
            "*@*" {  
                $user = Get-ADUser -Filter "UserPrincipalName -eq '$UserName'" -Server $GlobalCatalogServer -Properties CanonicalName
                $userdomain = [regex]::Match($User.CanonicalName,"[^/]+").Value
                $user = Get-ADUser -LDAPFilter '(ObjectClass=User)' -SearchBase $user.DistinguishedName -SearchScope Base -Server $userdomain -Properties "TokenGroups"
                break
            }
            #the parameter UserName is formated as 
            "*/*"{
                $uhelper = [regex]::Match($userName,"^([^/]+).*?/([^/]+)$")
                $user = Get-ADUser -Identity $uhelper.Groups[2].Value -Server $uhelper.Groups[1].Value
                $user = Get-ADUser -LDAPFilter '(ObjectClass=User)' -SearchBase $user.DistinguishedName -SearchScope Base -Server $uhelper.Groups[1].Value -Properties "TokenGroups"
                break
            }
            #the parameter UserName is formated as netbios domain name with username
            "*\*" {
                $uhelper = [regex]::Match($UserName,"([^\\]+)\\(.+)")
                #getting the netbios name from each domain in the forest
                Foreach ($domainRoot in (Get-ADForest).Domains){
                    $ADDomain = Get-ADDomain -server $domainRoot
                    if ($ADDomain.NetbiosName -eq $uhelper.Groups[1].Value){                    
                        $user = Get-ADuser -Identity $uhelper.Groups[2].Value -Server $domainRoot
                        $user = Get-ADUser -LDAPFilter '(ObjectClass=User)' -SearchBase $user.DistinguishedName -SearchScope Base -Server $uhelper.Groups[1].Value -Properties "TokenGroups"
                        break
                    }
                }
                break
            }
            #the parameter UserName is formated as local domain user
            Default {
                $user = Get-ADUser -Identity $UserName      
                $user = Get-ADUser -LDAPFilter '(ObjectClass=User)' -SearchBase $user.DistinguishedName -SearchScope Base -Properties "TokenGroups"
                break
            }   
        }
        #endregion
        #region searching computer
        switch -Wildcard ($ServerName) {
            "*.*" {
                $Computer = Get-ADComputer -Filter "DNSHostName -eq '$ServerName'" -Server $GlobalCatalogServer
                #The global catalog does not contains the ManagedBy attribute
                if ($Computer.GetType().Name -ne "ADcomputer"){
                    Write-Host "The computer $serverName is not available in AD. Please validate the DNS name of the computer object (Get-UserElevationState)" -ForegroundColor Red  
                    return $false
                }
                $domainDNS = ConvertFrom-DN2Dns $Computer.DistinguishedName
                $Computer = Get-ADComputer $Computer -Properties ManagedBy -Server $domainDNS
                break
            }
            "*.*/*"{
                $uhelper = [regex]::Match($userName,"^([^/]+).*?/([^/]+)$")
                $Computer = Get-ADcomputer -Filter "CN -eq '$($uhelper.Groups[2].Value)" -Properties ManagedBy -Server $uhelper.Groups[1].Value
                if ($Computer.GetType().Name -ne "ADcomputer"){
                    Write-Host "The computer $serverName is not available in AD. Please validate the canonical name ist correct (Get-UserElevationState)" -ForegroundColor Red
                    return $false
                }
                break
            }
            "*\*"{
                $uhelper = [regex]::Match($ServerName,"([^\\]+)\\(.+)")
                $DnsDomainName = (Get-ADObject -Filter "netbiosname -eq '$($uhelper.Groups[1].Value))'" -SearchBase (Get-ADForest).PartitionsContainer -Properties dnsroot).dnsroot
                if ($DnsDomainName -eq ""){
                    Write-Host "The computer $DnsDomainName is not available in AD. Please validate the computer is availabe (Get-UserElevationState)" -ForegroundColor Red
                    return $false
                }
                $Computer = Get-ADComputer -Filter "CN -eq '$($uhelper.Groups[2].Value)'" -Server $uhelper.Groups[1].Value -server $DnsDomainName
                if ($Computer.GetType().Name -ne "ADcomputer"){
                    Write-Host "The comuter $serverName is not available in AD. Please validate the computer is availabe (Get-UserElevationState)" -ForegroundColor Red
                    return $false
                }    
                break
            }
            Default{
                $Computer = Get-ADcomputer -Filter "CN -eq '$ServerName'" -Properties Managedby
                if ($Computer.GetType().Name -ne "ADcomputer"){
                    Write-Host "The computer $serverName is not available in AD. Please validate the computer is availble (Get-UserElevationState)" -ForegroundColor Red
                    return $false
                }
                break
            }
        }
        #endregion
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        if ($null -eq $user){
            Write-Host "Cannot find user $userName " -ForegroundColor Red
        } else {
            Write-Host "Cannot find computer $serverName" -ForegroundColor Red
        }
        return $false
    }
    #check the ManagedBy attribute is available 1st if not use delegation.config
    if ($null -ne $Computer.ManagedBy -and $AllowManagebyAttribute){
        $oManagedBy = Get-ADObject -Filter "DistinguishedName -eq '$($Computer.ManagedBy)'" -Server $GlobalCatalogServer -Properties ObjectSID, CanonicalName
        Switch ($oManagedBy.ObjectClass){
            "User"{
                if ($user.SID -eq $oManagedBy.ObjectSID.Value){
                    return $true
                }
            }
            "Group"{
                $groupDomain = [regex]::Match($Group.CanonicalName,"[^/]+").Value
                $oManagedByMembers = Get-ADGroupMember -Identity $group.DistinguishedName -Recursive -Server $groupDomain
                foreach ($member in $oManagedByMembers){
                    if ($member -eq $user.ObjectSID.Value){
                        return $true
                    }
                }

            }
        }
    }
    # no match with ManagedBy attribute, using delegation.config
    if ($config.EnableDelegation){
        $oDelegation = Get-Content $DelegationConfig | ConvertFrom-Json 
        $ServerDelegations = $oDelegation | Where-Object {$Computer.DistinguishedName -like "*$($_.ComputerOU)"} 
         foreach ($OU in $ServerDelegations){
            if ($OU.ADObject -contains $user.SID){
                return $true
            }
            foreach ($usergroupSID in $user.TokenGroups){
                if ($OU.ADObject -contains $usergroupSID){
                    return $true
                }
            }
        }
    }
    return $false
}
#endregion

<#
New-AdminRequest
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
    New-AdminAccess myhost.contoso.com
        Create a administrator request for the current user for server myhost.compunter.com
    New-AdminAccess myhost
        Create a administrator request for the current user for the server myhost. My host must exists
        in the forest necessarily in the current domain
    New-AdminAccess myhost.contoso.com 30
        Request administrator privileges for myhost.contoso.com for 30 minutes
    New-AdminAccess -Server myhost.contoso.com -Minutes 30 -user myuser@contoso.com
        Request administrator privileges for myhost.contoso.com for 30 minutes for user myuser@contoso.com
#>
function New-AdminRequest{
    param(
        # The name of the server requesting administrator privileges
        [Parameter(Mandatory = $true, Position=0 )]
        [string]$Server,
        # The amount of minutes to request administrator privileges
        #In Multi Forest environments you can provide the domain name instead of the FQDN
        [Parameter(Mandatory = $false)]
        [string]$ServerDomain,
        [Parameter(Mandatory = $false, Position=1)]
        [int]$Minutes = 0,
        #If the request is for a different user
        [Parameter(Mandatory = $false)]
        [string]$User,
        [Parameter (Mandatory = $false)]
        [bool]$UIused = $false
    )

    #reading the current configuration
    $config = Get-JITconfig

    #The following part is only required if UI is NOT used
    if (!$UIused) {

        #region validation of minutes
        #if the value must be between 15 and the maximum configured value. If the value is lower then 15
        #then the minutes variable will be set to 15
        #if the parameter is 0 the parameter will be changed to the configured default value 
        switch ($Minutes) {
            0 {
                $Minutes = $config.DefaultElevatedTime
                break
              }
            ({$_ -lt 15}){
                $Minutes = 15
                break
            }
            ({$_ -gt $config.MaxElevatedTime}){
                $Minutes = $config.MaxElevatedTime
                break
            }
        }
        #endregion
    }

    #region user evaluation
    if (!$User) { # no user provided
        # get current logged on user
        $User = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.split("\")[1]
    }

    #terminate the function if the user object is not available in the AD forest
    $oUser = Get-User $User
    if ((Get-AdminStatus $oUser).count -gt $config.MaxConcurrentServer){
        Write-ScriptMessage "Elevation limit reached. retry in a couple of minutes" -UIused $UIused
    }
    if ($Null -eq $oUser){
        Write-ScriptMessage "Can find the user object." -Severity Warning -UIused $UIused
        return
    }
    #endregion

    #if the server variable contains a . the hostname is FQDN. The function searches for the computer
    #object with this DNSHostName attribute. This function does not query the DNS it self. It is mandatory
    #the primary DNS name is registered.
    #if the server parameter is not as FQDN the function searches for the computername in the AD forest
    #If multiple computers with the same name exists if the forest the function return a $null object
    switch ($Server) {
        {$_ -like "*\*"}{
            #Hostname format is NetBIOS
            $oNetBiosServerName = $server.Split("\")
            if ($oNetBiosServerName[0] -like "*.*"){
                $oserver = Get-ADComputer -Filter "Name -eq '$($oNetBiosServerName[1])'" -Server $oNetBiosServerName[0] -Properties CanonicalName, ManagedBy
            } else {
                Foreach ($ForestDomainDNSName in (Get-ADForest).Domains){
                    if ((Get-ADDomain -Server $ForestDomainDNSName).NetBiosName -eq $oNetBiosServerName[0]){
                        $oServer = Get-ADcomputer  -Filter "Name -eq '$($oNetBiosServerName[1])'"  -Server $ForestDomainDNSName -Properties CanonicalName, ManagedBy    
                        break
                    }
                }
            }
            break
        }
        {$_ -like "*.*"}{
            #Hostname format is DNS ServerName
            $oServer = Get-ADcomputer -Filter "DNSHostName -eq '$Server'" -Server $GlobalCatalogServer -Properties CanonicalName, ManagedBy
            break
        }
        Default {
            if ($ServerDomain -eq ""){
                $oServer = Get-ADComputer -Filter "Name -eq '$Server'" -Server $GlobalCatalogServer -Properties CanonicalName, ManagedBy
            } else {
                $oServer = Get-ADcomputer -Filter "Name -eq '$Server'" -Server $ServerDomain -Properties CanonicalName, ManagedBy
            }
        }
    }
    #validate the server object exists. If the serverobject doesn't exists terminate the function
    if ($null -eq $oServer){
        Write-ScriptMessage -Message "Can't find a server $server in the forest" -Severity Warning -UIused $UIused
        return
    }
    #if multiple server object with the same name exists in the forest, terminate the function
    if ($oServer.GetType().Name -eq "Object[]"){
        Write-ScriptMessage -Message "Multiple computer found with this name $server in the current forest, Please use the DNS hostname instead " -Severity Warning -UIused $UIused 
        return
    }
    # the group name in multidomain mode is
    #   <AdminPreFix><Dns Domain Name><Seperator><server short name>
    # in single mode
    #   <AdminPreFix><Server name>
    if ($config.EnableMultiDomainSupport){
        #$ServerDomainDN = [regex]::Match($oserver.DistinguishedName,"DC=.*").value
        #$ServerDomainDNSName = (Get-ADForest).domains | Where-Object {(Get-ADDomain -Server $_ -ErrorAction SilentlyContinue).DistinguishedName -eq $ServerDomainDN}
        $ServerDomainDNSName = $oServer.CanonicalName.split("/")[0]
        #$ServerDomainNetBiosName = (GEt-ADdomain -Server $ServerDomainDNSName).NetBIOSName
        #$ServerGroupName = "$($config.AdminPreFix)$serverDomainNetBiosName$($config.DomainSeparator)$($oServer.Name)"
        # we will work with dns domain name
        $ServerGroupName = "$($config.AdminPreFix)$ServerDomainDNSName$($config.DomainSeparator)$($oServer.Name)"
    } else {
        $ServerGroupName = "$($config.AdminPreFix)$($oServer.Name)"
    }
    #endregion

    if (!$oServer.DNSHostName){
        Write-ScriptMessage -Message "Missing DNS Hostname entry on the computer object. Aborting elevation" -Severity Warning -UIused $UIused
        return
    }
    #if delegation mode is activated, the function validates if the user is allowed to request access to this server
    if ($config.EnableDelegation) {
        if (!(Get-UserElevationStatus -ServerName $oServer.DNSHostName -UserName $oUser.UserPrincipalName -DelegationConfig $config.DelegationConfigPath)){
            Write-ScriptMessage -Message "User is not allowed to request administrator privileges" -Severity Warning -UIused $UIused
            return
        }
    }
    #Prepare the eventlog entry and write the JIT request to the Jit eventlog
    $ElevateUser = New-Object PSObject
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "UserDN" -Value $oUser.DistinguishedName
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerGroup" -Value $ServerGroupName
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerDomain" -Value $ServerDomainDNSName
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "ElevationTime" -Value $Minutes
    #$ElevateUser | Add-Member -MemberType NoteProperty -Name "CallingUser" -Value "$($env:USERNAME)@$($env:USERDNSDOMAIN)"
    $ElevateUser | Add-Member -MemberType NoteProperty -Name "CallingUser" -Value (([ADSI]"LDAP://<SID=$([System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value)>").UserPrincipalName).ToString()
    $EventMessage = ConvertTo-Json $ElevateUser
    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId $config.ElevateEventID -Message $EventMessage
    Write-ScriptMessage -Message "The $($oUser.DistinguishedName) will be elevated soon" -Severity Information -UIused $UIused
}

<#
This function shows the current request status for a user. 
.PARAMETER User
    Is the name of the user
.PARAMETER UIused
    Is a internal parameter for show messages in the UI mode
.INPUTS
    user object 
.OUTPUTS
    a list of server group name where the user is member of
#>
function Get-AdminStatus{
    param(
    # Name of the user
    [Parameter(Mandatory=$false, Position=0, ValueFromPipeline = $true)]
    $User,
    [Parameter(Mandatory=$False)]
    [bool]$UIused = $False
    )
    if ($null -eq $User){
        $user = $env:USERNAME
    }
    $config = Get-JITconfig
    if ($user -is [string]){
        $User = Get-User $User
    }
    $retVal = @()
    if ($null -eq $User){
        Write-ScriptMessage -Message "cannot find user " -Severity Warning -UIused $UIused
        Return
    }
    foreach ($Group in (Get-ADGroup -Filter * -SearchBase $config.OU -Properties Members -ShowMemberTimeToLive)){
        $UserisMember = $Group.Members | Where-Object {$_ -like "*$($User.DistinguishedName)"}
        If ($null -ne $UserisMember){            
            if ($config.EnableMultiDomainSupport){
                $Domain = (($Group.Name).Substring(($config.AdminPreFix).Length)).Split($config.DomainSeparator)[0]
                $Server = (($Group.Name).Substring(($config.AdminPreFix).Length)).Split($config.DomainSeparator)[1]
                #$Domain = [regex]::Match($Group.Name,"$($config.AdminPreFix)([^#]+)").Groups[1].Value
                #$Server = [regex]::Match($Group.Name,"$($config.AdminPreFix)[^#]+#(.+)").Groups[1].Value
                $TTLsec = [regex]::Match($UserisMember, "\d+").Value
            } else {
                $Server = (($Group.Name).Substring(($config.AdminPreFix).Length))
                #$Server = [regex]::Match($Group.Name,"$($config.AdminPreFix)(.+)").Groups[1].Value
                $TTLsec = [regex]::Match($UserisMember, "\d+").Value
            }
            if ($TTLsec -eq ""){
                $TimeValue = "permanent"    
            } else {
                $TimeValue = [math]::Floor($TTLsec / 60)
            }   
            $obj = new-Object PSObject
            $obj | Add-Member -MemberType NoteProperty -Name "Server" -Value "$domain\$server"
            $obj | Add-Member -MemberType NoteProperty -Name "TTL"    -Value "$TimeValue"
            $retVal += $obj
        }
    }
    if ($UIused){
        $retVal |ForEach-Object{Write-scriptMessage -Message "$User is elevated on $($_.Server) for $($_.TTL) minutes"}
    } else {
        return $retVal
    }
}
