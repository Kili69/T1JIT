# T1JIT Event Reference

This file is the **single, consolidated reference for every Windows Event Log entry**
written by T1JIT (PowerShell scripts, modules, and the KJIT-Web service). Event IDs and
their meaning were previously scattered across comment-based help blocks in individual
scripts; this document brings them together in one place so administrators can look up
an event by ID without having to open the source code.

For general installation, configuration, and update instructions see [README.md](README.md).
For version history of the code itself see [CHANGELOG.md](CHANGELOG.md) (user-facing) and
[History.md](History.md) (raw commit log).

## Event logs and sources used by T1JIT

| Component | Windows Event Log | Event Source | Configurable via |
|---|---|---|---|
| `ElevateUser.ps1` (elevation processor, runs as scheduled task) | `$config.EventLog` (default `Tier 1 Management`) | hardcoded `T1Mgmt` | `EventLog` in `JIT.config` |
| `New-AdminRequest` in `just-in-time-request.psm1` (used by `RequestAdminAccessUI.ps1` and the PowerShell request cmdlets) | `$config.EventLog` (default `Tier 1 Management`) | `$config.EventSource` (default `T1Mgmt`) | `EventLog` / `EventSource` in `JIT.config` |
| KJIT-Web service, elevation request (`EventLogWriter.cs`) | `$config.EventLog` (default `Tier 1 Management`) | `$config.EventSource` (default `T1Mgmt`) | `EventLog` / `EventSource` in `JIT.config` |
| KJIT-Web service, startup diagnostics (`Program.cs`) | `Application` | `KjitWeb` (falls back to `.NET Runtime` if the source cannot be created) | not configurable |
| `Tier1LocalAdminGroup.ps1`, group management outcome | `$config.EventLog` (default `Tier 1 Management`) | `$config.EventSource` (default `T1Mgmt`) | `EventLog` / `EventSource` in `JIT.config` |
| `Tier1LocalAdminGroup.ps1`, script-level diagnostics | `Application` | `T1JIT Tier1LocalAdminGroup` | not configurable |
| `Config-JIT.ps1` / `Config-JITUI.ps1`, one-time setup marker | `$Configuration.EventLog` (default `Tier 1 Management`) | `$Configuration.EventSource` (default `T1Mgmt`) | `EventLog` / `EventSource` in `JIT.config` |

The `Tier 1 Management` event log and the `T1Mgmt` source are created once during
installation/configuration (`Config-JIT.ps1`/`Config-JITUI.ps1`); the `Application`-log
sources (`KjitWeb`, `T1JIT Tier1LocalAdminGroup`) are created on demand the first time
they are needed and require the writing process to have sufficient rights (see
[README.md](README.md) for the service account used by KJIT-Web).

## `Tier 1 Management` log — elevation request (event ID 100 by default)

The elevation request itself is **not** a fixed event ID — it is written with whatever
ID is configured as `ElevateEventID` in `JIT.config` (default: `100`). Both
`New-AdminRequest` (PowerShell UI / cmdlet path) and the KJIT-Web service
(`EventLogWriter.WriteManagementEvent`, hardcoded `ManagementEventId = 100`) write this
event; a scheduled task (created by `Config-JIT.ps1`) is triggered by this exact event
ID/log combination and calls `ElevateUser.ps1` to process the request.

| Event ID (default) | Severity | Meaning |
|---|---|---|
| 100 (`ElevateEventID`) | Information | A JIT elevation request was submitted. The message body is a JSON payload with `UserDN`, `ServerGroup`, `ServerDomain`, `ElevationTime`, and `CallingUser`. This event is consumed by `ElevateUser.ps1`, not meant for direct reading by administrators. |

> If `ElevateEventID` is changed from its default in `JIT.config`, the scheduled task
> trigger and both writers automatically use the new value — the event ID below is only
> the shipped default.

## `Tier 1 Management` log — `ElevateUser.ps1` (elevation processor)

