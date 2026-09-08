# T1JIT Active Directory Test Environment

> All PowerShell scripts in this directory are development-only tools. They are
> maintained on `dev` and must not be merged into `main` or included in a
> release package.

The `New-T1JitTestEnvironment.ps1` script creates Active Directory objects for
functional and delegation tests. It is not part of the release package and must
only be used in a disposable test domain.

The script prints its version immediately after startup. The current script
version is `0.1.20260907`.

## Created Structure

The script creates the base OU `OU=Server` below the current domain root. The
name can be changed with `-BaseOUName`. If the base OU does not exist, the script
creates it before processing groups, child OUs, or computer accounts. The
script creates all OUs with accidental-deletion protection disabled. The following
child OUs are then created:

- `Groups`
- `Application1` through `Application10`
- `File-Server`
- `Terminal-Server`
- `SQL`

By default, the script distributes exactly 100 enabled computer accounts as
evenly as possible across the 13 role OUs. The first nine role OUs receive eight
accounts and the remaining four receive seven. Computer names use the role
prefix and a sequence number, for example `APP1-SRV01`, `FILE-SRV01`,
`TERM-SRV01`, and `SQL-SRV01`. Each account receives:

- `OperatingSystem`: `Windows Server 2022`
- `DNSHostName`: `<computer-name>.<domain-dns-name>`

The `Groups` OU contains the independent security group `Server-Administrator`
and one group named `Server-Administrator-<OU name>` for each role OU. The script
does not create memberships between these groups.

## Requirements

- Windows PowerShell with the Active Directory module
- Permission to create and update OUs, groups, and computer accounts
- A disposable Active Directory test domain

## Usage

Preview all changes without writing to Active Directory:

```powershell
.\New-T1JitTestEnvironment.ps1 -WhatIf
```

Create the default environment through a specific domain controller:

```powershell
.\New-T1JitTestEnvironment.ps1 -DomainController dc01.contoso.com
```

Create the default 100 computers with a different Windows Server version:

```powershell
.\New-T1JitTestEnvironment.ps1 -WindowsServerVersion 2025
```

Alternatively, create five computers per OU:

```powershell
.\New-T1JitTestEnvironment.ps1 `
    -ComputerCountPerOU 5
```

The script is idempotent. Existing OUs and groups are reused. Existing computer
accounts are enabled and receive the configured `OperatingSystem` and
`DNSHostName` values. No objects are deleted. Newly created OUs have accidental-
deletion protection disabled.
After successfully creating an OU or security group, the script prints a status
line containing the object's distinguished name. Existing objects do not produce
a creation status line.

## Processing Order

1. Load the Active Directory module and resolve the target domain.
2. Reuse or create the base OU below the domain root.
3. Reuse or create the `Groups` OU below the base OU.
4. Reuse or create all security groups in the `Groups` OU.
5. Reuse or create each role OU.
6. Create missing computer accounts or update existing account attributes.

All Active Directory writes support `-WhatIf` through PowerShell's
`ShouldProcess` mechanism.

## Clean Installation Test

The following scripts prepare a repeatable installation test on an existing
domain hierarchy:

- `Remove-T1JitInstallation.ps1` removes the installed PowerShell and KjitWeb
    components, scheduled tasks, event log, GMSA, generated JIT administrator
    groups, and JIT configuration files. It preserves `OU=Servers`, all computer
    objects below it, `OU=SQL`, and the eligibility groups.
- `Install-T1JitTestInstallation.ps1` creates a configuration in SYSVOL, invokes
    `install-JIT.ps1`, installs KjitWeb, configures the delegations, and validates
    the resulting service, tasks, GMSA, and delegation entries.

The installation test expects these existing objects in the current domain:

- `OU=Servers`
- `OU=SQL,OU=Servers`
- Security group `Global Server Administrators`
- Security group `SQL-Admins`

Run both scripts in Windows PowerShell 5.1 as a local administrator and Domain
Admin. Preview the cleanup first:

```powershell
.\Remove-T1JitInstallation.ps1 -WhatIf
```

Remove the installation after reviewing the targets:

```powershell
.\Remove-T1JitInstallation.ps1 -Force -Verbose
```

Preview and then perform the installation. The default web binding permits only
local access:

```powershell
.\Install-T1JitTestInstallation.ps1 -WhatIf
.\Install-T1JitTestInstallation.ps1 -Confirm:$false -Verbose
```

To permit a specific administration workstation to access KjitWeb, provide its
resolvable hostname or IP address:

```powershell
.\Install-T1JitTestInstallation.ps1 `
        -AllowedClient "PAW01.contoso.com" `
        -Confirm:$false `
        -Verbose
```

The parent delegation makes `Global Server Administrators` eligible for every
computer below `OU=Servers`. The additional child delegation makes `SQL-Admins`
eligible for computers below `OU=SQL,OU=Servers`.
