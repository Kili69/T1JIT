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
    Version 0.1.20231029
        - Add a the new parameter DelegationConfigFilePath to the configuration file
        - Existing configuration files will be updated the latest version
    Version 0.1.20231109
        - New parameter to enable of disable the delegation model
    Version 0.1.20231130
        - better validation of input paramters
        - Support of spaces in Tier 0 computer OU
        - Terminate script if the current configuration file is created with a newe config-jit.ps1 script
        - Set full control to the Tier 1 computer Group OU
    Version 0.1.20231201
        - New parameter in config file LDAPT1computers
            This parameter contains the LDAP query to select Tier 1 computers
            This parameter is required in Tier1LocalAdminGroup.ps1
        - Support of WhatIf and Confirm parameters
    Version 0.1.20231204
        - Bug Fix in LDAP query to evaluate the T0 Computer OU
        - The domain separator can be configured in the JIT.config
#>
<#
    script parameters
#>
[CmdletBinding(SupportsShouldProcess)]
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
    [INT] $ServerEnumerationTime = 10,
    [Parameter (Mandatory=$false)]
    #Enable the delegation Model
    [bool] $EnableDelegationMode = $false,
    [Parameter (Mandatory = $false)]
    #The delegation file path
    [string] $DelegationFilePath
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
    if ($false -eq  (Test-Path $export)){
        Write-Host 'Administrator privileges required to set "Logon AS Batch job permission" please add the privilege manually'
        Return
    }
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
$_scriptVersion = "0.1.20231203"
$configFileName = "JIT.config"
$MaximumElevatedTime = 1440
#$DefaultElevatedTime = 60
$DefaultAdminPrefix = "Admin_"
$DefaultLdapQuery = "(&(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))" #deprecated will be removed
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
$config = New-Object PSObject
$config | Add-Member -MemberType NoteProperty -Name "ConfigScriptVersion"            -Value $_scriptVersion
$config | Add-Member -MemberType NoteProperty -Name "AdminPreFix"                    -Value $DefaultAdminPrefix
$config | Add-Member -MemberType NoteProperty -Name "OU"                             -Value "OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin"
$config | Add-Member -MemberType NoteProperty -Name "MaxElevatedTime"                -Value $MaximumElevatedTime
$config | Add-Member -MemberType NoteProperty -Name "DefaultElevatedTime"            -Value 60
$config | Add-Member -MemberType NoteProperty -Name "ElevateEventID"                 -Value 100
$config | Add-Member -MemberType NoteProperty -Name "Tier0ServerGroupName"           -Value $DefaultServerGroupName
$config | Add-Member -MemberType NoteProperty -Name "LDAPT0Computers"                -Value $DefaultLdapQuery #Deprecated Tier 0 computer identified by Tier 0 group membership
$config | Add-Member -MemberType NoteProperty -Name "LDAPT0ComputerPath"             -Value "OU=Tier 0,OU=Admin"
$config | Add-Member -MemberType NoteProperty -Name "LDAPT1Computers"                -Value "(&(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))" #added 20231201 LDAP query to search for Tier 1 computers
$config | Add-Member -MemberType NoteProperty -Name "EventSource"                    -Value $EventSource
$config | Add-Member -MemberType NoteProperty -Name "EventLog"                       -Value $EventLogName
$config | Add-Member -MemberType NoteProperty -Name "GroupManagementTaskRerun"       -Value $STAdminGroupManagementRerunMinutes
$config | Add-Member -MemberType NoteProperty -Name "GroupManagedServiceAccountName" -Value $DefaultGroupManagementServiceAccountName
$config | Add-Member -MemberType NoteProperty -Name "Domain"                         -Value $ADDomainDNS
$config | Add-Member -MemberType NoteProperty -Name "DelegationConfigPath"           -Value "$InstallationDirectory\delegation.config" #Parameter added is the path to the delegation config file
$config | Add-Member -MemberType NoteProperty -Name "EnableDelegation"               -Value $EnableDelegationMode
$config | Add-Member -MemberType NoteProperty -Name "EnableMultiDomainSupport"       -Value $true
$config | Add-Member -MemberType NoteProperty -Name "T1Searchbase"                   -Value @("<DomainRoot>")
$config | Add-Member -MemberType NoteProperty -Name "DomainSeparator"                -Value "#"

