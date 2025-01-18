In this file we describe the different event logon entries created by T1JIT

# Event ID Table
|Event ID| Event soure | Serverity |Description | Source|
|--------|-------------|-----------|------------|-------|
| 1      | T1MGMT      | Error     | A general Error has occured | ElevateUser.ps1|
|100     | T1MGMT| Information | This event message contains the information for an administrator request. The event contains the Distinguished name of the target user, the Active Directory group where the user will be added, the elevation time and the user who requested the Administrator access|New-AdminRequest|
|1000    | T1MGMT | Information | This eventlog entry will be created if a new group for Administrator access is created. | Tier1LocalAdminGroup.ps1|
|1001    | T1MGMT | Error | A general error occured while a Administrator access group will be created. Validate the GMSA has the proper writes to to create group objects in the configured OU| Tier1LocalAdminGroup.ps1|
|1002    | T1MGMT | Warning| A user is added permanently to a Administrator access group. AD Objects without a TimeToLive value will be removed from the Administrator Access group| Tier1LocalAdminGroup.ps1|
|1003    | T1MGMT | Error | A unexpected error occured, while removing a permanently member of a Administrator access group.| Tier1LocalAdminGroup.ps1|
|1004    | T1MGMT | Warning| A configured OU for searching computer objects doesn't exists in a domain | Tier1LocalAdmingroup.ps1|
|2000    | T1MGMT | Error | The configuration file is not available| ElevateUser.ps1|
|2001    | T1MGMT | Error | The group named in the event log entry is not available. please wait until the group is created| ElevateUser.ps1|edname 
|2002    | T1MGMT | Warning | The distinguished user name of a Administrator access doesn't exist | ElevateUser.ps1|
|2003    | T1MGMT | Warning | the requested elevation time is higher then the configured maximum allowed elevation time. The elevation time will be reduced to the maximum allowed elevation time| ElevateUser.ps1
|2004    | T1MGMT | Information| The user is still elevated. The elevation time will be set to the new requested elevation time| ElevateUser.ps1|
|2005    | T1MGMT | Error | The configuration file is invalid. Validate the configuration file is formated correct |ElevateUser.ps1|
|2006    | T1MGMT | Warning | The Eventlog entry could not be found in the Tier 1 Management event log| ElevateUser.ps1|
|2007    | T1MGMT | Error | A unexpected error has occured. View the Event message for mor details| ElevateUser.ps1| 
|2100    | T1MGMT | Error | The target computer object doesn't exist| ElevateUser.ps1|
|2101    | T1MGMT | Error | the delegation file is not available in the configured path| ElevateUser.ps1|
|2102    | T1MGMT | Warning| the computer object is not in a configured delegation OU. The user will not be elevated | ElevateUser.ps1|
|2103    | T1MGMT | Warning| the user is not allowed to request Administrator access on the target computer| ElevateUser.ps1|
|2104    | T1MGMT | Information | The user is successfully added to the elevation group | ElevateUser.ps1|
|2105    | T1MGMT | Error  | The AD Web Service could not be reacht to add a user to the elevation group| ElevateUser.ps1|
|2106    | T1MGMT | Information | The elevation procress strted. | ElevateUser.ps1|
