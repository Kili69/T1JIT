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
    This script install and configure the Tier 1 JIT solution 

.DESCRIPTION
    The installation script copies the required scripts to the script directory, create the 
    group managed service account and register the required schedule tasks

.EXAMPLE
    .\config-T1jit.ps1

.INPUTS
    -TargetDirectory
        Install the solution into another directory then the Windows Powershell script directory 
    -CreateGMSA [$true|$false]
        Create a new GMSA and install the GMSA on this computer
    -ServerEnumerationTime
        Rerun time for scheduled task
    -DebugOutput [$true|$false]
        For test purposes only, print out debug info.

.OUTPUTS
   none
.NOTES
    Version Tracking
    2021-10-12 
    Version 0.1
        - First internal release
    Version 0.1.2021294
        - Default installation directory changed from c:\Program Files\windowsPowershell\script to %working directory%
        - New parameter ServerEnumerationTime added. Time for scheduled task to evaluate the existing servers
    Version 0.1.20230612
        - Source code documentation
#>
<#
    script parameters
#>
param (
    #The groupname prefix for local administrators group 
    [Parameter (mandatory=$false)]
    $AdminPreFix,
    #The name of the domain 
    [Parameter (Mandatory=$false)]
    $Domain, 
    #The distinguished name of the organizaztional Unit to store the privileged groups
    [Parameter (mandatory=$false)]
    $OU,
    #the maximum amount of minutes to elevate a user
    [Parameter (Mandatory=$false)]
    $MaxMinutes,
    #Is the name of the Tier 0 computer group. Those computers will be excluded for this PAM solution
    [Parameter (Mandatory=$false)]
    $Tier0ServerGroupName,
    #Is the default time for elevated users
    [Parameter (Mandatory=$false)]
    $DefaultElevatedTime,
    #The installation directory to find the JIT.config file
    [Parameter (Mandatory=$false)]
    $InstallationDirectory,
    [Parameter (Mandatory=$false)]
    #The in minutes to run the computer enumeration script 
    [INT] $GroupManagementTaskRerun,
    #If this paramter is $True the required group management account will be created by this script
    [Parameter (Mandatory=$false)]
    [bool] $InstallGroupManagedServiceAccount = $true,
    #The name of the group managed service account
    [Parameter (Mandatory=$false)]
    $GroupManagedServiceAccountName,
    #Enable the debug option for additional information
    [Parameter (Mandatory=$false)]
    [bool] $DebugOutput = $false,
    #Install the schedule task on the local server, running in the context of the GMSA
    [Parameter (Mandatory=$false)]
    [bool] $CreateScheduledTaskADGroupManagement= $true,
    [Parameter (Mandatory=$false)]
    [INT] $ServerEnumerationTime = 10
)

function New-ADDGuidMap
{
    <#
    .SYNOPSIS
        Creates a guid map for the delegation part
    .DESCRIPTION
        Creates a guid map for the delegation part
    .EXAMPLE
        PS C:\> New-ADDGuidMap
    .OUTPUTS
        Hashtable
    .NOTES
        Author: Constantin Hager
        Date: 06.08.2019
    #>
    $rootdse = Get-ADRootDSE
    $guidmap = @{ }
    $GuidMapParams = @{
        SearchBase = ($rootdse.SchemaNamingContext)
        LDAPFilter = "(schemaidguid=*)"
        Properties = ("lDAPDisplayName", "schemaIDGUID")
    }
    Get-ADObject @GuidMapParams | ForEach-Object { $guidmap[$_.lDAPDisplayName] = [System.GUID]$_.schemaIDGUID }
    return $guidmap
}
<#
    This function add a SID to the "Logon as a Batch Job" privilege
#>
function Add-LogonAsABatchJobPrivilege 
{
    <#
    .SYNOPSIS
        Assign the Logon As A Batch Job privilege to a SID
    .DESCRIPTION
        Assign the Logon As A Batch Job privilege to a SID
    .EXAMPLE
        Add-LogonAsABatchJob -SID "S-1-5-0"
    .OUTPUTS
        none
    .NOTES
        Author: Andreas Lucas
        Date: 2021-10-10
    #>
    param ($Sid)
    #Temporary files for secedit
    $tempPath = [System.IO.Path]::GetTempPath()
    $import = Join-Path -Path $tempPath -ChildPath "import.inf"
    if(Test-Path $import) { Remove-Item -Path $import -Force }
    $export = Join-Path -Path $tempPath -ChildPath "export.inf"
    if(Test-Path $export) { Remove-Item -Path $export -Force }
    $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
    if(Test-Path $secedt) { Remove-Item -Path $secedt -Force }
    #Export the current configuration
    secedit /export /cfg $export
    #search for the current SID assigned to the SeBatchJob privilege
    $SIDs = (Select-String $export -Pattern "SeBatchLogonRight").Line
    if (!($SIDs.Contains($Sid)))
    {
        #create a new temporary security configuration file
        foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsABatchJob security template", "[Privilege Rights]", "$SIDs,*$sid"))
        {
            Add-Content $import $line
        }
        #configure privileges
        secedit /import /db $secedt /cfg $import
        secedit /configure /db $secedt
        gpupdate /force
        Remove-Item -Path $import -Force
        Remove-Item -Path $secedt -Force
    }
    #remove all temporary files   
    Remove-Item -Path $export -Force
    
}

