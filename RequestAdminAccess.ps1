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

.INPUTS
    -configuraitonfile
        Specify a configuration file. By default the script reads the configuration file from the working directory
    -User
        Active Directory Name
    -Domain
        User Domain name
    -Server name
        server name
    -ServerDomain
        dns name of the server
    -ElevatedMinutes
        Elevation time for the account
    -DebugOutput [$true|$false]
        For test purposes only, print out debug info.

.OUTPUTS
   By default, it generates only an HTML report. If the -XmlExport is set to $true, it will generate an XML output.
.NOTES
    Version Tracking
    2021-10-12 
    Version 0.1
        - First internal release
#>
param (
[Parameter(Mandatory=$false)]
$User,
[Parameter(Mandatory=$false)]
$Domain,
[Parameter(Mandatory=$false)]
$Servername,
[Parameter(Mandatory=$false)]
$ServerDomain,
[Parameter(Mandatory=$false)]
[INT]$ElevatedMinutes,
[Parameter(Mandatory=$false)]
$configurationFile,
[Parameter(Mandatory=$false)]
[Switch]$UIused
)
#constantes
$_scriptVersion = "0.1.2021299"
$_configfileVersion = "0.1.20230612"
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
if ($config.ConfigScriptVersion -ne $_configfileVersion)
{
    if ($UIused) {
        Write-output "Invalid configuration file version. Script aborted"
    } else {
        Write-Output "Invalid configuration file version. Script aborted"
    }
    return
}
#if the user parameter is not set used the current user
if ($null -eq $User){$User = $env:USERNAME}
if ($null -eq $Domain){$Domain = $env:USERDNSDOMAIN}
if (!(Get-ADUser -Identity $User -Server $Domain)) #validate the user name exists in the active directory
{
    Write-Host "User not found $User"
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
    if ($ServerDomain -eq ""){ $ServerDomain = (Get-ADDomain).DNSroot}
}
$ServerGroupName = $config.AdminPreFix + $ServerName
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
if ($ElevatedMinutes -eq 0) 
{
    [INT]$ElevatedMinutes = Read-Host "Elevated time [$($config.DefaultElevatedTime) minutes]"
    if ($ElevatedMinutes -eq 0)
    {
        $ElevatedMinutes = $config.DefaultElevatedTime
    }
}
if (($ElevatedMinutes -lt 10) -or ($ElevatedMinutes -gt $config.MaxElevatedTime))
{
    Write-Host "invalid elevation time"
    Return
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
    Read-Host "Request send. The account will be elevated soon"
}