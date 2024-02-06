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
    Local Administrator elevation request  

.DESCRIPTION
    This script creates a Eventlog entry with the elevation request. 

.EXAMPLE
    .\requestAdminAccess.ps1
.PARAMETER User
    Active Directory User Identity
.PARAMETER Domain
    User Domain DNS name
.PARAMETER Servername
    server host name to elevate user
.PARAMETER ServerDomain
    NetBIOS Name of the Domain
.PARAMETER ElevatedMinutes
    User elevation time
.PARAMETER configurationFile
    JIT configuration file
.PARAMETER UIused
    set this parameter to true if the GUI script is used
.INPUTS

.OUTPUTS
   By default, it generates only an HTML report. If the -XmlExport is set to $true, it will generate an XML output.
.NOTES
    Version Tracking
    2021-10-12 
    Version 0.1
        - First internal release
    Version 0.1.20231109
        the config file Version checking validates the build version. Newer config.jit version will be accepted
        Code documentation updated
    Version 0.1.20231204
        -On Mulit-Domain mode build the right group while using the Domain separator option
    Version 0.1.20240129
        Parameter type definition
        Username can now added a Name, UserPrincipalName or SamAccountName
        If the parameter serverName is empty interactive mode to add the server name
    Version 0.1.20240202
        Error handling added
    Version 0.1.20240206
        Users from child domain can enmumerate SID of allowed groups if the group is universal
#>
param (
[Parameter(Mandatory=$false)]
#Is the SAMaccount name of the user who need to be elevated
[string]$User,
[Parameter(Mandatory=$false)]
#Is the user domain
[string]$Domain,
[Parameter(Mandatory=$false)]
#The requested server name
[string]$Servername,
[Parameter(Mandatory=$false)]
#The domain DNS name where the server is installed
[string]$ServerDomain,
[Parameter(Mandatory=$false)]
#is the amount of minutes for the elevation 
[INT]$ElevatedMinutes,
[Parameter(Mandatory=$false)]
#File path to the JIT.config configuration file
[string]$configurationFile,
[Parameter(Mandatory=$false)]
#this parameter is used if the script is called by the UI version
[Switch]$UIused
)

