# Just-In-time Installation 



## Concept
One of the biggest challenges in modern Active Directory-based environments is that server administrators often have extensive access to many server systems. This issue is described in detail in the blog: https://techcommunity.microsoft.com/blog/coreinfrastructureandsecurityblog/protect-tier-1-sleep-well-at-night-/4418653.

The solution presented here aims to mitigate exactly this attack vector. Unlike many commercially available products, this application relies solely on built-in Windows features. It demonstrates how effective Just-In-Time administration can be implemented using native Windows tools, without the need for any third-party software. No modifications or additional services are required on the target systems.

The concept of this solution is to create a dedicated group for each computer in an OU, with the group name containing the computer's name. Each group is assigned to a single server and, through group policies, is added to the local administrators of that server. When a user is added to a group, they receive administrator privileges on the target system upon their next login. If the system is compromised, only the user is affected, and they do not have elevated permissions beyond the local system. This approach effectively addresses the problem of lateral movement.

Using Active Directory's Privileged Identity Management (PIM) feature, group membership can be time-limited.

With this concept, users can elevate themselves to administrator status, but they do not have permission to manage the Active Directory groups directly. Assignment is handled via a Group Managed Service Account (gMSA), which decouples the request and assignment processes. Additionally, users can only be elevated for specific servers, depending on the OU structure.

## Pre-Requisites

The T1JIT solution relies exclusively on existing Active Directory, PowerShell, and .NET features. To use T1JIT, the Modern Tier Level Model is essential. An Active Directory structure must be in place that allows identification of target systems. In complex environments, it is recommended to create a hierarchical OU structure, as this simplifies access management.

An example structure could look like this:
- OU=Server
  - Infrastructure
  - Application1
    - Web Server
  - Terminal Server
    - Server Farm 1
    - Server Farm 2

The OU=Server can be assigned a user group that is permitted to obtain administrator rights on any system within this structure.
The OU=Infrastructure can be assigned a user group that receives administrator rights only on infrastructure servers, but not on systems in OU=Server or OU=Application,OU=Server, or servers in OU=Terminal Server.
The OU=Terminal Server can be assigned a user group that receives administrator rights on all terminal servers, including those in sub-OUs, but not on systems outside this OU.

The required administrative OU structure should look similar to this:
- OU=Admin (base OU for a modern tiering concept)
  - Tier 0 (Tier 0 administrative AD objects)
    - Groups (Tier 0 groups; a group for Tier 0 computer objects should exist here)
    - Computers (Tier 0 computer member server objects)
  - Tier 1 (Tier 1 management AD objects)
    - Groups (Tier 1-based management groups)
    - JIT-Administration (groups created by this solution are stored in this OU)

Additionally, the Privileged Access Management (PAM) feature must be enabled in Active Directory. PAM can be activated with the following command:
Enable-ADOptionalFeature 'Privileged Access Management Feature' -Scope ForestOrConfigurationSet -Target contoso.com

For each OU under the Server OU, a group for delegation should be created.

Domain Administratorprivileges are required to install the solution. If you want a delegated installation without Domain Administrator privileges the following steps must be prepared from a Domain Admin
1. create the following folder \\<domain>\SYSVOL\<domain>\Just-In-Time
2. create a Organizational Unit OU=JIT-Administration,OU=Tier 1,OU=Admin,DC=<domain>
3. create a GMSA
3.1 Add the JIT-Server as allow to retrieve password
3.2. Provide write permission to the \\<domain>\SYSVOL\<domain>\JUST-In-Time
3.3. Provide write permission to the OU=JIT-Administration,OU=Tier 1,OU=Admin,DC=<domain>

### Active Dirctory

In Active Directory, an OU structure similar to the one described above should be created in each domain of the AD forest.

### JIT-Server

The JIT solution requires one or more Windows servers. On these servers, users only need standard user permissions to submit a JIT request. No special requirements are necessary for these servers, as long as they are standard Windows installations.

## Installation
The installation is based on the installation of the solution and configuration of the T1JIT solution. Download the latest version from the relasefolder from https://github.com/Kili69/T1JIT/release

### First Server Installation
To install the T1JIT solution run the .\install-JIT.ps1 with local Administrator privileges. This script copies the required Powershell modules and scripts to the server. 

### Additional Server Installation

## Configuration
After the installation of the solution run the config-JIT.ps1 script. This script generates the Just-In-Time configuration. 
The configJIT.ps1 will guide you to the JIT configuration. 

#### Admin-Prefix

Is a prefix to identify the active directory group as JIT-Administration group

#### Group Manages Service Account

name of the GMSA for the JIT Solution. If the GMSA is not available it will be created during the configuration

#### Delegation File path

The full qualified path to theJIT-Delegation file. This file contains the acces permission who can request access t a server