#check for an existing configuration file and read the configuration
if (Test-Path "$InstallationDirectory\$configFileName")
{
    $existingconfig = Get-Content "$InstallationDirectory\$configFileName" | ConvertFrom-Json
    if ((([regex]::Match($existingconfig.ConfigScriptVersion,"\d+$")).Value) -gt (([regex]::Match($_scriptVersion,"\d+$")).Value)){
        Write-Host "The configuration file is created with a newer configuration script. Please use the latest configuration file" -ForegroundColor Red
    }
    foreach ($setting in ($existingconfig | Get-Member -MemberType NoteProperty)){
            $config.$($setting.Name) = $existingconfig.$($setting.Name)
    }
    $config.ConfigScriptVersion = $_scriptVersion

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
$ReadEnableDelegationMode = Read-Host -Prompt "Enable the delegation mode? (Y/N)[Y]"
if (($ReadEnableDelegationMode -eq "n") -or ($ReadEnableDelegationMode -eq "N")){
    $config.EnableDelegation = $false
} else {
    $config.EnableDelegation = $true
    if ($DelegationFilePath -eq ""){
        $DelegationFilePath = Read-Host -Prompt "File location of the delegation control file [$($config.DelegationConfigPath)]"
        if ($DelegationFilePath -ne ""){
            $config.DelegationFilePath = $DelegationFilePath
        }
    }
}

$gmsaName = $config.GroupManagedServiceAccountName 
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
if ($false -eq (Test-ADServiceAccount -Identity $config.GroupManagedServiceAccountName )){
    Install-ADServiceAccount -Identity $GMSaccount
}
Write-Debug "Test $GMSAName $(Test-ADServiceAccount -Identity $($config.GroupManagedServiceAccountName))"
Add-LogonAsABatchJobPrivilege -Sid ($GmSaccount.SID).Value

#Definition of the AD OU where the AD groups are stored
do{
    $OU = Read-Host -Prompt "OU for the local administrator groups Default[$($config.OU)]"
    if ($OU -eq ""){
        $OU = $config.OU
    }
    try{
        #if ([ADSI]::Exists("LDAP://$OU,$((Get-ADDomain).DistinguishedName)")){
            if ([ADSI]::Exists("LDAP://$OU")){
            $config.OU = $OU
        } else {
            Write-Host "The Ou $OU doesn't exist" -ForegroundColor Yellow
            $OU = $null
        }
    } 
    catch {
        Write-Host "invalid DistinguishedName" -ForegroundColor Red
        $OU = $null
    }

}while ($null -eq $OU)
Write-Debug  "OU $($config.OU) is accessible updating ACL"
$aclGroupOU = Get-ACL -Path "AD:\$($config.OU)"
if (!($aclGroupOU.Sddl.Contains($GMSaccount.SID)))
{
    Write-Debug "Adding ACE to OU"
    #this section needs to be updated. Currently the GMSA get full control on the Tier 1 computer group OU. This should be fixed in
    # Full control to any group object in this OU and createChild, deleteChild for group object in this OU
    #$GuidMap = New-ADDGuidMap
    $objGMSASID = New-Object System.Security.Principal.SecurityIdentifier $GMSaccount.SID
    #$ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $objGMSASID, "GenericAll", "Allow", "Descendents", $GuidMap["Group"] #Give Full control on group objects
    $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $objGMSASID, "GenericAll", "Allow" #Give Full control on the OU
    $aclGroupOu.AddAccessRule($ace)
    Set-Acl "AD:\$($config.OU)" -AclObject $aclGroupOU
}
#Definition of the maximum time for elevated administrators
do {
    [UINT16]$MaxMinutes = Read-Host "Maximum elevated time [$($config.MaxElevatedTime)]"
    switch ($MaxMinutes) {
        0 {
            $MaxMinutes = 1
        }
        {($_ -gt 0) -and ($_ -lt 15)} {
            Write-Host "Minimum elevation time is 15 minutes" -ForegroundColor Yellow
            $MaxMinutes = 0
          }
        {$_ -gt 1440}{
            Write-Host "Maximum elevation time 1441 minutes" -ForegroundColor Yellow
            $MaxMinutes = 0
        }
        Default{
            $config.MaxElevatedTime = $MaxMinutes
        }
    }
} while ($MaxMinutes -eq 0) 
#Definition of the default elevation time
DO {
    [INT]$DefaultElevatedTime = Read-Host -Prompt "Default elevated time [$($config.DefaultElevatedTime)]"
    switch ($DefaultElevatedTime) {
        0 {
            if ($config.DefaultElevatedTime -gt $config.MaxElevatedTime){
                Write-Host "The default elevation time could not exceed the maximum elevation time"
            } else {
                $DefaultElevatedTime = 1
            }
        }
        {($_ -gt 0) -and ($_ -lt 15)} {
            Write-Host "The default elevation time could not be lower then 15 minutes" -ForegroundColor Yellow
            $DefaultElevatedTime = 0
        }
        {$_ -gt 1440} {
            Write-Host "The default elevation time cannot exceed 1440 minutes" -ForegroundColor Yellow
            $DefaultElevatedTime = 0
        }  
        Default{
            $config.MaxElevatedTime = $DefaultElevatedTime
        }      
    }
} while($DefaultElevatedTime -eq 0)


do{
    $T0computergroup = Read-Host -Prompt "Tier 0 computers group default[$($config.Tier0ServerGroupName)]"
    if ($T0computergroup -eq ""){
        $T0ComputerGroup = $config.Tier0ServerGroupName 
    }
    Try {
        $Group = Get-ADGroup -Identity $T0computergroup
        $config.Tier0ServerGroupName = $Group.Name
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
        Write-Host "$($T0computergroup) is not a valid AD group" -ForegroundColor Yellow 
        $T0computergroup = ""
    } 
    catch {
        Write-Host "unexpected occured script terminated" -ForegroundColor Red
        Write-Host $Error[0]
        return
    }

} while ($T0computergroup -eq "")

$LDAPT1Computers = Read-Host "LDAP query for Tier 1 computers [$($config.LDAPT1Computers)]"
if ($LDAPT1Computers -ne ""){
    $config.LDAPT1Computers = $LDAPT1Computers
}

do{
    $Tier0OUDN = Read-Host "Tier 0 OU realtive distinguished name [$($config.LDAPT0ComputerPath)]"
    if ($Tier0OUDN  -eq ""){
        $Tier0OUDN = $config.LDAPT0ComputerPath
    }
    try{
        if ([ADSI]::Exists("LDAP://$Tier0OUDN,$((Get-ADDomain).DistinguishedName)")){
            $config.LDAPT0ComputerPath = $Tier0OUDN
        } else {
            Write-Host "Invalid DistinguishedName LDAP://$Tier0OUDN,$((Get-ADDomain).Distinguishedname)."
            $Tier0OUDN = ""
        }
    } catch{
        Write-Host "Invalid DN path $($Error[0].CategoryInfo.GetType().Name)"
        $Tier0OUDN = ""
    }
} while ($Tier0OUDN -eq "")

while ($GroupManagementTaskRerun -in (0..4))
{
    [int]$GroupManagementTaskRerun = Read-Host "Minutes to evaluate Tier 1 Admin groups[$($config.GroupManagementTaskRerun)]" 
    switch ($GroupManagementTaskRerun) {
        {$_ -lt 5} { 
            $GroupManagementTaskRerun = [int]$config.GroupManagementTaskRerun
            }
        {$_ -gt 1440} {
            Write-Host "The enumeration of Tier 1 computer must run at least once a day" -ForegroundColor Yellow
            $GroupManagementTaskRerun = 0
        }
        Default{
            $config.GroupManagementTaskRerun = $Stgrouprerun
        }
    }
}

do {
    $ReadHost = Read-Host "Enable Mulitdomain support (y/n) [$($config.EnableMultiDomainSupport)]"
    switch ($ReadHost) {
        "y" { 
            $config.EnableMultiDomainSupport = $true 
        }
        "n" { 
            $config.EnableMultiDomainSupport = $false
        }
        ""  { $ReadHost = "DefaultValue"}
        Default {
            $ReadHost = ""
            Write-Host "Invalid entry" -ForegroundColor Yellow
        }
    }
} while ($ReadHost -eq "")
#region T1 searchbase
If ((Read-Host "Do you want to enable Just-In-Time for the entire Domain?(y/n)[N]") -eq "y"){
    $config.T1Searchbase = @("<DomainRoot>")
} else {
    $arySearchBase = @()
    foreach ($SearchBase in $config.T1Searchbase){
        if ($SearchBase -ne "<DomainRoot>"){
            $arySearchbase += $SearchBase
        }
    }
    $config.T1SearchBase = $arySearchBase
    do{
        Write-Host "Current searchbase "
        Write-Host $config.T1Searchbase -Separator "`n"
        if ((Read-Host "Add search base? [N]") -eq "y"){
            $arySearchBase = @()
            $arySearchBase += $config.T1Seachbase
            $SearchBase = Read-Host "Search base"
            if ([RegEx]::Match($Searchbase,"^(OU|CN)=.+").Success){
                if ($arySearchBase -contains $SearchBase){
                    Write-Host "$SearchBase is already available"
                } else {
                    $config.T1Searchbase += $SearchBase
                }
            } else {
                Write-Host "Invalid DN Retry" -ForegroundColor Yellow
            }
        } else {
            $SearchBase = "N"
        }
    } while ($SearchBase -ne "N") 
}

#endregion
#Writing configuration file
ConvertTo-Json $config | Out-File "$InstallationDirectory\$configFileName" -Confirm:$false

#create eventlog and register EventSource id required
Write-Host "Reading Windows eventlogs please wait" 
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
        try {
            $STaction  = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -file "' + $InstallationDirectory + '\Tier1LocalAdminGroup.ps1"') -WorkingDirectory $InstallationDirectory
            $STtrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $ServerEnumerationTime) 
            Register-ScheduledTask -Principal $STprincipal -TaskName $STGroupManagementTaskName -TaskPath $StGroupManagementTaskPath -Action $STaction -Trigger $STtrigger
            Start-ScheduledTask -TaskPath "$StGroupManagementTaskPath\" -TaskName $STGroupManagementTaskName
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
        catch [System.UnauthorizedAccessException] {
            Write-Host "Schedule task cannot registered." -ForegroundColor Red
        }
        catch {
            Write-Host "An error occurred:"
            Write-Host $_
        }
    }
}
