# T1JIT Active Directory Test Environment

The `New-T1JitTestEnvironment.ps1` script creates Active Directory objects for
functional and delegation tests. It is not part of the release package and must
only be used in a disposable test domain.

## Created Structure

The script creates the base OU `OU=Server` below the current domain root. The
following child OUs are created:

- `Application1` through `Application10`
- `File-Server`
- `Terminal-Server`
- `SQL`

By default, each child OU contains three disabled computer accounts. Computer
names use the role prefix and a sequence number, for example `APP1-SRV01`,
`FILE-SRV01`, `TERM-SRV01`, and `SQL-SRV01`. Each account receives:

- `OperatingSystem`: `Windows Server 2022`
- `DNSHostName`: `<computer-name>.<domain-dns-name>`

The base OU contains the independent security group `Server-Administrator`.
Each child OU contains an independent group named
`Server-Administrator-<OU name>`. The script does not create memberships between
these groups.

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
