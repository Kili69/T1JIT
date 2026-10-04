# Changelog

This file describes **user- and administrator-facing changes** to T1JIT: new features, behavior changes, and fixes that matter when installing, updating, or operating the Just-In-Time solution and the KJIT-Web service.

This is different from [`History.md`](History.md), which is an automatically generated, per-push audit log of raw commits and changed files created by `build/Push-GitHub.ps1`.
`History.md` answers "what was pushed and when"; this file answers "what changed for me as a user of T1JIT, and why does it matter".

Versions follow this repository's scheme `<Major>.<Minor>.<yyyyMMdd>.<Counter>` (see `build/Update-Version.ps1`), for example `0.2.20260925.3`. Every commit adds its change below `Unreleased`; the pre-commit hook moves those entries into the generated version section automatically.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [0.2.20261004.11] - 2026-10-04
### Changed

- Promoted the validated development changes to the production branch while excluding development-only test-environment scripts.

## [0.2.20261004.10] - 2026-10-04
### Changed

- Documented 1 outgoing commit(s) in `History.md` before the GitHub push.

## [0.2.20261004.9] - 2026-10-04
### Changed

- KjitWeb now places Switch user, language selection, and the compact About action in a low-emphasis utility bar below the branded header; the configurable branding logo remains at the far right and defaults to the bundled `kjitlogo.png`.

## [0.2.20261004.8] - 2026-10-04
### Changed

- Documented 9 outgoing commit(s) in `History.md` before the GitHub push.

## [0.2.20261004.7] - 2026-10-04
### Fixed

- The GitHub pre-push hook now recognizes the automatically versioned `CHANGELOG.md` and `README.md` as valid metadata in documented history commits.

## [0.2.20261004.6] - 2026-10-04
### Changed

- Documented 7 outgoing commit(s) in `History.md` before the GitHub push.

## [0.2.20261004.5] - 2026-10-04
### Added

- KjitWeb now provides an extensible modern menu in the top bar, starting with a localized About dialog that shows the application version, license, author contact and GitHub profile picture, plus links to the repository and its contributors.

### Changed

- Reworked the complete README into a consistent procedural style with standardized T1JIT/KjitWeb terminology, headings, parameter lists, PowerShell examples, installation guidance, and current cmdlet signatures. The monitoring section now links to the authoritative `EVENTS.md` reference, and redundant usage and historical text was removed.

## [0.2.20261004.4] - 2026-10-04
### Fixed

- Version validation now excludes the generated `release/` tree, matching pre-commit version generation and avoiding stale-manifest failures for derived binaries and recursive release metadata.

## [0.2.20261004.3] - 2026-10-04
### Fixed

- Changelog version validation now accepts the repository's Windows `CRLF` line endings.

## [0.2.20261004.2] - 2026-10-04
Changes merged into `dev` since the last published release (`v0.1.20260908.12`), not yet published as a GitHub release.

### Added

- KjitWeb now lists only delegated servers whose matching JIT administrator group exists and displays each selectable server by its fully qualified DNS name.
- Added a packaged [`GroupPolicy`](GroupPolicy/README.md) example that creates and links
  one complete policy per configured domain. It reads naming and server-OU settings from
  the active JIT configuration and adds each server-specific T1JIT AD group to the
  language-neutral built-in local Administrators group. The preference resolves the
  central group-account domain from `AdminGroupOU` and writes a domain-qualified
  `NETBIOS\GroupName` member reference. The installer copies the provisioning script to
  the Just-In-Time program folder and displays the required Domain Administrator or
  Group Policy Creator Owners follow-up action when installation completes. The script
  generates its Group Policy Preferences XML internally and no longer ships a separate
  XML template. Its optional `-Domain` parameter provisions only one configured domain;
  without it, multi-domain environments still process every forest domain. Per-domain
  permission failures now produce an actionable retry warning and do not prevent the
  remaining domains from being processed.
