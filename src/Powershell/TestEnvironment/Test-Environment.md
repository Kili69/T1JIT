# T1JIT Active Directory Test Environment

The `New-T1JitTestEnvironment.ps1` script creates Active Directory objects for
functional and delegation tests. It is not part of the release package and must
only be used in a disposable test domain.

The script prints its version immediately after startup. The current script
version is `0.1.20260824`.

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

By default, each child OU contains three disabled computer accounts. Computer
names use the role prefix and a sequence number, for example `APP1-SRV01`,
`FILE-SRV01`, `TERM-SRV01`, and `SQL-SRV01`. Each account receives:

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

Create five computers per OU with a different Windows Server version:

```powershell
.\New-T1JitTestEnvironment.ps1 `
    -ComputerCountPerOU 5 `
    -WindowsServerVersion 2025
```

The script is idempotent. Existing OUs and groups are reused. Existing computer
accounts receive the configured `OperatingSystem` and `DNSHostName` values. No
objects are deleted, and newly created computer accounts remain disabled.
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
