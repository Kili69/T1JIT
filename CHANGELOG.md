# Changelog

This file describes **user- and administrator-facing changes** to T1JIT: new features, behavior changes, and fixes that matter when installing, updating, or operating the Just-In-Time solution and the KJIT-Web service.

This is different from [`History.md`](History.md), which is an automatically generated, per-push audit log of raw commits and changed files created by `build/Push-GitHub.ps1`.
`History.md` answers "what was pushed and when"; this file answers "what changed for me as a user of T1JIT, and why does it matter".

Versions follow this repository's scheme `<Major>.<Minor>.<yyyyMMdd>.<Counter>` (see `build/Update-Version.ps1`), for example `0.1.20260925.3`. Update this file as part of [creating a release](README.md#creating-a-release), before publishing the corresponding GitHub release.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

Changes merged into `dev` since the last published release (`v0.1.20260908.12`), not yet published as a GitHub release.

### Added

- The installation package is now always produced as a single ZIP archive with a matching `.sha256` checksum file, named `T1JIT-<Version>-<Branch>.zip` (`-test` suffix for pre-releases). Only the archive and checksum are kept; there is no extracted copy left on disk.
- Documented a dedicated update procedure for the KJIT-Web service (`release/kJITWeb/update-kjitweb.ps1`): it updates an existing installation in place, keeps a rollback backup, and preserves `appsettings*.json` and `app_data` so
  configuration and delegation data are not lost. See [Updating the KJIT-Web service](README.md#updating-the-kjit-web-service).
- `install-JIT.ps1` now detects an existing Just-In-Time installation (via an existing `JIT.config`/`JustInTimeConfig` environment variable, or a previously installed `Config-JIT.ps1`) and updates it in place instead of running the full setup wizard again. If a newer version introduces new configuration settings, only those new settings are prompted for; use `-AdvancedSetup` to run the complete wizard again on an existing installation.
- Updating an existing JIT installation now also fully automates KjitWeb: when `install-JIT.ps1` detects a `KjitWeb` service backed by an already-deployed `KjitWeb.exe`, it skips the "Install the KjitWeb website...?" prompt entirely and
  immediately runs `update-kjitweb.ps1` instead of `install-kjitweb.ps1`, so the service is refreshed in place without asking for `AllowedClient`, `CompanyName`, `Port`, or `DebugLogPath`. `Config-JIT.ps1` likewise no longer prints the "do not forget to configure your OU delegation" reminder in this case, unless delegation was itself a setting newly introduced by the update.
- A fresh Just-In-Time installation now automatically delegates the owning domain's Domain Admins group on every configured search base, so JIT elevation works immediately without a manual `Add-JitDelegation` call. `Add-JitServerOU` grants the same default delegation when a new search base is added later, and `Remove-JITServerOU` already removed any matching delegation (including this default one) when a search base is removed. Updates never add or remove this
  default delegation automatically.
- Added [`EVENTS.md`](EVENTS.md): a consolidated reference documenting every Windows Event Log ID written by T1JIT (event log, source, severity, and meaning), previously scattered across each script's comment-based help. Linked from the README under a new [Event Reference](README.md#event-reference) section.
- The KjitWeb website now shows a symbol next to the version number in the footer when Error or Warning entries were logged to the Tier 1 Management event log within the last 24 hours (routine Warning IDs 2003 and 2009 are ignored). The check runs in the background every 5 minutes and the indicator is refreshed on the page without a reload.
- Added `set-kjitweb-allowedclient.ps1` (next to `install-kjitweb.ps1`) to change which client(s) may reach an already-installed KjitWeb service (`-AllowedClient`) without a full reinstall. It consistently updates `appsettings.json`/`appsettings.Production.json`, the service's `ASPNETCORE_URLS` registry value, the HTTP.sys URL-ACL reservation, and the Windows Firewall rule, then restarts the service; a failed run automatically restores the previous configuration. See [Restricting which clients can reach KjitWeb (AllowedClient)](README.md#restricting-which-clients-can-reach-kjitweb-allowedclient).
- `install-kjitweb.ps1`, `update-kjitweb.ps1`, and `set-kjitweb-allowedclient.ps1` now automatically check and, if missing, register the `HTTP/<hostname>` and `HTTP/<fqdn>` Kerberos SPNs required on the server's computer account whenever KjitWeb is configured for remote access (any `AllowedClient` other than `localhost`); this was previously a manual step documented only in [docs/Kerberos-Setup.md](docs/Kerberos-Setup.md). If the account running the script lacks permission to register the SPN (typically requires Domain Admin rights, or delegated "Validated write to service principal name" on the computer object), a clear warning is written with the exact `setspn -A` command an administrator can run manually instead of failing the installation/update.
- `install-kjitweb.ps1` and `update-kjitweb.ps1` now also copy `install-kjitweb.ps1`, `update-kjitweb.ps1`, and `set-kjitweb-allowedclient.ps1` into the KjitWeb installation folder (`Program Files\KJITWEB` by default) alongside the service binaries. Previously these management scripts only existed in the temporary extraction folder used during setup and were not available afterwards, so administrators had to keep or re-download the release package to run `set-kjitweb-allowedclient.ps1` (for example to change `AllowedClient`) or `update-kjitweb.ps1` again later. They are now always available directly next to the running service.

### Fixed

- `install-JIT.ps1` now fails fast with an actionable error instead of a raw "being used by another process" exception when updating an existing installation while `KjitCore.dll` is still loaded — either in the current PowerShell session (it checks for this up front, before copying any files) or in another PowerShell window or a currently running Just-In-Time scheduled task (detected when the module file copy itself fails). The message tells the administrator to close the offending session/wait for the scheduled task and re-run the installer.
- `update-kjitweb.ps1` now also enforces the `NetworkService` service account (as already done by `install-kjitweb.ps1`), so an existing KjitWeb service that was still running as `LocalSystem` (from an installation predating this setting) is corrected on the next update. `NetworkService` remains required because KjitWeb authenticates against Active Directory using the computer account; `LocalService` cannot do this, as it presents anonymous credentials on the network.
- `update-kjitweb.ps1` now also verifies the Windows Firewall rule matches the configured `AllowedClient` on every update, restoring it if it was manually removed or creating it for the first time on installations that predate this safeguard. Previously, only `install-kjitweb.ps1` created this rule, and `update-kjitweb.ps1` never touched the firewall at all, so a rule removed or missing outside of a fresh install was never repaired.
- Fixed: after switching the KjitWeb service account to `NetworkService`, Windows Authentication (Negotiate/Kerberos/NTLM) stopped working entirely — even for `http://localhost:<port>`. Root cause: the managed Negotiate authentication handler used with Kestrel performs authentication in-process and requires the service account to either be `LocalSystem` or a domain/local account with an SPN registered directly  on it; `NetworkService` has no such identity of its own. KjitWeb is now hosted on **HTTP.sys** instead of Kestrel, which — like IIS — performs Windows Authentication in kernel mode independent of the hosting process's account, so `NetworkService` now works correctly. Required SPNs are now registered on the server's **computer account** instead of a dedicated service account; see   [docs/Kerberos-Setup.md](docs/Kerberos-Setup.md) for the updated setup instructions. `install-kjitweb.ps1` and `update-kjitweb.ps1` now also reserve the HTTP.sys URL namespace for `NetworkService` via `netsh http add urlacl`, which HTTP.sys requires for non-administrator accounts to bind a port.
- Fixed: setting the KjitWeb service account to `NetworkService` failed with `sc.exe exited with code 1639` in both `install-kjitweb.ps1` and `update-kjitweb.ps1`. The cause was a PowerShell quirk where an empty-string `password=` argument passed to a native executable (`sc.exe`) is dropped/mangled, producing an invalid command line. Both scripts now use the `Win32_Service.Change()` WMI/CIM method instead (`Get-CimInstance` + `Invoke-CimMethod`), which avoids native command-line quoting issues entirely. `install-kjitweb.ps1` now also reports a warning if the account change fails, which it previously did not check for at all.
- **Security fix**: the loopback-only KjitWeb configuration (`AllowedClient` left at its default `localhost`) no longer actually restricted access to the local machine. Since the HTTP.sys migration, the service was bound to the hostname string `http://localhost:<port>`, but unlike Kestrel, HTTP.sys only uses that string to match the incoming `Host` header — the underlying socket was still listening on **all** network interfaces. Any client on the 
  network could bypass the intended restriction simply by sending a spoofed `Host: localhost` header to the machine's real IP address. `install-kjitweb.ps1` and `update-kjitweb.ps1` now bind loopback-only installations to the IP-literal prefixes `http://127.0.0.1:<port>` and `http://[::1]:<port>` instead, which HTTP.sys binds to that
  specific address only, restoring true loopback-only network isolation. Existing installations are migrated automatically the next time `update-kjitweb.ps1` runs; no manual action is required. Administrators who additionally need FQDN/console access to a loopback-only installation should configure `AllowedClient` for the desired host (using the new `set-kjitweb-allowedclient.ps1`, see above) instead of relying on Host-header spoofing.
- `Config-JIT.ps1` no longer aborts the entire installation/update with a raw, non-actionable error if the account running it lacks permission to grant the GMSA its `Full Control` delegation on the Tier 1 administrator-group OU. It now writes a clear warning naming the exact GMSA account, the target OU, and the permission to grant, and continues with the rest of the configuration; the administrator can grant the permission afterwards and simply re-run the configuration to have it applied.

### Changed

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