- Installation package creation now always runs Pester unit tests against the packaged PowerShell modules and aborts before creating a ZIP if manifest, syntax, or `Get-JITConfig` compatibility tests fail.
- Release packages are now a single ZIP + `.sha256` checksum (`T1JIT-<Version>-<Branch>.zip`).
- `update-kjitweb.ps1` updates an existing KJIT-Web installation in place (rollback backup, preserves `appsettings*.json`/`app_data`). `install-JIT.ps1` now detects an existing Just-In-Time/KjitWeb installation and updates it in place instead of re-running the full setup wizard, only prompting for settings introduced since the last configuration. Run the installed `Config-JIT.ps1 -AdvancedSetup` separately to review the complete configuration.
- New installations automatically delegate the domain's Domain Admins group on every search base (also applied by `Add-JitServerOU`), so JIT elevation works without a manual `Add-JitDelegation` call.
- Added [`EVENTS.md`](EVENTS.md), a consolidated reference of every Windows Event Log ID written by T1JIT, linked from the README's new [Event Reference](README.md#event-reference) section.
- The KjitWeb footer now shows a warning indicator when Error/Warning entries were logged to the Tier 1 Management event log in the last 24 hours.
- Added `set-kjitweb-allowedclient.ps1` to change which client(s) may reach an installed KjitWeb service without a full reinstall; see [Restricting which clients can reach KjitWeb (AllowedClient)](README.md#restricting-which-clients-can-reach-kjitweb-allowedclient).
- `set-kjitweb-allowedclient.ps1` now accepts multiple IPv4/IPv6 addresses and CIDR
  subnets from parameters or the pipeline and returns the resulting allow lists as an
  object. Loopback and all active local IPv4/IPv6 interface addresses are always included
  in the effective allow list. Added `get-kjitweb-allowedclient.ps1` to list the effective
  firewall addresses and display its script version when invoked.
- `set-kjitweb-allowedclient.ps1` supports `-Add`, `-Remove`, and `-WhatIf` for safely
  previewing and incrementally changing the configured allow list.
- `install-kjitweb.ps1`, `update-kjitweb.ps1`, and `set-kjitweb-allowedclient.ps1` now automatically register the required Kerberos SPNs on the server's computer account for remote access, writing a clear warning with the manual `setspn -A` command if the account lacks permission (previously only documented in [docs/Kerberos-Setup.md](docs/Kerberos-Setup.md)). `Config-JIT.ps1` likewise warns clearly, instead of aborting, if it lacks permission to grant the GMSA its OU delegation.
- The management scripts (`install-kjitweb.ps1`, `update-kjitweb.ps1`, `set-kjitweb-allowedclient.ps1`) are now copied into the KjitWeb installation folder alongside the service binaries, so they remain available after setup.

### Fixed

- Scheduled tasks now register the gMSA with the non-interactive `Password` logon type and automatically repair existing JIT tasks whose principal was stored as `(NONE)`, `ServiceAccount`, or another incompatible logon type.
- KjitWeb management scripts now remove IPv6 interface scope IDs (for example `%5`) before creating Windows Firewall rules and treat firewall creation failures as fatal instead of reporting a false success.
- Fixed `set-kjitweb-allowedclient.ps1` rejecting multiple `-AllowedClient` values while
  persisting the normalized value to `appsettings*.json`.
- KjitWeb management scripts no longer pass IPv4/IPv6 loopback addresses to
  `New-NetFirewallRule`, which rejects IPv6 loopback addresses. Loopback remains available
  locally and is included in the effective output.
- `get-kjitweb-allowedclient.ps1` now understands the subnet-mask notation returned by
  Windows Firewall (for example `/255.255.255.0`) and displays it as the equivalent CIDR
  prefix (`/24`) instead of failing.
- KjitWeb AllowedClient management now rejects malformed IP-like values and invalid DNS
  hostnames before attempting DNS resolution, with examples of accepted input formats.
- JIT delegation commands now stop with the configuration source and root loading error when `JIT.config` is invalid, instead of emitting a second, misleading `Test-Path` error for a null delegation path.
- `Get-JitConfig` now resolves the supported `<DomainRoot>` placeholder and relative `T1Searchbase` entries to full distinguished names instead of rejecting configurations generated by `Config-JIT.ps1`.
- `Get-JitConfig` once again accepts the simple `Tier0ServerGroupName` generated by unattended/default configuration, while continuing to accept a full group distinguished name.
- The PowerShell module manifest now reports the package version instead of the stale `0.1.20260907.42` value, and version generation keeps it synchronized for future releases.
- Documented pushes are no longer rejected when the generated history commit also synchronizes the PowerShell module version.
- `install-JIT.ps1` fails fast with an actionable error instead of a raw exception when updating while `KjitCore.dll` is still loaded elsewhere.
- `update-kjitweb.ps1` now also enforces the `NetworkService` service account and repairs the Windows Firewall rule for the configured `AllowedClient` on every update, matching `install-kjitweb.ps1`.
- KjitWeb is now hosted on **HTTP.sys** instead of Kestrel, fixing Windows Authentication (Negotiate/Kerberos/NTLM) breaking under the `NetworkService` account; SPNs are registered on the server's computer account instead of a dedicated service account, and the HTTP.sys URL namespace is reserved for `NetworkService` via `netsh http add urlacl`.
- Fixed `sc.exe exited with code 1639` when setting the KjitWeb service account, by using the `Win32_Service.Change()` CIM method instead of `sc.exe`.
- **Security fix**: local-system-only KjitWeb (`AllowedClient` = `localhost`) uses a
  Windows Firewall rule restricted to loopback and the server's active local addresses.
  HTTP.sys can therefore serve every local address without allowing other systems; existing
  localhost-only bindings are migrated automatically on the next update.

### Changed

- Every commit must now include a staged changelog entry. The pre-commit hook stamps pending `Unreleased` entries with the generated version and date, version validation rejects a changelog whose latest version differs from `VERSION`, and the documented-push script creates the entry for its automatic history commit.
- Relicensed the project from the MIT License to the Apache License 2.0, centralized the
  warranty disclaimer in the README, and included the license in release packages.
- Separated developer, build, versioning, release, and contribution information into [`Developer.md`](Developer.md), leaving the README focused on installation, configuration, and operation.
- Added complete API documentation, author attribution, and file-level version history to `KjitCore.cs`.
- Added complete contract and return-value documentation, author attribution, and version history to `IDistinguishedNameService.cs`.
- Completed file headers and XML API documentation across all C# source files; builds now reject missing or malformed XML documentation.
- Completed comment-based help, author attribution, and version history for every function in all four PowerShell module files; package tests now enforce this documentation coverage.
- Renamed the KJIT-Web release output folder from `release/kjibweb` to `release/kJITWeb`.

## [0.2.20260927.3] - 2026-09-27

### Added

- `set-kjitweb-allowedclient.ps1` now accepts multiple IPv4/IPv6 addresses and CIDR
  subnets from parameters or the pipeline and returns the resulting allow lists as an
  object. Loopback and all active local IPv4/IPv6 interface addresses are always included
  in the effective allow list. Added `get-kjitweb-allowedclient.ps1` to list the effective
  firewall addresses and display its script version when invoked.
- `set-kjitweb-allowedclient.ps1` supports `-Add`, `-Remove`, and `-WhatIf` for safely
  previewing and incrementally changing the configured allow list.

### Fixed

- Fixed `set-kjitweb-allowedclient.ps1` rejecting multiple `-AllowedClient` values while
  persisting the normalized value to `appsettings*.json`.
- KjitWeb management scripts no longer pass IPv4/IPv6 loopback addresses to
  `New-NetFirewallRule`, which rejects IPv6 loopback addresses. Loopback remains available
  locally and is included in the effective output.
- `get-kjitweb-allowedclient.ps1` now understands the subnet-mask notation returned by
  Windows Firewall (for example `/255.255.255.0`) and displays it as the equivalent CIDR
  prefix (`/24`) instead of failing.
- KjitWeb AllowedClient management now rejects malformed IP-like values and invalid DNS
  hostnames before attempting DNS resolution, with examples of accepted input formats.
- Local-system-only KjitWeb (`AllowedClient = localhost`) uses a Windows Firewall rule
  restricted to the server's active local addresses. HTTP.sys can therefore serve every
  local address without allowing other systems; existing localhost-only bindings are
  migrated automatically on the next update.

## [0.2.20260926.22] - 2026-09-26

Changes promoted from `dev` to `main` since the last published release
(`v0.1.20260908.12`).

### Added

- Installation package creation now always runs Pester unit tests against the packaged PowerShell modules and aborts before creating a ZIP if manifest, syntax, or `Get-JITConfig` compatibility tests fail.
- Release packages are now a single ZIP + `.sha256` checksum (`T1JIT-<Version>-<Branch>.zip`).
- `update-kjitweb.ps1` updates an existing KJIT-Web installation in place (rollback backup, preserves `appsettings*.json`/`app_data`). `install-JIT.ps1` now detects an existing Just-In-Time/KjitWeb installation and updates it in place instead of re-running the full setup wizard, only prompting for settings introduced since the last configuration. Run the installed `Config-JIT.ps1 -AdvancedSetup` separately to review the complete configuration.
- New installations automatically delegate the domain's Domain Admins group on every search base (also applied by `Add-JitServerOU`), so JIT elevation works without a manual `Add-JitDelegation` call.
- Added [`EVENTS.md`](EVENTS.md), a consolidated reference of every Windows Event Log ID written by T1JIT, linked from the README's new [Event Reference](README.md#event-reference) section.
- The KjitWeb footer now shows a warning indicator when Error/Warning entries were logged to the Tier 1 Management event log in the last 24 hours.
- Added `set-kjitweb-allowedclient.ps1` to change which client(s) may reach an installed KjitWeb service without a full reinstall; see [Restricting which clients can reach KjitWeb (AllowedClient)](README.md#restricting-which-clients-can-reach-kjitweb-allowedclient).
- `install-kjitweb.ps1`, `update-kjitweb.ps1`, and `set-kjitweb-allowedclient.ps1` now automatically register the required Kerberos SPNs on the server's computer account for remote access, writing a clear warning with the manual `setspn -A` command if the account lacks permission (previously only documented in [docs/Kerberos-Setup.md](docs/Kerberos-Setup.md)). `Config-JIT.ps1` likewise warns clearly, instead of aborting, if it lacks permission to grant the GMSA its OU delegation.
- The management scripts (`install-kjitweb.ps1`, `update-kjitweb.ps1`, `set-kjitweb-allowedclient.ps1`) are now copied into the KjitWeb installation folder alongside the service binaries, so they remain available after setup.

### Fixed

- KjitWeb management scripts now remove IPv6 interface scope IDs (for example `%5`) before creating Windows Firewall rules and treat firewall creation failures as fatal instead of reporting a false success.
- JIT delegation commands now stop with the configuration source and root loading error when `JIT.config` is invalid, instead of emitting a second, misleading `Test-Path` error for a null delegation path.
- `Get-JitConfig` now resolves the supported `<DomainRoot>` placeholder and relative `T1Searchbase` entries to full distinguished names instead of rejecting configurations generated by `Config-JIT.ps1`.
- `Get-JitConfig` once again accepts the simple `Tier0ServerGroupName` generated by unattended/default configuration, while continuing to accept a full group distinguished name.
- The PowerShell module manifest now reports the package version instead of the stale `0.1.20260907.42` value, and version generation keeps it synchronized for future releases.
- Documented pushes are no longer rejected when the generated history commit also synchronizes the PowerShell module version.
- `install-JIT.ps1` fails fast with an actionable error instead of a raw exception when updating while `KjitCore.dll` is still loaded elsewhere.
- `update-kjitweb.ps1` now also enforces the `NetworkService` service account and repairs the Windows Firewall rule for the configured `AllowedClient` on every update, matching `install-kjitweb.ps1`.
- KjitWeb is now hosted on **HTTP.sys** instead of Kestrel, fixing Windows Authentication (Negotiate/Kerberos/NTLM) breaking under the `NetworkService` account; SPNs are registered on the server's computer account instead of a dedicated service account, and the HTTP.sys URL namespace is reserved for `NetworkService` via `netsh http add urlacl`.
- Fixed `sc.exe exited with code 1639` when setting the KjitWeb service account, by using the `Win32_Service.Change()` CIM method instead of `sc.exe`.
- **Security fix**: loopback-only KjitWeb (`AllowedClient` = `localhost`) no longer actually restricted network access after the HTTP.sys migration, since HTTP.sys only matched the `Host` header while still listening on all interfaces. Loopback-only installations now bind to `http://127.0.0.1:<port>`/`http://[::1]:<port>` instead, restoring true isolation; existing installations are migrated automatically on the next `update-kjitweb.ps1` run.

### Changed

- Separated developer, build, versioning, release, and contribution information into [`Developer.md`](Developer.md), leaving the README focused on installation, configuration, and operation.
- Added complete API documentation, author attribution, and file-level version history to `KjitCore.cs`.
- Added complete contract and return-value documentation, author attribution, and version history to `IDistinguishedNameService.cs`.
- Completed file headers and XML API documentation across all C# source files; builds now reject missing or malformed XML documentation.
- Completed comment-based help, author attribution, and version history for every function in all four PowerShell module files; package tests now enforce this documentation coverage.
- Renamed the KJIT-Web release output folder from `release/kjibweb` to `release/kJITWeb`.

## [0.1.20260908.12] - 2026-09-08

### Fixed

- Fixed KjitWeb delegation resolution and relative search-base handling.

### Changed

- Automated the release build as part of the versioning workflow.

## [0.1.20260908.9] - 2026-09-08

### Fixed

- Prevented KjitWeb from reading transient/incomplete delegation configuration, which could otherwise apply stale settings.

## [0.1.20260908.7] - 2026-09-08

### Security

- Hardened KjitWeb access control and logging.

### Fixed

- Hardened JIT provisioning and request handling against invalid input.

## [0.1.20260908.3] - 2026-09-08

### Documentation

- Documented the `Config-JIT.ps1` configuration workflow.

## [0.1.20260907.50] - 2026-09-07

### Added

- KjitWeb now shows its version number in the page footer. 
- Added a repeatable, automated test installation for the JIT module (`src/Powershell/TestEnvironment`).

### Changed

- Improved multi-domain search diagnostics to make configuration problems easier to diagnose.
- Improved PowerShell module documentation and configuration guidance.

### Fixed

- Hardened JIT installation and diagnostics.
- Fixed a PowerShell module runtime compatibility issue.

## [0.1.20260907.34] and earlier

The first tagged pre-release (`v0.1.20260907.34-test`) covers the entire project history up to that point, including the original request-based Tier-1 delegation model, the KjitWeb service, the PowerShell configuration modules, and ongoing documentation and version-numbering improvements. Individual changes from this period were not tracked in
this changelog; see `git log` and `History.md` for full detail.
