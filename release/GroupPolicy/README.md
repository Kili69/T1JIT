# T1JIT local-administrator Group Policy provisioning

T1JIT creates a domain-local AD security group for every managed server. Windows does
not grant that group local administrator rights automatically. A computer Group Policy
must add the matching AD group to the server's built-in local Administrators group.

The script loads the active JIT configuration and creates a complete GPO directly in
Active Directory and SYSVOL for every configured domain. The required Group Policy
Preferences XML is generated directly in the script by `New-T1JitGroupsXml`; no separate
XML template or manual import is required.

This directory contains:

- `New-T1JitLocalAdministratorsGpo.ps1`: creates one complete GPO per configured domain
  and links it to matching configured server OUs.

The main T1JIT installer copies `New-T1JitLocalAdministratorsGpo.ps1` directly to:

```text
%ProgramFiles%\Just-In-Time\New-T1JitLocalAdministratorsGpo.ps1
```

The script prints its own version when it starts. Full comment-based help is available:

```powershell
Get-Help "$env:ProgramFiles\Just-In-Time\New-T1JitLocalAdministratorsGpo.ps1" -Full
```

## Generated preference

The policy uses:

- **Computer Configuration**
- **Preferences**
- **Control Panel Settings**
- **Local Users and Groups**
- **Update** the built-in Administrators group
- local group SID `S-1-5-32-544`, so the policy is independent of the operating-system
  display language
- **Add** the T1JIT AD group without deleting existing local users or groups

`AdminPreFix`, `DomainSeparator`, `EnableMultiDomainSupport`, `Domain`,
`AdminGroupOU`, and `T1Searchbase` are loaded through `Get-JITConfig`. The domain
containing `AdminGroupOU` is always included as the account-domain prefix. The default
T1JIT configuration with the groups stored in the `CONTOSO` domain therefore uses:

```text
CONTOSO\Admin_%AD-DNSDomainName%#%ComputerName%
```

For server `SRV01` in `contoso.com`, this resolves to:

```text
CONTOSO\Admin_contoso.com#SRV01
```

If `EnableMultiDomainSupport` is disabled in `JIT.config`, use:

```text
CONTOSO\Admin_%ComputerName%
```

`CONTOSO` is an example. The script derives the actual NetBIOS account-domain name from
the `DC=` components of `AdminGroupOU` and resolves it through Active Directory. This is
important in multi-domain forests: `%AD-DNSDomainName%` identifies the managed server's
domain as part of the JIT group name, while the prefix before `\` identifies the central
domain where that group object was created.

`-AdminPrefix` and `-DomainSeparator` are optional overrides. Normally, do not specify
them; the values from `JIT.config` are used automatically.

## Domain and OU handling

When `EnableMultiDomainSupport` is enabled, the script enumerates all domains in the
configured forest and creates one GPO per domain:

```text
T1JIT - Local Administrators - contoso.com
T1JIT - Local Administrators - child.contoso.com
```

Use `-Domain` to process only one of these configured domains:

```powershell
.\New-T1JitLocalAdministratorsGpo.ps1 -Domain 'child.contoso.com'
```

The value is validated against the domains discovered from the active JIT configuration.
An unrelated or misspelled domain is rejected before any GPO is changed.

Full and relative OU distinguished names in `T1Searchbase` are matched to the appropriate
domain and used as GPO link targets.

`<DomainRoot>` requires special care: linking a computer GPO at the domain root can affect
every computer in the domain, not only T1JIT servers. The script therefore creates the
complete domain GPO but leaves it unlinked unless `-LinkDomainRoot` is explicitly supplied.

## Create complete domain GPOs

Run the script in an elevated Windows PowerShell 5.1 session on a management computer
with the Group Policy Management, Active Directory, and T1JIT PowerShell modules
installed. The executing account requires GPO and SYSVOL permissions in every configured
domain. Run it as a Domain Administrator or as a member of **Group Policy Creator Owners**
that also has permission to link GPOs to the configured server OUs.

After a normal installation, start with:

```powershell
& "$env:ProgramFiles\Just-In-Time\New-T1JitLocalAdministratorsGpo.ps1" -WhatIf -Verbose
```

Preview the operation first:

```powershell
.\New-T1JitLocalAdministratorsGpo.ps1 -WhatIf
```

Display detailed configuration, domain, SYSVOL, and GPO-link information:

```powershell
.\New-T1JitLocalAdministratorsGpo.ps1 -Verbose
```

Combine both parameters for a detailed preview without changing Active Directory or
SYSVOL:

```powershell
.\New-T1JitLocalAdministratorsGpo.ps1 -WhatIf -Verbose
```

`-Verbose` and `-WhatIf` are PowerShell common parameters supplied by the script's
advanced-function declaration. `-WhatIf` still loads the configuration and validates
domains and target OUs, but it does not create or update a GPO, write SYSVOL files, or
create GPO links.

Create a complete policy in every configured domain and link it to the configured
`T1Searchbase` OUs:

```powershell
.\New-T1JitLocalAdministratorsGpo.ps1
```

If the current account lacks GPO, SYSVOL, or link permissions in one domain, the script
issues a warning, marks that domain as `Applied = False` with `Error = PermissionDenied`,
and continues with the remaining domains. The warning includes the retry command:

```powershell
.\New-T1JitLocalAdministratorsGpo.ps1 -Domain 'child.contoso.com'
```

Run that command with credentials authorized in the affected domain. Non-permission
failures still stop the script so configuration, connectivity, or XML errors are not hidden.

Load an explicit JIT configuration:

```powershell
.\New-T1JitLocalAdministratorsGpo.ps1 `
    -ConfigurationFile '\\contoso.com\SYSVOL\contoso.com\Just-In-Time\JIT.config'
```

