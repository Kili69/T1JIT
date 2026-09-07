# Change History

This file records the commits and files included in each GitHub push. New entries are
created by `build/Push-GitHub.ps1`; direct undocumented GitHub pushes are rejected by
the repository's pre-push hook.

<!-- history-enforcement-start:a11dbdc039fffc56405adcb574fe4e54958f9f30 -->
<!-- history-entries -->
## 2026-09-07 16:10:16 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:a95089e418ad9bee11e87cceb94179ae21a706eb -->
- `a95089e` Document T1JIT workflows

Changed files:

- `M -> README.md`

## 2026-09-07 15:46:13 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:04d0b12477ed30b90e4989b93db5820badc97a4c -->
- `04d0b12` Improve installation and architecture documentation

Changed files:

- `M -> README.md`
- `M -> VERSION`
- `M -> file-versions.json`

## 2026-09-07 09:57:46 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:6fd798b0ef469dea38a1afd1119aab6f13eaae7c -->
- `6fd798b` Add push history and installation packaging

Changed files:

- `A -> .githooks/pre-push`
- `A -> .githooks/pre-push.ps1`
- `M -> .gitignore`
- `M -> README.md`
- `M -> VERSION`
- `A -> build/New-InstallationPackage.ps1`
- `A -> build/Push-GitHub.ps1`
- `M -> file-versions.json`


## 2026-09-07 - `dev` to `origin/dev`

Commits:

<!-- commit:a11dbdc039fffc56405adcb574fe4e54958f9f30 -->
- `a11dbdc` Version 0.1.20260907: improve KjitWeb operations
<!-- commit:7270377cd4f80b810cac79976c34f4fe56e2d152 -->
- `7270377` Version 0.1.20260824

Changes:

- Added repository-wide version metadata, validation, and automatic pre-commit versioning.
- Added KjitWeb installation prompts for a free TCP port and company branding.
- Added a searchable server list with ten visible entries and single-domain display.
- Added the current elevated-computer view with automatic refresh and live TTL countdown.
- Added yellow and red TTL warning states plus German and English UI resources.
- Added a full-page processing lock that prevents duplicate elevation requests.
- Extended Active Directory queries and web models for active elevation information.
- Updated installation documentation, release scripts, modules, and published KjitWeb artifacts.



