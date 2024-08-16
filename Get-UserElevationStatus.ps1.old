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

.SYNOPSIS
    Get the elevation status of a user
.DESCRIPTION
    This script searches if a user is member of a elevationgroup
.PARAMETER User
    The name of the user 
.NOTES
    Version 0.1.20240206
    Initial version
    Version 0.1.20240731
        The script uses the JustIntime environment variable if the configuration parameter is not available
#>

param(
    # Name of the user
    [Parameter(Mandatory=$False, Position=0)]
    [string]
    $User,
    [Parameter(Mandatory=$false, Position=1)]
    [string]
    $configurationFile
)

$_Version = "0.1.20240203"
Write-Debug "Get-UserElevationStatus $_Version"

#Reading and validating configuration file
if ($configurationFile -eq "" )
{
    $configurationFile = $env:JustInTimeConfig
}
if (!(Test-Path $configurationFile))
{
    Write-Host "Missing configuration file $configurationFile" -ForegroundColor Red
    Return
}
$config = Get-Content $configurationFile | ConvertFrom-Json

#If the user name is not a parameter use the current user
if ($User -eq ""){$User = $env:USERNAME}
 

try {
    #Discover the next global catalog
    $GlobalCatalogServer = "$((Get-ADDomainController -Discover -Service GlobalCatalog).HostName):3268"
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
            $Domain = $env:USERDNSDOMAIN
        }
    }
    $oUser = Get-ADUser -Filter "SamAccountName -eq '$User'" -Server $Domain
    if ($null -eq $oUser){
        Write-Host "cannot find user $User in $Domain" -ForegroundColor Yellow
        Return
    }
    $GroupAry = Get-ADGroup -Filter * -SearchBase $config.OU -Properties Members -ShowMemberTimeToLive
    foreach ($Group in $GroupAry){
        $UserisMember = $Group.Members | Where-Object {$_ -like "*$($oUser.DistinguishedName)"}
        If ($null -ne $UserisMember){            
            if ($config.EnableMultiDomainSupport){
                $Domain = [regex]::Match($Group.Name,"$($config.AdminPreFix)([^#]+)").Groups[1].Value
                $Server = [regex]::Match($Group.Name,"$($config.AdminPreFix)[^#]+#(.+)").Groups[1].Value
                $TTLsec = [regex]::Match($UserisMember, "\d+").Value
                if ($TTLsec -eq ""){
                    $TimeValue = "permanent"    
                } else {
                    $TimeValue = [math]::Floor($TTLsec / 60)
                }                
                Write-Host "$($oUser.DistinguishedName ) Is Member elevated on $Domain\$Server for $TimeValue minutes"

            } else {
                $Server = [regex]::Match($Group.Name,"$($config.AdminPreFix)(.+)").Groups[1].Value
                $TTLsec = [regex]::Match($UserisMember, "\d+").Value
                if ($TTLsec -eq ""){
                    $TimeValue = "permanent"    
                } else {
                    $TimeValue = [math]::Floor($TTLsec / 60)
                }                
                Write-Host "Is elevated on $Server for $TimeValue"
            }
        }
    }
}
catch [Microsoft.ActiveDirectory.Management.ADServerDownException]{
    Write-Host "can't conntect to $GlobalCatalogServer"
}

