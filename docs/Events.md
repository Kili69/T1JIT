# Windows Events used by T1JIT

## Tier 1 Management Event Log

| Event ID | Severity     | Message                                                                 | Remarks                                                                                   |
|----------|-------------|-------------------------------------------------------------------------|-------------------------------------------------------------------------------------------|
| 1        | Error        | An unhandled exception has occurred                                     | Validate the Debug log file                                                               |
| 100      | Information  | A new JIT request is generated                                          | This event occurs when a New-Admin command is executed                                    |
| 1000     | Information  | Elevation group is successfully created                                 | This event occurs if a new server is added to the target OU                               |
| 1001     | Error        | An elevation group could not be created                                 | Validate the GMSA has the appropriate write permission to the JIT-Administrator Group OU  |
| 1002     | Information  | A permanent user or group is removed from a JIT-Administrator group     | This event occurs if a user/group is added to a JIT-Administrator without a TTL           |
| 1003     | Error        | A permanent user of a JIT-Administrator group could not be removed      |                                                                                           |
| 1100     | Error        | The configuration path is not accessible                                | Validate the JUST-IN-TIME environment variable contains the correct path to the JIT.config file |
| 1004     | Warning      | The configuration contains a non-existing OU path                       | Validate the Tier1SearchBase configuration                                                |
| 2000     | Error        | Configuration file is missing or corrupt                                | Validate the JUST-IN-TIME environment variable                                            |
| 2001     | Error        | A JIT-Administrator group doesn't exist in the JIT-Administration OU    | Validate the group is generated and in the correct OU                                     |
| 2002     | Warning      | The requested user doesn't exist in Active Directory                    |                                                                                           |
| 2003     | Warning      | The requested elevation time exceeds the maximum configured elevation time |                                                                                           |
| 2004     | Information  | The requested user is already elevated to the selected server           |                                                                                           |
| 2005     | Error        | Invalid configuration file                                              |                                                                                           |
| 2006     | Warning      | The referenced event log for new elevation doesn't exist                |                                                                                           |
| 2100     | Warning      | The requested server doesn't exist in Active Directory                  |                                                                                           |
| 2103     | Warning      | The requested user is not allowed to be elevated on the target server   |                                                                                           |
| 2104     | Information  | A user is successfully elevated to a server                             |                                                                                           |
| 2105     | Error        | A server down exception occurred                                        | Validate AD-Webservices are available                                                     |
| 2106     | Information  | An elevation process is started                                         |                                                                                           |
| 2107     | Error        | An unhandled Active Directory exception has occurred                    |                                                                                           |
| 2109     | Error        | The configuration file contains an invalid jit-delegation.config file path |                                                                                           |

## Application Event Log

<!-- Ergänze hier weitere Events für das Application Event Log, falls vorhanden -->

