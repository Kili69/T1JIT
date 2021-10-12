<#

#>

#Parameter Section
Param(
    [Parameter (Mandatory=$false)]
    $configurationFile
)
#Read configuration
if ($configurationFile -eq $null)
{
    $configurationFile = 'C:\Program Files\WindowsPowershell\Scripts\JIT.config'
}
$config = Get-Content $configurationFile | ConvertFrom-Json
#Getting all Servers operatingsystems except domain controllers"
$serverList = Get-ADComputer -LDAPFilter $config.LDAPT0Computers
Foreach ($Server in $serverList)
{
    $GroupName = $config.AdminPreFix + $Server.Name
    if ((Get-ADGroup -LDAPFilter "(SAMAccountName=$GroupName)") -eq $null)
    {
        New-ADGroup -GroupCategory Security -GroupScope DomainLocal -SamAccountName $GroupName -Name $GroupName -Description ("Administrators on " + $Server.Name) -Path $config.OU
        $Error| Out-File c:\log\scriptLog.log -Force -Append
    }
    else
    {
        #remove any not timebombed user
        Foreach ($Member in (Get-ADGroup $GroupName -Property member -ShowMemberTimeToLive).member)
        {
            $Regex = [RegEx]::new("<TTL=\d*>,CN=.")
            $Match = $Regex.Match($Member)
            if (!$Match.Success)
            {
                Get-ADGroup $GroupName | Remove-ADGroupMember -Members (Get-ADObject -Identity $Member) -Confirm:$false
            }
        }
    }
}