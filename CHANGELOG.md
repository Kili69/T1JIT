# Changelog

This file describes **user- and administrator-facing changes** to T1JIT: new features,
behavior changes, and fixes that matter when installing, updating, or operating the
Just-In-Time solution and the KJIT-Web service.

This is different from [`History.md`](History.md), which is an automatically generated,
per-push audit log of raw commits and changed files created by `build/Push-GitHub.ps1`.
`History.md` answers "what was pushed and when"; this file answers "what changed for me
as a user of T1JIT, and why does it matter".

Versions follow this repository's scheme `<Major>.<Minor>.<yyyyMMdd>.<Counter>` (see
`build/Update-Version.ps1`), for example `0.1.20260925.3`. Update this file as part of
[creating a release](README.md#creating-a-release), before publishing the corresponding
GitHub release.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

Changes merged into `dev` since the last published release (`v0.1.20260908.12`), not yet
published as a GitHub release.

### Added

- The installation package is now always produced as a single ZIP archive with a
  matching `.sha256` checksum file, named `T1JIT-<Version>-<Branch>.zip`
  (`-test` suffix for pre-releases). Only the archive and checksum are kept; there is no
  extracted copy left on disk.
- Documented a dedicated update procedure for the KJIT-Web service
  (`release/kJITWeb/update-kjitweb.ps1`): it updates an existing installation in place,
  keeps a rollback backup, and preserves `appsettings*.json` and `app_data` so
  configuration and delegation data are not lost. See
  [Updating the KJIT-Web service](README.md#updating-the-kjit-web-service).

### Changed

- Renamed the KJIT-Web release output folder from `release/kjibweb` to `release/kJITWeb`.

## [0.1.20260908.12] - 2026-09-08

### Fixed

- Fixed KjitWeb delegation resolution and relative search-base handling.

### Changed

- Automated the release build as part of the versioning workflow.

## [0.1.20260908.9] - 2026-09-08

### Fixed

- Prevented KjitWeb from reading transient/incomplete delegation configuration, which
  could otherwise apply stale settings.

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
- Added a repeatable, automated test installation for the JIT module
  (`src/Powershell/TestEnvironment`).

### Changed

- Improved multi-domain search diagnostics to make configuration problems easier to
  diagnose.
- Improved PowerShell module documentation and configuration guidance.

### Fixed

- Hardened JIT installation and diagnostics.
- Fixed a PowerShell module runtime compatibility issue.

## [0.1.20260907.34] and earlier

The first tagged pre-release (`v0.1.20260907.34-test`) covers the entire project history
up to that point, including the original request-based Tier-1 delegation model, the
KjitWeb service, the PowerShell configuration modules, and ongoing documentation and
version-numbering improvements. Individual changes from this period were not tracked in
this changelog; see `git log` and `History.md` for full detail.