#### JIt-Administration Groups

A AD organiuzational user (OU) to store the JIT-Administration groups

#### Server OU

A organizational unit (OU) who contains the target server. It is not required to define sub folders. 
You can define multiple OUs if you server are distributed in you AdD

#### Maximum elevation time

Is the time in minutes how long a user can be elevated to a server. Default value is 24 h (1440 minutes)

#### Minimum elevation time

Is the mimimum time fpor adminitrator elevtion. Valused below 5 minutes are not supported

#### Tier 0 computer groups

The name of the AD group who contains Tier 0 member server. Users can be elevated to Tier 0 computers

#### Tier 0 computer OU

Is the relative path to Tier 0 computers in all domains in the AD-forest

#### JIT-Member elevation

The time in minutes how often the JIT member will be elevated in Active Directory

#### Tier 1 search base

The distinguished name of the Tier 1 member servers. Multiple DN can be added.

### Assing a Group Policy to the target server

On every OU who ist listed in the JIT configruation apply a Group Policy In this group policy create a Group Policy perferences who add the <AdminPerFix><domain><Domainseparator>%computerName% (e.g. Admin_contoso.com#%computerName% )to the local Administrator group. 

### Managing a Member Server OU

#### Get the current configured OU

With the *Get-JITServerOU* command you will retrieve a list of OU who are currently configured
 
To add a new OU for member servers use the *Add-JITServerOU*. This command adds a new searchbase to the configuration
Add-JITServerOU -OU "<DistringuishedName>"
Example: Add-JITServerOU -OU "OU=MyOrg,DC=contoso,DC=com"
Within this command, any computer object in the OU OU=MyOrg,DC=contoso,DC=com is now part of the JIT Administation 

To remove a OU from the configuration use the Remove-JITServerOU command. e.g. Remove-JITServer -OU "OU=MyOrg,DC=contoso,DC=com"

### Delegation configuration

To define wich user can be elevated to a server you need to configure the delegation. To allow a user for elevation the user must be member of a group or it can be directly assigned.

To retrieve the current delegation configuration use the *Get-JITDelegation" command. If the OU parameter is not applied the entries delegation configuration is shown.

To allow a user or group to be elevated on a server in a OU use the *Add-JITDelegation" command with the parameter OU who contains the distinguished Name of the target OU and the ADObject who is the user or group name
the ADObject can be in the format
- Name => is a user or group in the current domain e.g. mygroup or myuser
- UPN => is a valid user in the AD forest e.g. myuser@contoso.com
- NT4 Style => is a user or gorup in a forest or child domain e.g. fabrikam\myuser
- canonical name => is a user or group in a forest domain e.g. contoso.com/myuser

To remove a delegation use the *Remove-JItDelegation" command with the parameter *OU* for the target OU and the *ADObject* for the user / group entry who should be removed

## Just-In-Time in Action

To request a administrator privileged this solution provides several ways. At the end all refere to the same process => creating a new event log entry in the JIT server and the JIT server will consume the entry, validate the request and add the user to the target group. 
You can only request administrator access for users and not for groups

### Requesting privileged access

To request a administrator access use the *New-AdminRequest* command.
The New-AdminRequest command uses the following parameters:
-  Server is the name of the server where the user request administrator privilege. This parameter is mandatory
- ServerDomain is required is the target server is not member of the domain where the JIT server is located
- Minutes is the TTL how logon is a user able to request administrator privileges. The value can't be lower the 5 minutes and higer the the configured maximum elevation time. If this parameter is not available the configured default value will be used
- User is the AD user who will be elevated. If this parameter is not provided the current user will be used

Here some examples:

New-AdminRequest -Server myServer

    Will provide Administrator privileges on the server myServer, if the user is allowed, for the configured default TTL
 
New-AdminRequest -Server myServer -minutes 120

    Will provide Administrator privileges on the server myServer for 120 minutes, if the user is allowed
New-AdminRequest -Server myServer -user user@contoso.com

    Will provide Administrator privileges for the user user@contoso.com on the server myServer with the default TTL. 

### Elevation status

To get the current elevation status of a user use the *Get-AdminStatus* command. If the parameter -user is not used, the command provide the current elevation status of the user.

Here some examples:
Get-AdminStatus 

    Provies a list of servers with administrator privileges and TTL of the current user

Get-AdminStatus -user myuser@contoso.com

    Provides a list of servers with administrator privileges and TTL of the user myuser@contoso.com

## Monitoring

T1JIT is based on Windows Event logs. All Events are monitored in the "Tier 1 Management" event log below the Application and services log.
The events are described in the .\Eventd.MD file

## Trouble-shooting

Use the Tier 1 Management event log for trouble shooting. The elevation process is documented in a debug log file. The path to the Debug log file is given in the Elveation event (Event ID 2106)