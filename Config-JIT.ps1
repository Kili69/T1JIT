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
    Version 0.1.20240116
        - Bug fix creating OU structure
        - Bug fix creating schedule task
    Version 0.1.20240202
        - Bug fix ACL for GMSA
    Version 0.1.20240205
        - Terminate the configuration script, if the AD PAM feature is not enabled
    Version 0.1.20240213
        - by Andreas Luy
        - corrected several inconsistency issues with existing config file
        - simplified/corrected OU creation function 
        - integrated updating delegationconfig location
        - group validation corrected
        - ToDo: use custom form for input
    Version 0.1.20240722
        - bug fixing
    Version 0.1.20240731
        - New Parameter advancedsetup
            The LDAP configuration string will only be visible if this switch is available
        - New Environment variable
            A global environment variable will created to determnine the configuration file. This environment variable will 
            be used in the request and elevate script to read a central configuration without using the config parameter
        - removed all parameters except InstallationDirectory and AdvancedSetup
        - new switch parameter -silent
            This parameter installs the GMSA on the local computer, create the Windows Eventlog and the schedule task
            This parameter can be used if the solution run on multiple servers. this parameter required the JIT.config file 
            JIT.CONFIG can be availabel through
                - Environment variable
                - configurationFile parameter
                - local jit.config
        - Schedule task to elevate users run in paralell 
            The userelevate schedule task run in paralell if multiple request events send to the event log



.PARAMETER InstallationDirectory
    Installation directory
.PARAMETER AdvancedSetup
    This switch provides additional properties during the setup
.PARAMETER configurationFile
    For unattended installation 
#>
[CmdletBinding(SupportsShouldProcess)]
param (
    #The installation directory to find the JIT.config file
    [Parameter (Mandatory=$false)]
    $InstallationDirectory,
    [Parameter ()]
    [switch]$AdvancedSetup,
    [Parameter ()]
    [switch]$silient,
    [Parameter (Mandatory=$false)]
    [string]$configurationFile
)
#region Functions
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