#Constant section
$_scriptVersion = "0.1.20230612"
$configFileName = "JIT.config"
$MaximumElevatedTime = 1440
$DefaultElevatedTime = 60
$DefaultAdminPrefix = "Admin_"
$DefaultLdapQuery = "(&(Operatingsystem=*Windows Server*)(!(PrimaryGroupID=516))(!(memberof=[DNTier0serverGroup])))"
$DefaultOU = "OU=Tier 1 - Management Groups,OU=Admin, $(Get-ADDomain)"
$DefaultServerGroupName = "Tier 0 Computers"
$DefaultGroupManagementServiceAccountName = "T1GroupMgmt"
$EventSource = "T1Mgmt"
$EventLogName = "Tier 1 Management"
$STGroupManagementTaskName = "Tier 1 Local Group Management"
$StGroupManagementTaskPath = "\Just-In-Time-Privilege"

#$STAdminGroupManagement = "Administrator Group Management"
$STAdminGroupManagementRerunMinutes = 5
$STElevateUser = "Elevate User"
$ADDomainDNS = (Get-ADDomain).DNSRoot
#End constant section

#Setting Debugging option
if ($DebugOutput -eq $true) {$DebugPreference = "Continue"} else {$DebugPreference = "SilentlyContinue"}
#Validate the installation directory and stop execution if installation directory doesn't exists
if ($null -eq $InstallationDirectory )
    {$InstallationDirectory = (Get-Location).Path}
if (!(Test-Path $InstallationDirectory))
{
    Write-Output "Installation directory missing"
    return
}
#check for an existing configuration file and read the configuration
if (Test-Path "$InstallationDirectory\$configFileName")
{
    $config = Get-Content "$InstallationDirectory\$configFileName" | ConvertFrom-Json
    if ($config.ConfigScriptVersion -ne $_scriptVersion)
    {
        #There is a config file version conflict
        Write-Output "invalid version of the configuration file. Delete the configuration to create a new configuration"
        Return
    }
}
else
{
    $config = New-Object PSObject
    $config | Add-Member -MemberType NoteProperty -Name "ConfigScriptVersion"            -Value $_scriptVersion
    $config | Add-Member -MemberType NoteProperty -Name "AdminPreFix"                    -Value $DefaultAdminPrefix
    $config | Add-Member -MemberType NoteProperty -Name "OU"                             -Value $DefaultOU
    $config | Add-Member -MemberType NoteProperty -Name "MaxElevatedTime"                -Value $MaximumElevatedTime
    $config | Add-Member -MemberType NoteProperty -Name "DefaultElevatedTime"            -Value $DefaultElevatedTime
    $config | Add-Member -MemberType NoteProperty -Name "ElevateEventID"                 -Value 100
    $config | Add-Member -MemberType NoteProperty -Name "Tier0ServerGroupName"           -Value $DefaultServerGroupName
    $config | Add-Member -MemberType NoteProperty -Name "LDAPT0Computers"                -Value $DefaultLdapQuery
    $config | Add-Member -MemberType NoteProperty -Name "EventSource"                    -Value $EventSource
    $config | Add-Member -MemberType NoteProperty -Name "EventLog"                       -Value $EventLogName
    $config | Add-Member -MemberType NoteProperty -Name "GroupManagementTaskRerun"       -Value $STAdminGroupManagementRerunMinutes
    $config | Add-Member -MemberType NoteProperty -Name "GroupManagedServiceAccountName" -Value $DefaultGroupManagementServiceAccountName
    $config | Add-Member -MemberType NoteProperty -Name "Domain"                         -Value $ADDomainDNS
}