function Write-ScriptMessage {
    param (
        [Parameter (Mandatory, Position=0)]
        [string] $Message,
        [Parameter (Mandatory=$false, Position=1)]
        [ValidateSet('Information','Warning','Error')]
        [string] $Severity = 'Information'
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

#constantes
Write-Debug "Script version 0.1.20240201"

[int]$_configBuildVersion = "20231108"
#Reading and validating configuration file
if ($configurationFile -eq "" )
{
    $configurationFile = (Get-Location).Path + '\JIT.config'
}
if (!(Test-Path $configurationFile))
{
    Write-ScriptMessage "Missing configuration file $configurationFile" -severity Warning
    Return
}
$config = Get-Content $configurationFile | ConvertFrom-Json
#extracting and converting the build version of the script and the configuration file
$configFileBuildVersion = [int]([regex]::Matches($config.ConfigScriptVersion,"[^\.]*$")).Groups[0].Value 
#Validate the build version of the jit.config file is equal or higher then the tested jit.config file version
if ($_configBuildVersion -ge $configFileBuildVersion)
{
    Write-ScriptMessage "Invalid configuration file version. Script aborted" -Severity Error
    return
}
$GlobalCatalogServer = "$((Get-ADDomainController -Discover -Service GlobalCatalog).HostName):3268"
#if the user parameter is not set used the current user
try {
switch -Wildcard ($User) {
    "*\*" {  
        $strSplitUserName = $User.Split("\")
        $User = $strSplitUserName[1]
        Foreach($DomainDNS in ((Get-ADForest).Domains)){
            if ((Get-ADDomain -Server $DomainDNS).NetBiosName -eq $strSplitUserName[0]){
                $Domain = $DomainDNS
                break
            }
        }
        if ([string]::IsNullOrEmpty($Domain)){
            Write-ScriptMessage -Severity Warning "Invalid domain name: $($strSplitUserName[0]) "
            return
        }
    }
    "*@*"{
        $oUser = (Get-ADUser -Filter "UserPrincipalName -eq '$user'" -Server $GlobalCatalogServer -Properties CanonicalName)
        if ($null -eq $oUser){
            Write-ScriptMessage -Severity Warning -Message "Can't find user $user"
            return
        }
        $user = $oUser.SamAccountName
        $Domain = $oUser.canonicalName.Split("/")[0]
    }
    Default {
        if ($User -eq ""){$User = $env:USERNAME}
        if ($Domain -eq ""){$Domain = $env:USERDNSDOMAIN}
    }
}
$oUser = Get-ADUser -Filter "SamAccountName -eq '$User'" -Server $Domain
} 
catch [Microsoft.ActiveDirectory.Management.ADServerDownException]{
    Write-ScriptMessage -Severity Error -Message "Cannot conntect to Active Directory"
    return
}
catch {
    Write-ScriptMessage -Severity Error -Message $Error[0]
}
if ($null -eq $oUser) #validate the user name exists in the active directory
{
    Write-ScriptMessage "User not found $user in $domain" -Severity Warning
    Return
} else {
    #If the user object exists, search for all recursive group membership
    $oUserSID = @()
    Foreach ($UserSID in (Get-ADUser -LDAPFilter '(ObjectClass=User)' -SearchBase $oUser.DistinguishedName -SearchScope Base -Server $domain -Properties "TokenGroups").TokenGroups){
        $oUserSID += $UserSID.Value
        $oSID = New-Object System.Security.Principal.SecurityIdentifier($UserSID.Value)
    }
    $oUserSID += $oUser.SID.Value
    Write-Debug "User Token SID $oUserSID"
}
#read and validate the server name where the user will be elevated
if ($Servername -eq "")
{
    do
    {
        $Servername = Read-Host -Prompt "ServerName"
    } while ($Servername -eq "")
}
#Validate the server Name is FQDN
if ($Servername.Contains(".")){
    #The Server name is FQDN. It is required to split the name into Hostname and domain name
    $ServerDomain = [regex]::Match($ServerName,"[^.]+\.(.+)").Groups[1].value
    $ServerName =  [regex]::Match($ServerName,"([^.]+)\.").Groups[1].value
} else {
    #If only the hostname is added the current domain will be used as the domain 
    $ServerDomain = (Get-ADDomain).DNSRoot
}
#read the domain name if the user press return the current domain will be used
if ($config.EnableMultiDomainSupport){
    while ($ServerDomain -eq "") {
        $ServerDomain = Read-Host "Server DNS domain [$((Get-ADDomain).DNSroot)]"
        if ($ServerDomain -eq ""){
            $ServerDomain = (Get-ADDomain).DNSroot
        } else {
          if ((Get-ADForest).Domains -notlike $ServerDomain){
            $ServerDomain = ""
          }  
        }
    }
    try {
        $ServerDomainNetBiosName = (Get-ADDomain -Server $ServerDomain).NetBIOSName
        $ServerGroupName = "$($config.AdminPreFix)$($ServerDomainNetBiosName)$($config.DomainSeparator)$($ServerName)"        
    }
    catch {
        Write-ScriptMessage "Error $($Error[0].Exception.GetType().Name) occured while searching for server $ServerName in $ServerDomain" -Severity Error
        return
    }

} else {
    $ServerGroupName = $config.AdminPreFix + $Servername
}
if (!(Get-ADGroup -Filter {SamAccountName -eq $ServerGroupName} -Server $config.Domain))
{
    Write-ScriptMessage "Can not find group $ServerGroupName" -Severity Warning
    return
}
if ($config.EnableDelegation){
    $Delegation =@()
    $Delegation += Get-Content $config.DelegationConfigPath | ConvertFrom-Json
    $oServer = Get-ADComputer -Filter "Name -like '$ServerName'" -Server $ServerDomain
    if ($null -eq $oServer){
        Write-ScriptMessage "can't find $ServerName in $serverDomain" -Severity Warning
        return
    } else {
        $ServerOU= [regex]::Match($oServer.DistinguishedName,"CN=[^,]+,(.+)").Groups[1].value
        $oDelegationOU = $Delegation | Where-Object {$serverOU -like "*$($_.ComputerOU)"}
        #validate the server OU exists in the delegation.config file
        if ($null -eq $oDelegationOU ){
            Write-ScriptMessage "The Server $serverName is outside of the JIT defined OUs" -Severity Warning
            return
        } else {
            #validate the user SID is a assigned to this OU
            #compare all SID defined in the delegation.config for this ou with the pac of the user
            $bSidFound = $false
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
                Write-ScriptMessage "user is not allowed to request privileged access on this computer $ServerName" -Severity Warning
                return
            }
        }
    }
}

#read the elevated minutes
while (($ElevatedMinutes -lt 10) -or ($ElevatedMinutes -gt $config.MaxElevatedTime)) {
    [INT]$ElevatedMinutes = Read-Host "Elevated time  [$($config.DefaultElevatedTime) minutes]"
    if ($ElevatedMinutes -eq 0){
        $ElevatedMinutes = $config.DefaultElevatedTime
    }
    if (($ElevatedMinutes -lt 10) -or ($ElevatedMinutes -gt $config.MaxElevatedTime)) {
        Write-ScriptMessage "Invalid elevation time. The requested time must be higher 10 minutes and lower then $($config.MaxElevatedTime)" -Severity Warning
    }
}

$ElevateUser = New-Object PSObject
$ElevateUser | Add-Member -MemberType NoteProperty -Name "UserDN" -Value (Get-ADUser -Identity $User -Server $Domain).DistinguishedName
$ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerGroup" -Value $ServerGroupName
$ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerDomain" -Value $ServerDomain
$ElevateUser | Add-Member -MemberType NoteProperty -Name "ElevationTime" -Value $ElevatedMinutes
$EventMessage = ConvertTo-Json $ElevateUser
Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId $config.ElevateEventID -Message $EventMessage
Write-ScriptMessage "Request send. The account will be elevated soon" Information
