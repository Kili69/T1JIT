
# Just-In-Time Solution for Active Directory Member Servers

## Project Description

This project provides a Just-In-Time (JIT) solution for managing local administrator rights on Active Directory member servers. The goal is to reduce the risk of lateral movement in case of server compromise by ensuring that users are only temporarily granted elevated privileges.
This project is based on Active Directory features and do not required agents oder high privileged users on the target systems. 

## Problem Statement

In many IT environments, users are members of the local administrators group on multiple servers. If one server is compromised, an attacker can exploit these privileges to move laterally across the network. Many existing solution requires Agents, high privileged or using privileged accounts in the background. 
All ot those solutions provides a lateral movement attack path, because there is one high privileged identitiy on the target system. 
This soultion works without a privileged identitiy on teh target computers.

## How does T1JIT works

T1JiT works with Active Directory groups and group polices. A user can connect to the KJIT-Web Service and select a target server and the elevation time. With the "request access" access button a request message is written to the Just-In-Time event log. 
The event log is consumed from a group managed service account, who reads the event log and validate the user is allowed to request the access. If the user is allowed, the user object if time-bound added to the group who is member of the local administrator on the target server. 
While the group where the user is added contains the target server in the name,only one group policy with a variable is required to assign the local administrator rights on the target server.
The user is automatically removed from the local administrator group after the time is expired.
The groups will be automatically created by the JIT-Solution, if a computer oject exists in the configured target OU.


## Solution Structure 

- `src`: contains all source code
- `Release`: contains all files required for the installation of the JIT-Solution. 
- `docs`: documentation
- `build`: scripts to build a new release version

## Quick-start Installation

Download all files from the relase directory and run the install-JIT.ps1. If the PIM feature in Active Directory is not enabled, Enterprise-Administrator privileges are required. 
If you installing this JIT-Solution not as a Domain Administrator the following pre-requisites are required:
- Validate Active Directory root-key from group managed service account exists
- Folder \\<domain>\\SYSVOL\<domain>\JUST-IN-TIME
- OU for the Just-In-Time groups e.g. OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin,DC=<domain>
- Group Managed Service Account 
    - Allow to retrieve password on the JIT server
    - Create group object in the JIT-Administrator Groups OU

required installation permission:
- Member of the local administrator groups
- Create file permission on \\<domain>\\SYSVOL\<domain>\JUST-IN-TIME

### Install Just-In-Time

1. Run the install-JIT.ps1 script. This script will install the JIT-Solution on the current computer. 
2. Move to the %ProgramFiles%\Just-IN-time folder and the config-Jit.ps1 script to configure the JIT-Solution. This script will ask for the required configuration parameters and write them to the config file.
3. COnfigure the group policy to assign the local administrator rights on the target servers. The group policy should contain a preference to add the <AdminPrefix>%AD-DNSdomainname%<DomainSeparator>%<ComputerName>% to the local administrator group.
4. (optional) Install the KJIT-Web service with the install-kjitweb.ps1 script. This script will install the KJIT-Web service on the current computer.

### Configure Just-In-Time

The configuration of the JIT-Solution is done with the config-JIT.ps1 script. This script will ask for the required configuration parameters and write them to the config file. The configuration parameters are:
- Admin Prefix: The prefix for the group name who is member of the local administrator group on the target server. The group name will be in the format <AdminPrefix>%AD-DNSdomainname%<DomainSeparator>%<ComputerName>%. The default value is "Admin_".
- GMSAccount: The name of the group managed service account who will read the event log and add the users to the local administrator group on the target server. The format should be <domain>\<gmsaccountname>$.   
- OU for local Administrator groups: The OU where the groups who are member of the local administrator group on the target server are located. Take care onyl the GMSA and domain administrators should have permissions to create groups in this OU. The groups will be automatically created by the JIT-Solution, if a computer oject exists in the configured target OU.
- Maximum elevation time: The maximum time for the elevation. The user will be automatically removed from the local administrator group after the time is expired. The default value is 60 minutes.
- searchbase: The searchbase for the computer objects of the target servers. The JIT-Solution will only work for computer objects who are located in this OU or its child OUs.

### Configure elevation privileges

To allow a user to request administrators privileges on servers in a OU use the ADD-JITdelegation command. This command will add user or group to be evlevated on the target servers. The command should be run with the following parameters:
- Identity: The identity of the user or group who should be allowed to request administrators privileges on the target servers. The format should be <domain>\<username> or <domain>\<groupname>.
- OU: The OU where the computer objects of the target servers are located. The JIT
Solution will only work for computer objects who are located in this OU or its child OUs. A user will inherit the privileges to request administrators privileges on the target servers, if the user is member of a group who is allowed to request administrators privileges on the target servers.
create sub OU's below the target OU and delegate users / groups to this sub OU's to have a better structure and overview of the delegations.
e.g.
add-jitdelegation -Identity "domain\serveradmins" -OU "OU=Server,DC=domain,DC=local"
    Any user who is member of the "domain\serveradmins" group will be able to request administrators privileges on the target servers who are located in the "OU=Server,DC=domain,DC=local" OU or its child OUs.