#Definition of the AD group prefix. Use the default value if the question is not answerd
if ($null -eq $AdminPreFix )
{
    $AdminPreFix = Read-Host -Prompt "Admin Prefix for local administrators default[$($config.AdminPreFix)]"
    if ($AdminPreFix -ne "")
        {$config.AdminPreFix = $AdminPreFix}
}
#Validation of the GroupManagedService Account
if ($null -eq $GroupManagedServiceAccountName )
{
   $gmsaName = Read-Host -Prompt "Group Managed account name [$($config.GroupManagedServiceAccountName)]"
   if ($gmsaName -ne "")
    { $config.GroupManagedServiceAccountName = $gmsaName}
}
$gmsaName = $config.GroupManagedServiceAccountName #$config.groupManagedServiceAccountName wird nicht akzeptiert was mach ich falsch?
#if ((Get-ADServiceAccount -Filter {Name -eq "$($config.GroupManagedServiceAccountName)"}) -eq $null)
if ($null -eq (Get-ADServiceAccount -Filter {Name -eq $gmsaName} -Server $($config.Domain)))
{
    if ($InstallGroupManagedServiceAccount)
    {
        Write-Debug "Create GMSA $($config.GroupManagedServiceAccountName) "
        New-ADServiceAccount -Name $config.GroupManagedServiceAccountName -DisplayName $config.GroupManagedServiceAccountName -DNSHostName "$($config.GroupManagedServiceAccountName).$((Get-ADDomain).DomainDNSroot)" -Server $config.Domain
    }
    else
    {
        Write-Output "Missing GMSA $($config.GroupManagedServiceAccountName)"
        #return
    }
}
Write-Debug "allow the current computer to retrive the password"
$principalsAllowToRetrivePassword = (Get-ADServiceAccount -Identity $config.GroupManagedServiceAccountName -Properties PrincipalsAllowedToRetrieveManagedPassword).PrincipalsAllowedToRetrieveManagedPassword
if (($principalsAllowToRetrivePassword.Count -eq 0) -or ($principalsAllowToRetrivePassword.Value -notcontains (Get-ADComputer -Identity $env:COMPUTERNAME).DistinguishedName))
{
    Write-Debug "Adding current computer to the list of computer who an retrive the password"
    $principalsAllowToretrivePassword.Add((Get-ADComputer -Identity $env:COMPUTERNAME))
    Set-ADServiceAccount -Identity $GMSAName -PrincipalsAllowedToRetrieveManagedPassword $principalsAllowToRetrivePassword -Server $config.Domain
}
else
{
    Write-Debug "is already in the list of computer who can retrieve the password"
}
$GMSaccount = Get-ADServiceAccount -Identity $config.GroupManagedServiceAccountName -Server $config.Domain
Install-ADServiceAccount -Identity $GMSaccount
Write-Debug "Test $GMSAName $(Test-ADServiceAccount -Identity $($config.GroupManagedServiceAccountName))"
Add-LogonAsABatchJobPrivilege -Sid ($GmSaccount.SID).Value

#Definition of the AD OU where the AD groups are stored
if ($null -eq $ou)
{
    $OU = Read-Host -Prompt "OU for the local administrator groups Default[$($config.OU)]"
    if ($OU -ne "")
        {$config.OU = $OU}
}
$OU = $config.OU
if ($null -eq (Get-ADOrganizationalUnit -Filter {DistinguishedName -eq $OU} -Server $config.Domain))
{
    Write-Output "The Ou $($config.ou) is not available"
    #return
}
Write-Debug  "OU $($config.OU) is accessible updating ACL"
$aclGroupOU = Get-ACL -Path "AD:\$($config.OU)"
if (!($aclGroupOU.Sddl.Contains($GMSaccount.SID)))
{
    Write-Debug "Adding ACE to OU"
    $GuidMap = New-ADDGuidMap
    $objGMSASID = New-Object System.Security.Principal.SecurityIdentifier $GMSaccount.SID
    $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $objGMSASID, "GenericAll", "Allow", "Descendents", $GuidMap["Group"]
    #$ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $objGMSASID, "GenericAll", "Allow", "All", $GuidMap["Group"]
    $aclGroupOu.AddAccessRule($ace)
    Set-Acl "AD:\$($config.OU)" -AclObject $aclGroupOU
    Write-Output "check ACL!!!!"
}
#Definition of the maximum time for elevated administrators
if ($null -eq $MaxMinutes ) 
{

    [UINT16]$MaxMinutes = Read-Host "Maximum elevated time [$($config.MaxElevatedTime)]"
    if (($MaxMinutes -gt 0) -and ($MaxMinutes -lt 1441))
    {
        $config.MaxElevatedTime = $MaxMinutes
        Write-Debug "Maximum elevated time is $($config.MaxElevatedTime)"
    }
    else
    {
        $config.MaxElevatedTime = 1440
        Write-Debug "Maximum elevated time is set to 24h"
    }
}
else
{
    if ($MaxMinutes -gt $config.MaxElevatedTime)
    {
        Write-Debug "$MaxMinutes exceed the Maximum elevated time"
        $config.DefaultElevatedTime = $config.MaxElevatedTime
    }
    else
    {
        $config.MaxElevatedTime = $MaxMinutes
    }
}
#Definition of the default elevation time
if ($DefaultElevatedTime -eq $null)
{
    [INT]$DefaultElevatedTime = Read-Host -Prompt "Default elevated time [$($config.DefaultElevatedTime)]"
    if (($DefaultElevatedTime -gt 0  ) -and ($DefaultElevatedTime -lt ($config.MaxElevatedTime +1)))
    {
        $config.DefaultElevatedTime = $DefaultElevatedTime
    }
    else
    {
        $config.DefaultElevatedTime = $config.MaxElevatedTime
    }
}

