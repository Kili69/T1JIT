#Upgrade DFL to Windows Server 2016
Set-ADDomainMode –Identity <DOMAINNAME> –DomainMode Windows2016Forest
#Upgrade FFL to Windows Server 2016
Set-ADForestMode –Identity <DOMAINNAME> –ForestMode Windows2016ForestMode
#Install PIM feature required for timebombed group membership
Enable-ADOptionalFeature ‘Privileged Access Management Feature’ -Scope ForestOrConfigurationSet -Target <FORESTNAME>

#create a GMSA for managing JIT
New-ADServiceAccount -Name "T1LAGroupMgmt" -AccountNotDelegated $true -Description "This GMSA creates and manage groups for Tier 1 Local Administrator access" -DNSHostName T1LAGroupMgmt.<DOMAINNAME> -PrincipalsAllowedToRetrieveManagedPassword (Get-ADComputer $env:COMPUTERNAME)
#Replace $env:COMPUTERNAME with AVD Host or management server if the command is running on a different computer
#Install GSMA on the PAW / AVD / Management server
Install-ADServiceAccount -Identity (Get-ADServiceAccount -Filter {Name -eq "T1LAGroupMgMt"}) 

$act = New-ScheduledTaskAction -Execute "powershell.exe" -Argument '-NoProfile -NonInteractive -ExecutionPolicy Bypass -file "C:\Program Files\WindowsPowerShell\Scripts\Tier1LocalAdminGroup.ps1" -GroupPreFix "Admin_" -OU "OU=Tier 1 - Management Groups,OU=Admin,"'
$trigg = New-ScheduledTaskTrigger -Once -RepetitionInterval (New-TimeSpan -Minutes 5) -At (Get-Date)
$princ = New-ScheduledTaskPrincipal -UserID 'bloedgelaber\T1LAGroupMgmt$' -LogonType Password
Register-ScheduledTask "T1 Admin Group Management" –Action $act –Trigger $trigg  –Principal $princ