add-jitdelegation -Identity "domain\SQLAdmins" -OU "OU=SQLServer,OU=Server,DC=domain,DC=local"
    Any user who is member of the "domain\SQLAdmins" group will be able to request administrators privileges on the target servers who are located in the "OU=SQLServer,OU=Server,DC=domain,DC=local" OU or its child OUs.
    Addtional members of the "domain\serveradmins" group will also be able to request administrators privileges on the target servers who are located in the "OU=SQLServer,OU=Server,DC=domain,DC=local" OU or its child OUs, because the "domain\serveradmins" group is member of the "domain\SQLAdmins" group.

### Useage of JIT

A user can now request administrator privielges via Powershell withou any privilege in active directory. To request administrator privileges for a target server the user can use the New-AdminRequest command. This command should be run with the following parameters:
- Server: The name of the target server. The format should be <computername>
- Duration: The duration for the elevation. The default value is 60 minutes. The maximum value is the value configured in the configuration of the JIT-Solution.
e.g.   
    New-AdminRequest -Server myserver.domain.local 
        This will request administrator privileges for the "myserver" server for 60 minutes. The user will be automatically removed from the local administrator group after 60 minutes.
    New-AdminRequest -Server myserver.domain.local -Duration 30 
        This will request administrator privileges for the "myserver" server for 30 minutes. The user will be automatically removed from the local administrator group after 30 minutes.
    New-AdminRequest -Server myserver.domain.local -Duration 120 -User anotheruser
        This will request administrator privileges for the "myserver" server for 120 minutes on behalf of the user "anotheruser@


## Using the Web Interface

The KJIT-Web service provides a web interface for users to request administrator privileges on the target servers. The web interface is accessible via http://<server>.<domain>:5240. The user can select the target server and the duration for the elevation. The user can also see the status of their requests and the remaining time for the elevation.

### Installation of the KJIT-Web service

The KJIT-Web service can be installed with the install-kjitweb.ps1 script. This script will install the KJIT-Web service on the current computer. The KJIT-Web Service must be installed on a server where the JIT-Solution is installed.
### Using the KJIT-Web service

To use the KJIT-Web service, the user can open a web browser and navigate to http://<server>.<domain>:5240. The user can then select the target server and the duration for the elevation. The user can also see the status of their requests and the remaining time for the elevation.

### Configuration of the KJIT-Web service

The KJIT-Web service can be configured with the appsettings.json file. The configuration parameters are:
- Branding: The branding configuration for the web interface. The parameters are:
    - LogoPath: The path to the logo for the web interface. The default value is "/images/logo.png". The logo should be a square image with a size of 100x100 pixels.
    - CompanyName: The name of the company for the web interface. The default value is "Contoso Ltd.". The company name will be displayed in the header of the web interface.
- AllowedHosts: The allowed hosts for the web interface. The default value is "*". The web interface will only be accessible from the specified hosts. To allow access from any host, set the value to "*".

## Security Considerations
- The KJIT-Web service should be configured to use HTTPS to encrypt the communication between the client and the server.
- The KJIT-Web service should be offered via Azure Enterprise Application Proxy or a similar solution to provide secure remote access to the web interface.

## Configuration and Customization
The JIT-Solution can be customized to fit the specific needs of the organization. The configuration parameters can be adjusted to meet the security requirements and the operational needs of the organization. To customize the JIT solution use the Powershell module who is installed with the JIT-Solution. The module provides commands to manage the configuration and the delegations for the JIT-Solution.

### Get-JITConfig
The Get-JITConfig command can be used to retrieve the current configuration of the JIT-Solution. This command will return an object with the current configuration parameters.

#### Parameters
- configurationfile: The path to the configuration file. If this parameter is not specified, the command will return the configuration from the default configuration file located in the installation directory of the JIT-Solution.
#### Example

    Get-JITConfig
        This will return the current configuration of the JIT-Solution. The output will be an object with the current configuration parameters.
    Get-JITconfig -configurationfile C:\config\jitconfig.json
        This will return the configuration of the JIT-Solution from the specified configuration file. The output will be an object with the configuration parameters from the specified configuration file.
### Get-AdminStatus
The Get-AdminStatus command can be used to retrieve the current status of the administrator privileges for a target server. This command will return an object with the current status of the administrator privileges for the specified target server.

#### Parameters
- User: The user for whom the status should be retrieved. The format should be <domain>\<username>. If this parameter is not specified, the command will return the status for the current user.

#### Example

    Get-AdminStatus 
        This will return the current elevation status for the current user.
    Get-AdminStatus -User anotheruser
        This will return the current elevation status for the user "anotheruser".

