# Introduction 
This is a active directory Just-In-Time solution based on the Active Directory Version 2016 or higher and powershell scripts. The reduce the risk of a administrator ist 24x7 administrator on all or many computers. 
The principal of this project is: Each server has a domain local group in the active directory. This group is added to the local administrators of a server via group policy.  
A user can request local administrator privilege due writeing a event to the Tier 1 Local Administrator event log. A schedule task ist tirggered on this event. This schedule task is running as a Group Managed Service Account and add the user will be added time restricted to this group. Now the user is time restricted local administrator on a singel server.  

The project is based on:
1) Active directory Forest functional Level Windwos Server 2016
2) A schedule task who create a group for each computer object. 
3) A Group Policy who add the computer specified group to the local administrators group on each computer
4) A scheduled task to add a user to one of these tasks. this task is triggered by an event
5) A powershell script which triggers the scheduled task

# Getting Started
Before you start with this solutions, take care the Active Directory Forest functional levle is Windows Server 2016 or higher.
Provide a AD joined server with privileged access to T0 users or local user accounts. Take care Tier 1 users have only user privileg.

Pre-Reqs:
- AD Optional feature "Privileged Access Management Feature" needs to be installed
  
	  Enable-ADOptionalFeature "Privileged Access Management Feature" –Scope ForestOrConfigurationSet -Target <domainFQDN>
- RSAT-AD-Powershell feature needs to be installed on T1 JiT mgmt server


1.	Installation process
1.1. Tier 1 local user management server
Provide a Windows Server 2012 or higher for the Tier 1 local administrator management
1.2. copy scripts
copy the powershell scripts of this solution to  a directory with read privleged for any authenticated users
1.2. Organizational Unit
Create a Organizational unit for Tier 1 Local Administrators groups. Take care Tier 1 / Tier 2 users have no write access to this OU
1.3 run configuration
run the configuration config-jit.ps1. the configuration script asks for:
- Admin Prefix: is the prefix for the active directory group for the local administrator
- Domain: the DNS Name of the active Directory domain
- OU: the distinguished path of the O where the groups for the local administrators are created
- Tier0 Server group name: Is the name of the group, who conatins all Tier 0 servers objects
- Default elevation time: This is default value for elevated time if no time is specified in the request
- Installation directory: The working directory for the powershell scripts
- Elevation time for new server object: GroupManagementTaskRerun is the time how often a schedule task searches for new Tier 1 servers and removes permanent members
- Name of the group managed service acocunt: This account maintains the groups in the organizational units
3.	Create a group policy for local administrators
Create a group policy with a group policy preferences who adds the <Admin-Prefix>%COMPUTERNAME% to the local administrators. Assing this group policy to the Tier 1 server OU
- take care on localization OS languages (e.g.: on french systems, local administrators group is named "Administrateurs")
- you might need to use WMI filter for different server OS', e.g.:
  
			german:
  			select * FROM Win32_OperatingSystem WHERE OSLanguage=1031
			english:
			select * FROM Win32_OperatingSystem WHERE OSLanguage=1033
			french:
			select * FROM Win32_OperatingSystem WHERE OSLanguage=1036
			
    [MS-OE376]: Part 4 Section 7.6.2.39, LCID (Locale ID) | Microsoft Learn
    https://learn.microsoft.com/en-us/openspecs/office_standards/ms-oe376/6c085406-a698-4e12-9d4d-c3b0ee3dbc4a

# Build and Test
1. Validate the schedule task who creates the groups in the active directory
2. Validate the Group Policy add the groups create in the step above to the local administrator groups
3. Create a local administrator request due running the requestadminaccess.ps1
4. Validate the request is written to the Tier 1 Management event log
5. validate the requested user is member of the active directory group
6. logon as the requested user to the server and validate the user is local administrator and logoff
7. wait till the elevation time is expired
8. logon as the requested user and validate the user has no more administrator privileges

# Installation
The installation of of the T1JIT solution is a two step approach. Before youstarte with the installtion, take care the "mark from the web" attribute is removed from any script and PowerShell module file. It's recommended to sing the scripts and modules with your code signature certificates.

## 1 Install the source and the module
Run the install.ps1 script. this script will copy the script files to the %ProgramFiles% folder and register the Just-In-Time Powershell module. 