| Event ID | Severity | Meaning |
|---|---|---|
| 1 | Error | An unexpected/unhandled error occurred while processing an elevation request. Message includes the request ID, the exception, and the failing line number. *(Note: this ID overlaps with the one-time "JIT configuration created" marker below — see [Known event ID overlaps](#known-event-id-overlaps-and-documentation-gaps).)* |
| 2000 | Error | The configuration file (`JIT.config`) is missing. The elevation request is aborted. |
| 2001 | Error | The Active Directory group required for elevation (`ServerGroup` from the request) could not be found. Validate that `Tier1LocalAdminGroup.ps1` ran without error for the target server. |
| 2002 | Warning | The requesting user could not be found in Active Directory (searched forest-wide via Global Catalog), or the user has neither a UPN nor a canonical name. |
| 2003 | Warning | The requested elevation time exceeds `MaxElevatedTime`; the time-to-live is capped to the configured maximum. |
| 2004 | Information | The user is already a member of the target admin group; the time-to-live is refreshed instead of adding a duplicate membership. |
| 2005 | Error | The configuration file's build version is older than the version required by this script. Re-run `Config-JIT.ps1` to update it. |
| 2006 | Warning | No event with the requested record ID exists in the configured event log/`ElevateEventID` — the request could not be located. |
| 2007 | Error | An Active Directory exception occurred while processing the request (see the logged exception for details). |
| 2009 | Warning | The requesting user exceeded `MaxConcurrentServer` (too many concurrent elevated server memberships). |
| 2100 | Warning | The target server object could not be found in Active Directory. |
| 2103 | Warning | Delegation is enabled, and the requesting user is not covered by any matching delegation entry for the target server/OU. |
| 2104 | Information | The user was successfully added to the local administrators group (via AD group membership) for the requested duration. |
| 2105 | Error | A Global Catalog / domain controller was unreachable (`ADServerDownException`). |
| 2106 | Information | Script start marker; message contains the request ID and the path to the detailed debug log for this run. |
| 2109 | Error | `EnableDelegation` is set but `DelegationConfigPath` does not point to an accessible file. |

### Documented but not currently emitted

The comment-based help in `ElevateUser.ps1` also lists the following IDs; they are **not
written by any code path in the current version** and are kept here only so the numbers
are not accidentally reused for something else in the future:

| Event ID | Documented meaning |
|---|---|
| 2008 | Warning — user elevation throttled, waiting for removal from admin groups. |
| 2101 | Error — the delegation JSON file (`delegation.config`) is not available. |
| 2102 | Error — the target server's OU path is not defined in `delegation.config`. |
| 2107/2007 (duplicate ID in source comment, likely a typo for 2107) | Error — the AD object class referenced by the `ManagedBy` attribute is not supported. |
| 2108 | Error — the configured `Delegation.config` path is invalid. |

## `Tier 1 Management` log — `Tier1LocalAdminGroup.ps1` (group provisioning outcome)

Written with `$config.EventLog`/`$config.EventSource` (default `Tier 1 Management`/`T1Mgmt`):

| Event ID | Severity | Meaning |
|---|---|---|
| 1000 | Information | A new local-admin-equivalent group (`$GroupName`) was created for a Tier 1 server. |
| 1001 | Error | Creating the local-admin-equivalent group failed. |
| 1002 | Warning | A permanently assigned member was removed from the group during reconciliation. |
| 1003 | Error | Removing a permanent member from the group failed. |
| 1004 | Warning | A configured search-base OU could not be found in the domain. |

### Documented but not currently emitted

| Event ID | Documented meaning |
|---|---|
| 1100 | Error — configuration file missing. In the current version this condition instead terminates the script with exit code `0x3E8`/`0x3EA` without writing this event ID. |

## `Application` log — `Tier1LocalAdminGroup.ps1` (script-level diagnostics)

Written with a dedicated source, `T1JIT Tier1LocalAdminGroup` (registered automatically
on first use, and pre-registered by `Config-JIT.ps1`):

| Event ID | Severity | Meaning |
|---|---|---|
| 3100 | Information | Script started; message contains the path to the per-run debug transcript. |
| 3101 | Error | The computer search (discovering Tier 1 member servers) failed; message contains the path to the debug transcript for details. |

## `Application` log — KJIT-Web service startup (`Program.cs`)

Written with source `KjitWeb` (falls back to the built-in `.NET Runtime` source if the
`KjitWeb` source cannot be created, e.g. due to insufficient rights — the service always
runs under `NetworkService`, see [README.md](README.md)):

| Event ID | Severity | Meaning |
|---|---|---|
| 5000 | Error | The KJIT-Web service failed to start. Message contains the full exception. Use this to diagnose misconfiguration (e.g. invalid `JIT.config`, missing `T1Searchbase`, or missing `EventLogSource`). |
| 5001 | Information | The KJIT-Web service started successfully. Message contains the resolved debug-log path. |

## `Tier 1 Management` log — one-time setup marker (`Config-JIT.ps1` / `Config-JITUI.ps1`)

| Event ID | Severity | Meaning |
|---|---|---|
| 1 | Information | Written exactly once, when the `Tier 1 Management` event log and its `T1Mgmt` source are created for the first time during initial configuration. Message: "JIT configuration created". *(Note: this ID overlaps with `ElevateUser.ps1`'s "unexpected error" event — see below.)* |

## KjitWeb website health indicator

The KjitWeb website shows a symbol next to the version number in the footer (`⚠` orange
for Warning, `⛔` red for Error) whenever a qualifying entry was logged to the configured
`EventLog` (default `Tier 1 Management`) within the last 24 hours. The check
(`EventLogHealthMonitor` in `src/C#/Kjitweb/Services`) runs in the background every 5
minutes; the browser polls `GET /Home/EventLogHealthStatus` on the same interval to keep
the indicator current without a page reload.

Event IDs **2003** and **2009** are always excluded from this check, because they are
routine Warning-level events raised by `ElevateUser.ps1` during normal operation
(elevation time capped to the configured maximum, and a user exceeding
`MaxConcurrentServer`, respectively — see the table above) rather than actionable
problems. All other Error or Warning entries in the log count towards the indicator.

## Known event ID overlaps and documentation gaps

- **Event ID 1** is used both for the one-time "JIT configuration created" marker
  (`Config-JIT.ps1`/`Config-JITUI.ps1`, `EntryType Information`) and for "an unexpected
  error occurred" in `ElevateUser.ps1` (`EntryType Error`). Both use the same log
  (`Tier 1 Management`) and source (`T1Mgmt`). Distinguish them by **entry type** and by
  the message text ("JIT configuration created" vs. "a unexpected Error has occured").
- Several event IDs referenced in older comment-based help blocks (`1100`, `2008`,
  `2101`, `2102`, `2108`, and the likely-mistyped `2007`/`2107` duplicate) are not
  currently written by any code path. They are listed above for completeness so the
  numbers are not silently reused for a different meaning later.

## Maintaining this file

When adding a new `Write-EventLog` / `EventLog.WriteEntry` call (or changing the meaning
of an existing event ID), update the corresponding table in this file in the same change,
and add a short note to [CHANGELOG.md](CHANGELOG.md) if the change is user-visible (e.g. a
new event administrators should monitor for).