### Get-UserElevationStatus
The Get-UserElevationStatus command can be used to retrieve the current elevation status for a server. This command will return an object with the current elevation status for the specified server.

#### Parameters
- Server: The name of the target server. The format should be <computername>.

#### Example

    Get-UserElevationStatus -Server myserver
        This will return the current elevation status for the "myserver" server. The output will be an object with the current elevation status for the "myserver" server.  

### Get-JITDelegation
The Get-JITDelegation command can be used to retrieve the current delegations for the JIT-Solution. This command will return an object with the current delegations for the JIT-Solution.   

#### Example

    Get-JITDelegation
        This will return the current delegations for the JIT-Solution. The output will be an object with the current delegations for the JIT-Solution.

### Get-JITServerOU
The Get-JITServerOU command can be used to retrieve the current server OU for the JIT-Solution. This command will return the current server OU for the JIT-Solution.

#### Example

    Get-JITServerOU
        This will return the current server OU for the JIT-Solution. The output will be the current server OU for the JIT-Solution.

### Remove-JITDelegation
The Remove-JITDelegation command can be used to remove a delegation for the JIT-Solution. This command will remove the specified delegation for the JIT-Solution.

#### Parameters
- Identity: The identity of the user or group whose delegation should be removed. The format should be <domain>\<username> or <domain>\<groupname>.
- OU: The OU where the computer objects of the target servers are located. The JITSolution will only work for computer objects who are located in this OU or its child OUs. A user will inherit the privileges to request administrators privileges on the target servers, if the user is member of a group who is allowed to request administrators privileges on the target servers.

#### Example

    Remove-JITDelegation -Identity "domain\serveradmins" -OU "OU=Server,DC=domain,DC=local"
        This will remove the delegation for the "domain\serveradmins" group for the target servers who are located in the "OU=Server,DC=domain,DC=local" OU or its child OUs. Any user who is member of the "domain\serveradmins" group will no longer be able to request administrators privileges on the target servers who are located in the "OU=Server,DC=domain,DC=local" OU or its child OUs.
### Remove-JITServerOU
The Remove-JITServerOU command can be used to remove the server OU for the JIT-Solution. This command will remove the server OU for the JIT-Solution.

#### Parameters
- OU: The OU where the computer objects of the target servers are located. The JIT-Solution will only work for computer objects who are located in this OU or its child OUs. A user will inherit the privileges to request administrators privileges on the target servers, if the user is member of a group who is allowed to request administrators privileges on the target servers.
#### Example

    Remove-JITServerOU
        This will remove the server OU for the JIT-Solution. The JIT-Solution will no longer work for any target servers, because the server OU is required for the JIT-Solution to function.
### Add-jitdelegation
The Add-JITDelegation command can be used to add a delegation for the JIT-Solution. This command will add the specified delegation for the JIT-Solution.    

#### Parameters
- Identity: The identity of the user or group who should be allowed to request administrators privileges on the target servers. The format should be <domain>\<username> or <domain>\<groupname>.
- OU: The OU where the computer objects of the target servers are located. The JIT  Solution will only work for computer objects who are located in this OU or its child OUs. A user will inherit the privileges to request administrators privileges on the target servers, if the user is member of a group who is allowed to request administrators privileges on the target servers.

#### Example

    Add-JITDelegation -Identity "domain\serveradmins" -OU "OU=Server,DC=domain,DC=local"
        This will add a delegation for the "domain\serveradmins" group for the target servers who are located in the "OU=Server,DC=domain,DC=local" OU or its child OUs. Any user who is member of the "domain\serveradmins" group will be able to request administrators privileges on the target servers who are located in the "OU=Server,DC=domain,DC=local" OU or its child OUs.

### Add-JITServerOU
The Add-JITServerOU command can be used to add a server OU for the JIT-Solution. This command will add the specified server OU for the JIT-Solution.

#### Parameters
- OU: The OU where the computer objects of the target servers are located. The JIT-Solution will only work for computer objects who are located in this OU or its child OUs. A user will inherit the privileges to request administrators privileges on the target servers, if the user is member of a group who is allowed to request administrators privileges on the target servers.

#### Example

    Add-JITServerOU -OU "OU=Server,DC=domain,DC=local"
        This will add the "OU=Server,DC=domain,DC=local" OU for the JIT-Solution. Any computer objects located in this OU or its child OUs will be considered as target servers for the JIT-Solution.




## Contributing

github\Kili69
github\Bulgwei


## 📄 License

This project is licensed under the MIT License.

## Updates
2025-08-30 The update is a complete restructuring of the files to enable the use of C# code. Integrating C# is essential for extending the JIT Solution into a cloud service. In this update, the code has been separated from the release files. Additionally, the documentation has been moved to the Doc folder to improve clarity. All files required for operation are now located in the release directory.