## 2 Configure T1JIT
Run the config-JIT.ps1 script to configure the JIT solution. 
### Initial configuration
In the initial configuration you configure the settings for JIT. the script will guide you to all configuration parameters. 
|Paramter| Description | Example |
|--------|-------------|---------|
|AdminPreFix | Is the prefix to identiy the Just-in-time administration group | Admin_ |
|OU | is the distinguished name of the organizational unit, where the Just-In-Time administration groups are located | OU=JIT-Administrators,OU=Tier 1,OU=Admin,DC=contoso,DC=com |
|MaxElevatedTime | Is the maximum time in minutes how long a user can be elevated as administrator | 1440 (24 hours) |
|DefaultElevatedTime | Is the default elevation time, if no time is requested | 60 minutes |
|Tier0serverGroupName | Is the distinguished name of the Tier 0 computer group. Computer objects whoa re member of this group can not be elevated via T1JIT | Tier 0 computers,OU=Groups,OU=Tier 0,OU=Admin,DC=contoso,DC=com|
|LDAPT0ComputerPath | Is the realvtive (without the domain component) distinguished name of the OU path, where Tier 0 computers are located. For those computer objects, the tool will not create any AdminGroups. | OU=Tier 0,OU=Admin |
|GroupManagedServiceAccountName | Is the GMSA name, who maintain the JIT groups. This GMSA must have write / create permission to the "OU" path for groups|
|Domain| is a list of domains who will be managed by the JIT tool| contoso.com|
|DelegationConfigPath| Is the UNC to the delegation configuration file. This file contains the permission, who can request Administrator access to a server | \\contoso.com\SYSVOL\contoso.com\Just-In-time\Tier1delegation.config|
|T1SearchBase| Is a list of full qualified or relative OU path, where the T1JIT solution is searching for computer object. If the path didn't contains the domain component of a DN (DC=), the solution include the path for any domain defined in the domains paramter|OU=Servers,DC=contos,OU=com|
|MaxConcurrentServer| Is the amount of group member ship a user can request in parallel| 50|

If you initial configuration is done, the delegation must be defined. It's recommended to create a group and add your administrators to this group. With the Add-JitDelegation CMDlet a delegation can be added to the configration
#### Add-JitDelegation
this Just-In-Time module command adds a new delegation to the configuration. The syntax of this command is
Add-JitDelegation -OU "OU=server,DC=contoso,DC=com" -ADObject "MyServerAdminGroup"
This allows any member of the MyServerAdminGroup to request Administrator access to any server in OU=server,DC=contoso,DC=com including any sub OU

#### Get-JitDelegation
Shows the current delegation. This command has no parameters

#### Remove-JitDelegation
Removes a delegation entry fro the configuratiob. 
Remove-JitDelegation -OU "OU=server,DC=contoso,DC=com" -ADObject "contoso\My2ndAdmins" 
Members of the contoso\My2ndAdmins cannot request Administrator privileges on server located in this OU

### Advanced configuration parameters
|Parameter| Description|Example| comment|
|---------|-------------|------|--------|
|ConfigScriptVersion| Is the version number who created this configuration file. This parameter is use to avoid incompatible configuration files created by a previous version| 0.1.20241013| The version number will be automatically updated the configuration command. Do not change this value|
|LDAPT0COmputer| This parameter exclude GMSA and domain controllers for the JIT tool. This is mandantroy to avoid a AD corrution if the JIT group policy (who adds user to the local administrator groupo) on domain root level|(\u0026(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521)))| do not change this setting|
|LDAPT1Computers| Is a LADP query to avoid the creation of incompatible (e.g. non Windows Operating System) computers. |(\u0026(OperatingSystem=*Windows*)(ObjectClass=Computer)(!(ObjectClass=msDS-GroupManagedServiceAccount))(!(PrimaryGroupID=516))(!(PrimaryGroupID=521))| This parameter should only be changed if T1JIT should be restricted to dedicated operation System versions|
|EventSource| is the event source paramter which will be used to create the required event log entries|T1Mgmt| Do not change this parameter|
|EventLog| Is the Eventlog name which will be used by the JIT solution for monitoring and elevation|Tier 1 Management| If this parameter needs to changen the Event source must be reregistered|
|EnableDelegatio|Enable or disable the delegation|True| DO not change this parameter|
|DomainSeparator| is a separator between the domain name and the computer name in the JIT computer group|#| |
|UseManagedByDelegation| If this parameter is true, the request permission can by managed by the "Managed by" attribute. This can be used to allow user / group the request privilege for a dedicated server in a OU where the user has no request privilege|true| |
|MaxConcurrentServer| This paramter defines how many admin request are allowed in parallel| 50 | |

# Contribute