function CreateOU {
    <# Function create the entire OU path of the relative distinuished name without the domain component. This function
    is required to provide the same OU structure in the entrie forest
    .SYNOPSIS 
        Create OU path in the current $DomainDNS
    .DESCRIPTION
        create OU and sub OU to build the entire OU path. As an example on a DN like OU=Computers,OU=Tier 0,OU=Admin in
        contoso. The funtion create in the 1st round the OU=Admin if requried, in the 2nd round the OU=Tier 0,OU=Admin
        and so on till the entrie path is created
    .PARAMETER OUPath 
        the relative OU path withou domain component
    .PARAMETER DomainDNS
        Domain DNS Name
    .EXAMPLE
        CreateOU -OUPath "OU=Test,OU=Demo" -DomainDNS "contoso.com"
    .OUTPUTS
        $True
            if the OUs are sucessfully create
        $False
            If at least one OU cannot created. It the user has not the required rights, the function will also return $false 
    #>

    [CmdletBinding ( SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [string]$OUPath,
        [Parameter (Mandatory)]
        [string]$DomainDNS
    )
    try{
        #load the OU path into array to create the entire path step by step
        $DomainDN = (Get-ADDomain -Server $DomainDNS).DistinguishedName
        $aryOU=$OUPath.Split(",").Trim()
        $OUBuildPath = ","+$DomainDN
        
        #walk through the entire domain
        [array]::Reverse($aryOU)
        $aryOU|ForEach-Object {
            #ignore 'DC=' values
            if ($_ -like "ou=*") {
                $OUName = $_ -ireplace [regex]::Escape("ou="), ""
                #check if OU already exists
                if (Get-ADOrganizationalUnit -Filter "distinguishedName -eq '$($_+$OUBuildPath)'") {
                    Write-Debug "$($_+$OUBuildPath) already exists no actions needed"
                } else {
                    Write-Host "'$($_+$OUBuildPath)' doesn't exist. Creating OU" -ForegroundColor Green
                    New-ADOrganizationalUnit -Name $OUName -Path $OUBuildPath.Substring(1) -Server $DomainDNS                        
                    
                }
                #adding current OU to 'BuildOUPath' for next iteration
                $OUBuildPath = ","+$_+$OUBuildPath
            }


        }
 
    } 
    catch [System.UnauthorizedAccessException]{
        Write-Host "Access denied to create $OUPath in $domainDNS"
        Return $false
    } 
    catch{
        Write-Host "A error occured while create OU Structure"
        Write-Host $Error[0].CategoryInfo.GetType()
        Return $false
    }
    Return $true
}
#endregion
#region global variables 
$_scriptVersion = "0.1.20240729" #the current script version
#region Default values
$configFileName = "JIT.config" #The default name of the configuration file
$STGroupManagementTaskName = "Tier 1 Local Group Management" #Name of the Schedule tasl to enumerate servers
$StGroupManagementTaskPath = "\Just-In-Time-Privilege" #Is the schedule task folder
$STElevateUser = "Elevate User" #Is the name of the Schedule task to elevate users
try {
    $ADDomainDNS = (Get-ADDomain).DNSRoot #$current domain DNSName. Testing the Powershell AD modules are working
}
catch {
    Write-Output "Cannot determine AD domain - aborting!"
    return
}
#endregion
#Checking the access to the installation directory and provide the system environment variable
#Validate the installation directory and stop execution if installation directory doesn't exists
if (!($InstallationDirectory)){
    $InstallationDirectory = (Get-Location).Path
    Write-Host "Installation directory is $installationDirectory"
} elseif (!(Test-Path $InstallationDirectory)) {
    Write-Output "Installation directory missing - aborting!"
    exit
}
#region validate configuration file for silent installation
#the silient paramter required the configuration script or the Just-In-Time environment. 
#   The configuration scirpt will terminate if the configuraiton file is not accessible
if ($silient){
    if ($null -eq $env:JustInTimeConfig){
        if ($configurationFile -eq ""){
            Write-Host "The parameter silent requires the environment variable JustInTimeConfig or the -configurationFile parameter" -ForegroundColor Red
            Write-Host "Just-In-Time configuration stopped"
            exit
        }else{
            if (!(Test-Path $configurationFile)){
                Write-Host "The configuration file $configurationFile doesn't exists" -ForegroundColor Red
                Write-Host "Just-In-Time configuraiton stopped"
            }
        }
    } else{
        if (!(Test-Path $env:JustInTimeConfig)){
            Write-Host "Can't access configuration file $($env:JustInTimeConfig). Aborting configuration" -ForegroundColor Red
            Write-Host "Validate the Just-In-Time variable"
            exit
        }
    }
}
#endregion
#region Prepare system variable
#creating the system variable if if doesn't exists
try {
    #Provide the environment variable as system variable. In the 2nd step validate the 
    if ($Null -eq $env:JustInTimeConfig ){
        [Environment]::SetEnvironmentVariable("JustInTimeConfig", "$InstallationDirectory\$configFileName", "Machine")
        $env:JustInTimeConfig = "$InstallationDirectory\$configFileName"
    }
    if ($configurationFile -ne ""){
        if (Test-Path $configurationFile){
            $env:JustInTimeConfig = $configurationFile
        } else {
            Write-Host "Can't find configuration file $configurationFile. Installation terminated"
            exit
        }
    }
}
catch [System.Management.Automation.MethodInvocationException] {
    Write-Host "Local Administrator privileges required" -ForegroundColor Red
    Write-Host "Configuration stopped"
    exit
}
catch{
    Write-Host "A unexpected error is occured while creating the environment" -ForegroundColor Red
    Write-Host "configuration aborted"
    exit
}
#endregion
#Validate the Active Directory PAW feature is activated. If not the script will terminate
if (!((Get-ADOptionalFeature -Filter "name -eq 'Privileged Access Management Feature'").EnabledScopes)){
    Write-Host "Active Directory PAM feature is not enables" -ForegroundColor Yellow
    Write-Host "Run:"
    Write-Host "Enable-ADOptionalFeature ""Privileged Access Management Feature"" -Scope ForestOrConfigurationSet -Target $((Get-ADForest).Name)"
    Write-Host "Before continuing with JIT"
    Write-Host "Aborting!"
    exit
}
#region Creating the configuratin object with default values and read the existing configuration file it it exists. 
$config = New-Object PSObject
$config | Add-Member -MemberType NoteProperty -Name "ConfigScriptVersion"            -Value $_scriptVersion
$config | Add-Member -MemberType NoteProperty -Name "AdminPreFix"                    -Value "Admin_"
$config | Add-Member -MemberType NoteProperty -Name "OU"                             -Value "OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin,$((Get-ADDomain).DistinguishedName)"
$config | Add-Member -MemberType NoteProperty -Name "MaxElevatedTime"                -Value 1440
$config | Add-Member -MemberType NoteProperty -Name "DefaultElevatedTime"            -Value 60
$config | Add-Member -MemberType NoteProperty -Name "ElevateEventID"                 -Value 100
$config | Add-Member -MemberType NoteProperty -Name "Tier0ServerGroupName"           -Value "Tier 0 Computers"
$config | Add-Member -MemberType NoteProperty -Name "LDAPT0Computers"                -Value "(&(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))" #Deprecated Tier 0 computer identified by Tier 0 group membership
$config | Add-Member -MemberType NoteProperty -Name "LDAPT0ComputerPath"             -Value "OU=Tier 0,OU=Admin"
$config | Add-Member -MemberType NoteProperty -Name "LDAPT1Computers"                -Value "(&(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))" #added 20231201 LDAP query to search for Tier 1 computers
$config | Add-Member -MemberType NoteProperty -Name "EventSource"                    -Value "T1Mgmt"
$config | Add-Member -MemberType NoteProperty -Name "EventLog"                       -Value "Tier 1 Management"
$config | Add-Member -MemberType NoteProperty -Name "GroupManagementTaskRerun"       -Value 5
$config | Add-Member -MemberType NoteProperty -Name "GroupManagedServiceAccountName" -Value "T1GroupMgmt"
$config | Add-Member -MemberType NoteProperty -Name "Domain"                         -Value $ADDomainDNS
$config | Add-Member -MemberType NoteProperty -Name "DelegationConfigPath"           -Value "$InstallationDirectory\Tier1delegation.config" #Parameter added is the path to the delegation config file
$config | Add-Member -MemberType NoteProperty -Name "EnableDelegation"               -Value $true
$config | Add-Member -MemberType NoteProperty -Name "EnableMultiDomainSupport"       -Value $true
$config | Add-Member -MemberType NoteProperty -Name "T1Searchbase"                   -Value @("<DomainRoot>")
$config | Add-Member -MemberType NoteProperty -Name "DomainSeparator"                -Value "#"

#check for an existing configuration file and read the configuration
if (Test-Path $env:JustInTimeConfig){
    $existingconfig = Get-Content $env:JustInTimeConfig | ConvertFrom-Json
    if ((([regex]::Match($existingconfig.ConfigScriptVersion,"\d+$")).Value) -gt (([regex]::Match($_scriptVersion,"\d+$")).Value)){
        Write-Host "The configuration file is created with a newer configuration script. Please use the latest configuration file" -ForegroundColor Red
        exit
    }
    #Replace the default values with the existing values
    foreach ($setting in ($existingconfig | Get-Member -MemberType NoteProperty)){
        $config.$($setting.Name) = $existingconfig.$($setting.Name)
    }
    $config.ConfigScriptVersion = $_scriptVersion
}
#endregion
#Definition of the AD group prefix. Use the default value if the question is not answerd
if (!$silient){
    $AdminPreFix = Read-Host -Prompt "Admin Prefix for local administrators default[$($config.AdminPreFix)]"
    if ($AdminPreFix -ne ""){
        $config.AdminPreFix = $AdminPreFix
    }
    #Validation of the GroupManagedService Account
    do{
        $gmsaName = Read-Host -Prompt "Group Managed account name [$($config.GroupManagedServiceAccountName)]"
        if ($gmsaName -ne ""){ 
            $config.GroupManagedServiceAccountName = $gmsaName
        }
        #validation GMSA name
        if (5 -lt $gmsaName -gt 8 ){
            Write-Host "Invalid length of the GMSA name. The name must between 5 and 8 characters"
            $gmsaName = ""
        }
    } while ($gmsaName -ne "")
    $ReadEnableDelegationMode = Read-Host -Prompt "Enable the delegation mode? (Y/N)[Y]"
    if (($ReadEnableDelegationMode -eq "n") -or ($ReadEnableDelegationMode -eq "N")){
        $config.EnableDelegation = $false
    } else {
        $config.EnableDelegation = $true
        $DelegationFile = Read-Host -Prompt "File location of the delegation control file [$($config.DelegationConfigPath)]"
        if ($DelegationFile -eq ""){
            $DelegationFile = $config.DelegationConfigPath
        } else {
            $config.DelegationConfigPath = $DelegationFile
        }
        if (!(Test-Path $DelegationFile)){
            try{
                if (!(Test-Path (Split-Path $DelegationFile))){
                    Write-Host "Can't find this directory $(Split-Path $DelegationFile). Create the directory manually "
                } else {
                    $Null = New-Item $DelegationFile -ItemType File -ErrorAction Stop 
                    Remove-Item $DelegationFile -Force
                }
            }
            catch {
                Write-Host "Validate your premissions to create the $DelegationFile delegation file  " -ForegroundColor Yellow
            }
        }
    }
}
#region GMSA
$gmsaName = $config.GroupManagedServiceAccountName 
try {
    if ($null -eq (Get-ADServiceAccount -Filter "Name -eq '$($config.GroupManagedServiceAccountName)'" -Server $($config.Domain))){
        Write-Host "Create GMSA $($config.GroupManagedServiceAccountName) "
        New-ADServiceAccount -Name $config.GroupManagedServiceAccountName -DisplayName $config.GroupManagedServiceAccountName -DNSHostName "$($config.GroupManagedServiceAccountName).$((Get-ADDomain).DomainDNSroot)" -Server $config.Domain
    }
    $principalsAllowToRetrivePassword = (Get-ADServiceAccount -Identity $config.GroupManagedServiceAccountName -Properties PrincipalsAllowedToRetrieveManagedPassword).PrincipalsAllowedToRetrieveManagedPassword
    if (($principalsAllowToRetrivePassword.Count -eq 0) -or ($principalsAllowToRetrivePassword.Value -notcontains (Get-ADComputer -Identity $env:COMPUTERNAME).DistinguishedName)){
        Write-Debug "Adding current computer to the list of computer who an retrive the password"
        $principalsAllowToretrivePassword.Add((Get-ADComputer -Identity $env:COMPUTERNAME))
        Set-ADServiceAccount -Identity $GMSAName -PrincipalsAllowedToRetrieveManagedPassword $principalsAllowToRetrivePassword -Server $config.Domain
    }
} catch {
    if ( $Error[0].CategoryInfo.Activity -eq "New-ADServiceAccount"){
        Write-Host "A GMSA coult not be created.Validate you have the correct privileges and the KDS rootkey exists" -ForegroundColor Red
        return
    }
    Write-Host "A error occured while creating the GMSA or apply the current computer to the GMSA. Configuration stopped" -ForegroundColor Red
    Write-Host "Validate the GMSA exists and the computer has the privilege to retrive the GMSA password" -ForegroundColor Red
    return
}
#create the group managed service account and install the group managed service account locally if required. 
$oGmsa = Get-ADServiceAccount -Identity $config.GroupManagedServiceAccountName -Server $config.Domain
if ($false -eq (Test-ADServiceAccount -Identity $config.GroupManagedServiceAccountName )){
    #The GMSA 
    Install-ADServiceAccount -Identity $oGmsa
}
if (!(Test-ADServiceAccount -Identity $config.GroupManagedServiceAccountName)){
    Write-Host "validation of the Group managed service account ($($config.GroupManagedServiceAccountName)) failed." -ForegroundColor Red
    Write-Host "configuration terminated" -ForegroundColor Red
    exit
}

Add-LogonAsABatchJobPrivilege -Sid ($oGmsa.SID).Value
#endregion

if (!$silient){
    #Definition of the AD OU where the AD groups are stored
    do{
        $OU = Read-Host -Prompt "OU for the local administrator groups Default[$($config.OU)]"
        if ($OU -eq ""){
            $OU = $config.OU
        }
        try{
            if ([ADSI]::Exists("LDAP://$OU")){
                $config.OU = $OU
            } else {
                Write-Host "The Ou '$OU' doesn't exist" -ForegroundColor Yellow
                if (CreateOU -OUPath $OU -DomainDNS (Get-ADDomain).DNSRoot) {
                    Write-Host "'$OU' succesfully created" -ForegroundColor Green
                }
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
    if (!($aclGroupOU.Sddl.Contains($oGmsa.SID))){
        Write-Debug "Adding ACE to OU"
        #this section needs to be updated. Currently the GMSA get full control on the Tier 1 computer group OU. This should be fixed in
        # Full control to any group object in this OU and createChild, deleteChild for group object in this OU
        $identity = [System.Security.Principal.IdentityReference] $oGmsa.SID
        $adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
        $type = [System.Security.AccessControl.AccessControlType] "Allow"
        $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "All"
        $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType
        $aclGroupOU.AddAccessRule($ace)
        Set-Acl -AclObject $aclGroupOU "AD:\$($config.OU)"
    }
    #Definition of the maximum time for elevated administrators
    do {
        [UINT16]$MaxMinutes = Read-Host "Maximum elevated time [$($config.MaxElevatedTime)]"
        switch ($MaxMinutes) {
            0{
                $MaxMinutes = $config.MaxElevatedTime
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
            {$_ -gt $config.MaxElevatedTime} {
                Write-Host "The default elevation time cannot exceed 1440 minutes" -ForegroundColor Yellow
                $DefaultElevatedTime = 0
            }  
            Default {
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
            $config.Tier0ServerGroupName = $Group.DistinguishedName
        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
            Write-Host "$($T0computergroup) is not a valid AD group" -ForegroundColor Yellow 
            Write-Host "Please enter either group's SamAccountName or DistinguishedName" -ForegroundColor Yellow 
            $T0computergroup = ""
        } 
        catch {
            Write-Host "unexpected occured script terminated" -ForegroundColor Red
            Write-Host $Error[0]
            return
        }
    } while ($T0computergroup -eq "")

    if ($AdvancedSetup){
        $LDAPT1Computers = Read-Host "LDAP query for Tier 1 computers [$($config.LDAPT1Computers)]"
        if ($LDAPT1Computers -ne ""){
            $config.LDAPT1Computers = $LDAPT1Computers
        }
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

    do{
        try{
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
                    $config.GroupManagementTaskRerun = $GroupManagementTaskRerun
                } 
            }
        }
        catch [System.Management.Automation.ArgumentTransformationMetadataException]{
            Write-Host "Invalid number please use a numer between 5 and 1439" -ForegroundColor Red
            $GroupManagementTaskRerun = $Null
        }
        catch{
            Write-Host "a unexpected error is occured $($error[0].CategoryInfo)"
            $GroupManagementTaskRerun = $Null
        }
    } while (5 -lt $GroupManagementTaskRerun -gt 1439 )

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
                $SearchBase = Read-Host "Search base for JIT computers"
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
    $ForestRootDNS = (Get-ADForest).RootDomain
    Write-Host "It is recommended to store the configuration file on a central storage like \\$ForestRootDNS\SYSVOL\$ForestRootDNS\Just-in-Time\JIT.config"
    $configSaved = $false
    do {
        $configFileName = Read-Host "Provide a path to store the configuration file[$($env:JustInTimeConfig)]"
        if ($configFileName -eq ""){
            $configFileName = $env:JustInTimeConfig
        } 
        try {
            if (!(Test-Path (Split-Path -Path $configFileName ))){
                $Null = New-Item (Split-Path $configFileName) -ItemType Directory
            }
            if (!(Test-Path "$configFileName")){

                $Null = New-Item -Path "$configFileName" -ItemType File 
            }
            ConvertTo-Json $config | Out-File $env:JustInTimeConfig -Confirm:$false
            if($env:JustInTimeConfig -ne $configFileName){
                [Environment]::SetEnvironmentVariable("JustInTimeConfig", $configFileName, [EnvironmentVariableTarget]::Machine)
                $env:JustInTimeConfig = $configFileName
            }
            $configSaved = $true
        }
        catch [System.Security.SecurityException]{
            if ($error[0].InvocationInfo.Line -like "*SetEnvironmentVariable*"){
                Write-Host "Can change system variable. Administrator privileges required"
            } else{
                Write-Host "Can't write configuration file $configurationFile Write privileges required"
            }
        }
        catch [System.Management.Automation.MethodInvocationException]{
            Write-Host "$($error[0].Exception.InnerException)" -ForegroundColor Red
        }
        catch {
            Write-Host "can't create the configuration file. Please check the directory $configFileName exists and you have the permissions on this folder" -ForegroundColor Red
        }
    } while ($configSaved -eq $false)
}
#region create eventlog and register EventSource id required
Write-Host "Reading Windows eventlogs please wait" 
if ($null -eq (Get-EventLog -List | Where-Object {$_.LogDisplayName -eq $config.EventLog}))
{
    Write-Host "Creating new Event log $($config.EventLog)"
    New-EventLog -LogName $config.EventLog -Source $config.EventSource
    Write-EventLog -LogName $config.EventLog -Source $config.EventSource -EventId 1 -Message "JIT configuration created"
}
#endregion
#region createing Scheduled Task Section
Write-Host "creating schedule task to evaluate required Administrator groups"
$STprincipal = New-ScheduledTaskPrincipal -UserId "$((Get-ADDomain).NetbiosName)\$((Get-ADServiceAccount $config.GroupManagedServiceAccountName).SamAccountName)" -LogonType Password
If (!((Get-ScheduledTask).URI -contains "$StGroupManagementTaskPath\$STGroupManagementTaskName"))
{
    try {
        $STaction  = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument ('-NoProfile -NonInteractive -ExecutionPolicy Bypass -file "' + $InstallationDirectory + '\Tier1LocalAdminGroup.ps1"') 
        $STTrigger = New-ScheduledTaskTrigger -AtStartup 
        $STTrigger.Repetition = $(New-ScheduledTaskTrigger -Once -at 7am -RepetitionInterval (New-TimeSpan -Minutes $($config.GroupManagementTaskRerun))).Repetition                      
        Register-ScheduledTask -Principal $STprincipal -TaskName $STGroupManagementTaskName -TaskPath $StGroupManagementTaskPath -Action $STaction -Trigger $STTrigger
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
            $ElevateUserSettings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel 
            Register-ScheduledTask -Principal $STprincipal -TaskName $STElevateUser -TaskPath $StGroupManagementTaskPath -Action $STaction -Trigger $Trigger -Settings $ElevateUserSettings
        }                        
    }
    catch [System.UnauthorizedAccessException] {
        Write-Host "Schedule task cannot registered." -ForegroundColor Red
    }
}
#endregion
if ($config.EnableDelegation){
    Write-Host "do not forget to configure your OU delegation"
    Write-Host "to allow the group Server-Admins on OU=Server,OU=contoso,OU=com use the command"
    Write-Host ".\DelegationConfig.ps1 -action AddDelegation -OU ""OU=Server,DC=contoso,DC=com"" -AdUserOrGroup ""contoso\Server-Admins"" "
}
