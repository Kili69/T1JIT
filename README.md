
# Just-In-Time Solution for Active Directory Member Servers

## Project Description

This project provides a Just-In-Time (JIT) solution for managing local administrator rights on Active Directory member servers. The goal is to reduce the risk of lateral movement in case of server compromise by ensuring that users are only temporarily granted elevated privileges.

## Problem Statement

In many IT environments, users are members of the local administrators group on multiple servers. If one server is compromised, an attacker can exploit these privileges to move laterally across the network. 

## Strcuture 
- `src`: source code
- `Release`: Solution 
- `docs`: documentation

## Quick-start Installation

Download all files from the relase directory and run the install-JIT.ps1. If the PIM feature in Active Directory is not enabled, Enterprise-Administrator privileges are required. If you installing this JIT-Solution not as a Domain Administrator the following pre-requisites are required:
- Folder \\<domain>\\SYSVOL\<domain>\JUST-IN-TIME
- OU for the Just-In-Time sroups e.g. OU=JIT-Administrator Groups,OU=Tier 1,OU=Admin,DC=<domain>
- Group Managed Service Account 
    - Allow to retrieve password on the JIT server
    - Create group object in the JIT-Administrator Groups OU

required installation permission:
- Member of the local administrator groups
- Create file permission on \\<domain>\\SYSVOL\<domain>\JUST-IN-TIME

Create Active Directory groups. Members of this group will get Administrator access to any server in a specifiert OU. To assing the group to a OU use the Add-JitDelegation command, who is part of the Just-In-time powershell module.

If the installation of the JIT-solution is finished, create a group policy with a preference to add the <AdminPrefix>%AD-DNSdomainname%<DomainSeparator>%<ComputerName>%
Link this group policy to any OU who is member of this JIT-Solution
Remove existing group policies who assing members to the local administrator group

For more information check the installation documentation in the /docs folder


## Contributing

github\Kili69
github\Bulgwei


## 📄 License

This project is licensed under the MIT License.
