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
    This script create and maintain the local administrator groups

.DESCRIPTION
    this script run in the context of a GroupManagedServiceAccount and create a domain local group for each 
    server in the Tier1 Management OU

.EXAMPLE
    .\Tier1LocalAdminGroup.ps1
    run the script with the configuration file in the current directory
    .\Tier1LocalAdminGroup.ps1 -configurationFile "C:\program files\WindowsPowershell\scripts\jit.config"
    run the script with a dedicated configuration fil

.INPUTS
    -configurationFile
        use a dedicated configuration file. use this parameter if the configuration file is not in the working directory

.OUTPUTS
   none
.NOTES
    Version Tracking
    2021-10-12 
    Version 0.1
        - First internal release
    Version 0.1.2021294
        - Default installation directory changed from c:\Program Files\windowsPowershell\script to %working directory%
        - Added Event logging
#>
<#
Event ID
1000 Information LocalAdmin Group created
1001 Error Group not created
1002 Information permanent user removed
1003 Error removing permanent user
1100 Error configuration file missing
#>
#Parameter Section
Param(
    [Parameter (Mandatory=$false)]
    $configurationFile
)
$_scriptVersion = "0.1.2021294"

#Read configuration
if ($null -eq $configurationFile)
{
    $configurationFile = (Get-Location).Path + '\jit.config'
}
if (Test-Path $configurationFile)
{
    $config = Get-Content $configurationFile | ConvertFrom-Json
}
else
{
    Write-Error -Message "configuration file $configurationFile missing"
    return
}
#Getting all Servers operatingsystems except domain controllers"
$serverList = Get-ADComputer -LDAPFilter $config.LDAPT0Computers
Foreach ($Server in $serverList)
{
    $GroupName = $config.AdminPreFix + $Server.Name
    if ($null -eq (Get-ADGroup -LDAPFilter "(SAMAccountName=$GroupName)" -Server $config.Domain))
    {
        try {
            New-ADGroup -GroupCategory Security -GroupScope DomainLocal -SamAccountName $GroupName -Name $GroupName -Description ("Administrators on " + $Server.Name) -Path $config.OU -Server $config.Domain
            Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1000 -Message "New Local admin group $GroupName created" -EntryType Information
            }
        catch{
            Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1001 -Message "Error creating Local Admin group $groupname : $Error"  -EntryType Error
        }
    }
    else
    {
        #remove any not timebombed user
        Foreach ($Member in (Get-ADGroup $GroupName -Property member -ShowMemberTimeToLive -Server $config.Domain).member)
        {
            $Regex = [RegEx]::new("<TTL=\d*>,CN=.")
            $Match = $Regex.Match($Member)
            if (!$Match.Success)
            {
                try {
                    Get-ADGroup $GroupName -Server $config.Domain | Remove-ADGroupMember -Members (Get-ADObject -Identity $Member -Server $config.Domain) -Confirm:$false
                    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1002 -Message "Removing permanent user $Member from group $GroupName" -EntryType Warning
                }
                catch
                {
                    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1003 -Message "Can not remove permanent user from $GroupName $Error" -EntryType Error
                }
            }
        }
    }
}
