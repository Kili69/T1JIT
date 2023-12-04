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
        -On Mulit-Domain mode build the right group while using the Domain separator option in
#>
param (
[Parameter(Mandatory=$false)]
#Is the SAMaccount name of the user who need to be elevated
$User,
[Parameter(Mandatory=$false)]
#Is the user domain
$Domain,
[Parameter(Mandatory=$false)]
#The requested server name
$Servername,
[Parameter(Mandatory=$false)]
#The domain DNS name where the server is installed
$ServerDomain,
[Parameter(Mandatory=$false)]
#is the amount of minutes for the elevation 
[INT]$ElevatedMinutes,
[Parameter(Mandatory=$false)]
#File path to the JIT.config configuration file
$configurationFile,
[Parameter(Mandatory=$false)]
#this parameter is used if the script is called by the UI version
[Switch]$UIused
)
#constantes
#$_scriptVersion = "0.1.20231204"
[int]$_configBuildVersion = "20231108"
#Reading and validating configuration file
if ($null -eq $configurationFile )
{
    $configurationFile = (Get-Location).Path + '\JIT.config'
}
if (!(Test-Path $configurationFile))
{
    Write-Host "Missing configuration file"
    Return
}
$config = Get-Content $configurationFile | ConvertFrom-Json
#extracting and converting the build version of the script and the configuration file
$configFileBuildVersion = [int]([regex]::Matches($config.ConfigScriptVersion,"[^\.]*$")).Groups[0].Value 
#Validate the build version of the jit.config file is equal or higher then the tested jit.config file version
if ($_configBuildVersion -ge $configFileBuildVersion)
{
    if ($UIused) {
        Write-output "Invalid configuration file version. Script aborted"
    } else {
        Write-host "Invalid configuration file version. Script aborted"
    }
    return
}
#if the user parameter is not set used the current user
if ($null -eq $User){$User = $env:USERNAME}
if ($null -eq $Domain){$Domain = $env:USERDNSDOMAIN}
if (!(Get-ADUser -Identity $User -Server $Domain)) #validate the user name exists in the active directory
{
    if($UIused){
        Write-Output "User not found $User"
    } else{
        Write-Host "User not found $User"
    }
    Return
}
#read and validate the server name where the user will be elevated
if ($null -eq $Servername)
{
    do
    {
        $Servername = Read-Host -Prompt "ServerName"
    } while ($Servername -eq "")
}

#read the domain name if the user press return the current domain will be used
if ($null -eq $ServerDomain)
{
    $ServerDomain = Read-Host "Server DNS domain [$((Get-ADDomain).DNSroot)]" 
    if ($ServerDomain -eq ""){ $ServerDomain = (Get-ADDomain).NetBiosName}
}
if ($config.EnableMultiDomainSupport){
    $ServerGroupName = "$($config.AdminPreFix)$($ServerDomain)$($config.DomainSeparator)$($ServerName)"
} else {
    $ServerGroupName = $config.AdminPreFix + $Servername
}
if (!(Get-ADGroup -Filter {SamAccountName -eq $ServerGroupName} -Server $config.Domain))
{
    if ($UIused) {
        Write-output "Can not find group $ServerGroupName"
    } else {
        Write-Host "Can not find group $ServerGroupName"
    }
    return
}
#read the elevated minutes
while (($ElevatedMinutes -lt 10) -or ($ElevatedMinutes -gt $config.MaxElevatedTime)) {
    [INT]$ElevatedMinutes = Read-Host "Elevated time [$($config.DefaultElevatedTime) minutes]"
    if ($ElevatedMinutes -eq 0){
        $ElevatedMinutes = $config.DefaultElevatedTime
    }
    if (($ElevatedMinutes -lt 10) -or ($ElevatedMinutes -gt $config.MaxElevatedTime)) {
        if ($UIused){
            Write-Output "Invalid elevation time"
            Return
        } else {
            Write-Host "Invalid elevation time. The requested time must be higher 10 minutes and lower then $($config.MaxElevatedTime)"
        }
    }

}

$ElevateUser = New-Object PSObject
$ElevateUser | Add-Member -MemberType NoteProperty -Name "UserDN" -Value (Get-ADUser -Identity $User -Server $Domain).DistinguishedName
$ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerGroup" -Value $ServerGroupName
$ElevateUser | Add-Member -MemberType NoteProperty -Name "ServerDomain" -Value $ServerDomain
$ElevateUser | Add-Member -MemberType NoteProperty -Name "ElevationTime" -Value $ElevatedMinutes
$EventMessage = ConvertTo-Json $ElevateUser
Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId $config.ElevateEventID -Message $EventMessage
if ($UIused) {
    Write-output "Request send. The account will be elevated soon"
} else {
    Write-Host "Request send. The account will be elevated soon" -ForegroundColor Green
}