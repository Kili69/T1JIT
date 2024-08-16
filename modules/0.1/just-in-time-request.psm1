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
Import the configuration from JIT.config
#>
function Get-JITconfig{
    [int]$_configBuildVersion = "20231108"
    #Reading and validating configuration file
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
Searching the user object in the entire forest with the user PAC
#>
function Get-User{
    param(
        # Username
        [Parameter(Mandatory=$false,Position=0)]
        [string]
        $User
    )
    $GlobalCatalogServer = "$((Get-ADDomainController -Discover -Service GlobalCatalog).HostName):3268"
    switch ($user){
        ""{
            $oUser = get-ADuser $env:UserName -Properties ObjectSID  
        }
        ({$_ -like "*@*"}){
            $oUser = get-ADUser -Filter "UserPrincipalName -eq '$User'" -Server $GlobalCatalogServer -Properties ObjectSID
        }
        ({$_ -like "*\*"}){
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
    $UserDomainDN = [regex]::Match($oUser.DistinguishedName,"DC=.*").value
    $UserDomainDNSName = (Get-ADForest).domains | Where-Object {(Get-ADDomain -Server $_).DistinguishedName -eq $UserDomainDN}
    $oUser = Get-ADUser -LDAPFilter "(ObjectClass=user)" -SearchBase $ouser.DistinguishedName -SearchScope Base -Server $userDomainDNSName -Properties "TokenGroups"
    return $oUser
}

#region Exported functions
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
    $config = Get-JITconfig
    $GlobalCatalogServer = "$((Get-ADDomainController -Discover -Service GlobalCatalog).HostName):3268"
    #region validation of minutes
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
   $oUser = Get-User $User
    if ($Null -eq $oUser){
        Write-ScriptMessage "Can find the user object." -Severity Warning -UIused $UIused
        exit
    }
    #endregion
    if ($server -like "*.*"){
        $oServer = Get-ADcomputer -Filter "DNSHostName -eq '$Server'" -Server $GlobalCatalogServer
    } else {
        $oServer = Get-ADComputer -Filter "Name -eq '$Server'" -Server $GlobalCatalogServer
    }
    #validate the server object exists
    if ($null -eq $oServer){
        Write-ScriptMessage -Message "Can't find a server $server in the forest" -Severity Warning -UIused $UIused
        exit
    }
    #if multiple server object with the same name exists in the forest, terminate the function
    if ($oServer.GetType().Name -eq "Object[]"){
        Write-ScriptMessage -Message "Multiple computer found with this name $Server in the current forest. Please use the DNS hostname in stead" -Severity Warning -UIused $UIused
        exit
    }
    if ($config.EnableMultiDomainSupport){
        $ServerDomainDN = [regex]::Match($oserver.DistinguishedName,"DC=.*").value
        $ServerDomainDNSName = (Get-ADForest).domains | Where-Object {(Get-ADDomain -Server $_).DistinguishedName -eq $ServerDomainDN}
        $ServerDomainNetBiosName = (GEt-ADdomain -Server $ServerDomainDNSName).NetBIOSName
        $ServerGroupName = "$($config.AdminPreFix)$serverDomainNetBiosName$($config.DomainSeparator)$($oServer.Name)"
    } else {
        $ServerGroupName = "$($config.AdminPreFix)$oServer.Name"
    }

    if ($config.EnableMultiDomainSupport){
        $DelegationConfig = Get-Content $config.DelegationConfigPath | ConvertFrom-Json
        $userIsAllowed = $false
        $DelegationOU = $DelegationConfig | Where-Object {$oServer.distinguishedname -like "*$($_.ComputerOU)"}
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
        if (!$userIsAllowed){
            Write-ScriptMessage -Message "User is not allowed to request administrator privileges" -Severity Warning -UIused $UIused
            exit
        }
    }
 
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