Override the naming values only when intentionally different from `JIT.config`:

```powershell
.\New-T1JitLocalAdministratorsGpo.ps1 `
    -AdminPrefix 'T1Admin_' `
    -DomainSeparator '-'
```

Explicitly permit domain-root links when `<DomainRoot>` is configured:

```powershell
.\New-T1JitLocalAdministratorsGpo.ps1 -LinkDomainRoot
```

When a domain GPO already exists, the script displays a warning and asks whether its Local
Users and Groups preference should be overwritten. Answering **No** leaves the GPO unchanged
and returns an output object with `Applied = False`.

Use `-Force` only after reviewing the existing policy. It replaces the existing GPO's Local
Users and Groups `Groups.xml` without another confirmation prompt:

```powershell
.\New-T1JitLocalAdministratorsGpo.ps1 -Force
```

`-Force -WhatIf` remains a non-changing preview and does not create or update a GPO.

## Equivalent manual creation in GPMC

The equivalent manual configuration is:

1. Create a GPO named **T1JIT - Local Administrators**.
2. Edit **Computer Configuration > Preferences > Control Panel Settings > Local Users
   and Groups**.
3. Add a **Local Group** preference with action **Update**.
4. Select the built-in **Administrators (built-in)** group.
5. Do not enable either option that deletes existing users or groups.
6. Add `CONTOSO\Admin_%AD-DNSDomainName%#%ComputerName%` as a member, or use
   `CONTOSO\Admin_%ComputerName%` when multi-domain support is disabled. Replace
   `CONTOSO` with the NetBIOS name of the domain containing `AdminGroupOU`.
7. Repeat this in every configured domain.
8. Link each domain GPO only to OUs containing T1JIT-managed server computer objects.

## Validate before production rollout

Test the policy in a non-production OU first:

```powershell
gpupdate.exe /force
gpresult.exe /scope computer /r
Get-LocalGroupMember -SID 'S-1-5-32-544'
```

Confirm that:

- the expected server-specific T1JIT group exists in Active Directory;
- the dynamic name resolves to that exact group;
- the group appears in the local Administrators group;
- unrelated local Administrators members remain unchanged;
- the GPO is linked only to intended server OUs.

Do not link this example to domain controllers or broad workstation OUs. Review normal
GPO security filtering, delegation, change control, and SYSVOL replication requirements
for the environment before production deployment.