if ($null -eq $Tier0ServerGroupName )
{
    $DefaultT0ComputerGroup = $config.Tier0ServerGroupName
    $T0computergroup = Read-Host -Prompt "Tier 0 computers group default[$($DefaultT0computerGroup)]"
    if ($T0computergroup -ne "")
        {$config.Tier0ServerGroupName = $DefaultT0ComputerGroup}
    else
        {$config.Tier0ServerGroupName = $DefaultT0ComputerGroup}
}
if ($null -eq (Get-ADGroup $config.Tier0ServerGroupName))
{
    Write-Output "$($config.Tier0ServerGroupName) is not a valid AD group"
    #Return
}
$T0ServerGroup = Get-ADGroup $config.Tier0ServerGroupName
$config.LDAPT0Computers = $config.LDAPT0Computers -replace "\[DNTier0serverGroup\]", $T0ServerGroup.DistinguishedName
if ($GroupManagementTaskRerun -eq $null)
{
    $Stgrouprerun = $config.GroupManagementTaskRerun
    $Stgrouprerun = Read-Host "Minutes to evaluate Tier 1 Admin groups[$($config.GroupManagementTaskRerun)]" 
    $config.GroupManagementTaskRerun = $Stgrouprerun
}
#Writing configuration file
ConvertTo-Json $config | Out-File "$InstallationDirectory\$configFileName" -Confirm:$false

#create eventlog and register EventSource id required
if ($null -eq (Get-EventLog -List | Where-Object {$_.LogDisplayName -eq $config.EventLog}))
{
    New-EventLog -LogName $config.EventLog -Source $config.EventSource
    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1 -Message "JIT configuration created"
}

#createing Scheduled Task Section
if ($CreateScheduledTaskADGroupManagement -eq $true) 
{
    $STprincipal = New-ScheduledTaskPrincipal -UserId "$((Get-ADDomain).NetbiosName)\$((Get-ADServiceAccount $config.GroupManagedServiceAccountName).SamAccountName)" -LogonType Password
    If (!((Get-ScheduledTask).URI -contains "$StGroupManagementTaskPath\$STGroupManagementTaskName"))
    {

        $STaction = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -file "' + $InstallationDirectory + '\Tier1LocalAdminGroup.ps1"') -WorkingDirectory $InstallationDirectory
        #$DurationTimeSpan = New-TimeSpan -Minutes $config.GroupManagementTaskRerun
        #$DurationTimeSpanIndefinite = ([TimeSpan]::MaxValue) 
        $STtrigger = New-ScheduledTaskTrigger -Once -RepetitionInterval (New-TimeSpan -Minutes $ServerEnumerationTime) -At (Get-Date)
        Register-ScheduledTask -Principal $STprincipal -TaskName $STGroupManagementTaskName -TaskPath $StGroupManagementTaskPath -Action $STaction -Trigger $STtrigger
        Start-ScheduledTask -TaskPath "$StGroupManagementTaskPath\" -TaskName $STGroupManagementTaskName
    }
    If (!((Get-ScheduledTask).URI -contains "$StGroupManagementTaskPath\$STElevateUser"))
    {
        <#
        create s schedule task who is triggered by eventlog entry in the event Log Tier 1 Management
        #>
        $STaction = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -file "' + $InstallationDirectory + '\ElevateUser.ps1" -eventRecordID $(eventRecordID)') -WorkingDirectory $InstallationDirectory
        $CIMTriggerClass = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger
        $Trigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
        $Trigger.Subscription = "<QueryList><Query Id=""0"" Path=""$($config.EventLog)""><Select Path=""$($config.EventLog)"">*[System[Provider[@Name='$($config.EventSource)'] and EventID=$($config.ElevateEventID)]]</Select></Query></QueryList>"
        $Trigger.Enabled = $true
        $Trigger.ValueQueries = [CimInstance[]]$(Get-CimClass -ClassName MSFT_TaskNamedValue -Namespace Root/Microsoft/Windows/TaskScheduler:MSFT_TaskNamedValue)
        $Trigger.ValueQueries[0].Name = "eventRecordID"
        $Trigger.ValueQueries[0].Value = "Event/System/EventRecordID"
        Register-ScheduledTask -Principal $STprincipal -TaskName $STElevateUser -TaskPath $StGroupManagementTaskPath -Action $STaction -Trigger $Trigger
    }
}
