# Change History

This file records the commits and files included in each GitHub push. New entries are
created by `build/Push-GitHub.ps1`; direct undocumented GitHub pushes are rejected by
the repository's pre-push hook.

<!-- history-enforcement-start:a11dbdc039fffc56405adcb574fe4e54958f9f30 -->
<!-- history-entries -->
## 2026-10-05 11:12:37 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:44faffe831ed57addf73054f77e1af09d83dec17 -->
- `44faffe` Fix README markdown lint issues

Changed files:

- `M -> CHANGELOG.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> file-versions.json`
- `M -> release/ElevateUser.ps1`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/Powershell/modules/Just-In-time.psd1`

## 2026-10-05 10:19:53 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:5edb50da36349ed761059f11d020f54b09a5af25 -->
- `5edb50d` Harden elevation concurrency and document HTTPS

Changed files:

- `M -> CHANGELOG.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `M -> release/ElevateUser.ps1`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/install-kjitweb.ps1`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/0.1/just-in-time-request.psm1`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/ElevateUser.ps1`
- `M -> src/Powershell/modules/0.1/just-in-time-request.psm1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `M -> tests/PowerShell/Modules.Tests.ps1`

## 2026-10-05 09:10:02 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:2202185859a2061f424273edd690d19179e6a9a7 -->
- `2202185` Modernize README documentation

Changed files:

- `M -> CHANGELOG.md`
- `M -> README.md`
- `A -> docs/images/kjitweb-server-selection.png`
- `A -> docs/images/t1jit-powershell-request.png`

## 2026-10-04 08:11:40 +02:00 - `main` to `origin/main`

Commits:

<!-- commit:6843b48629f4461bd4ea13c9ffe513839d0ae68b -->
- `6843b48` Add Windows Autopilot registration workflow
<!-- commit:404f423d14979275b49254ed2067fe89a3675961 -->
- `404f423` Relicense project under Apache 2.0
<!-- commit:aefb1adbe7bf26c9f509a4881bd46574bf37dd63 -->
- `aefb1ad` Document GitHub push history
<!-- commit:4f956fea10b07eea77893bfbda52104e2a37c718 -->
- `4f956fe` Add Group Policy provisioning and improve release workflow
<!-- commit:82c6bd9eb9c85955f349c3522d18b9b9a3fb8295 -->
- `82c6bd9` Filter KjitWeb servers and repair gMSA tasks
<!-- commit:030b48984f6d945c667e62c3d229ed39d3b1c124 -->
- `030b489` Fix gMSA scheduled task logon
<!-- commit:4b32deb8f48145f72f10e0a92656a8adf94c39e2 -->
- `4b32deb` Version changelog entries per commit
<!-- commit:44aa31da5294f4244e2c6d359eb67cdd99be37cf -->
- `44aa31d` Accept CRLF changelog versions
<!-- commit:c856aeafbf0371f634f5251a00fd415f7260a03b -->
- `c856aea` Exclude generated release from version checks
<!-- commit:da1c26fa7c6335b95107be26a0df526487c90400 -->
- `da1c26f` Add KjitWeb About menu and unify documentation
<!-- commit:352ccb020ebed10acb7d8f947c4bea3adba31615 -->
- `352ccb0` Document GitHub push history
<!-- commit:9c0db427de90fa7aa8089d0781c3ae68fda5f9ce -->
- `9c0db42` Allow versioned history metadata in pushes
<!-- commit:c514d376acf9e12be3b29b5ef73ea331f40794a9 -->
- `c514d37` Document GitHub push history
<!-- commit:5df2dc056b026d7bce57702b78b1b95cf48595b0 -->
- `5df2dc0` Refine KjitWeb utility navigation
<!-- commit:ae0b1641d9a98ed78865dcc66f821706a0337149 -->
- `ae0b164` Document GitHub push history
<!-- commit:38fcfec155fb6fec4e8bfe4be93ce492d81eb3a1 -->
- `38fcfec` Promote dev changes to main

Changed files:

- `M -> .githooks/pre-commit.ps1`
- `M -> .githooks/pre-push.ps1`
- `A -> .mailmap`
- `M -> CHANGELOG.md`
- `M -> Developer.md`
- `A -> GroupPolicy/New-T1JitLocalAdministratorsGpo.ps1`
- `A -> GroupPolicy/README.md`
- `M -> LICENSE`
- `M -> README.md`
- `M -> VERSION`
- `M -> build/New-InstallationPackage.ps1`
- `M -> build/Push-GitHub.ps1`
- `M -> build/Test-PowerShellModules.ps1`
- `M -> build/Update-Version.ps1`
- `M -> build/release_build.ps1`
- `M -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `M -> release/Config-JITUI.ps1`
- `M -> release/ElevateUser.ps1`
- `A -> release/GroupPolicy/New-T1JitLocalAdministratorsGpo.ps1`
- `A -> release/GroupPolicy/README.md`
- `A -> release/LICENSE`
- `A -> release/Register-WindowsAutopilotDevice.ps1`
- `M -> release/Request-AdminAccessUI.ps1`
- `M -> release/RequestAdminAccessUI.ps1`
- `M -> release/Show-KjitConfiguration.ps1`
- `M -> release/Tier1LocalAdminGroup.ps1`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/install-JIT.ps1`
- `M -> release/kJITWeb/get-kjitweb-allowedclient.ps1`
- `M -> release/kJITWeb/install-kjitweb.ps1`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.xml`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `A -> release/kJITWeb/publish-service/wwwroot/css/site.css`
- `A -> release/kJITWeb/publish-service/wwwroot/images/andreas-lucas-github.jpg`
- `M -> release/kJITWeb/set-kjitweb-allowedclient.ps1`
- `M -> release/kJITWeb/update-kjitweb.ps1`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> release/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> release/modules/0.1/just-in-time-configuration.psm1`
- `M -> release/modules/0.1/just-in-time-request.psm1`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/C#/KjitCore.DebugHost/KjitCore.DebugHost.csproj`
- `M -> src/C#/KjitCore/KjitCore.csproj`
- `M -> src/C#/KjitCore/Models/JitConfigurationObject.cs`
- `M -> src/C#/KjitCore/Services/JitConfigurationReader.cs`
- `M -> src/C#/Kjitweb/Controllers/HomeController.cs`
- `M -> src/C#/Kjitweb/KjitWeb.csproj`
- `M -> src/C#/Kjitweb/Resources/SharedResource.de.resx`
- `M -> src/C#/Kjitweb/Resources/SharedResource.en.resx`
- `M -> src/C#/Kjitweb/Services/ActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/EventLogWriter.cs`
- `M -> src/C#/Kjitweb/Services/IActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/configuration.cs`
- `M -> src/C#/Kjitweb/Views/Home/Index.cshtml`
- `M -> src/C#/Kjitweb/Views/Shared/_Layout.cshtml`
- `M -> src/C#/Kjitweb/get-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `M -> src/C#/Kjitweb/set-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/uninstall-service.ps1`
- `M -> src/C#/Kjitweb/update-kjitweb.ps1`
- `A -> src/C#/Kjitweb/wwwroot/css/site.css`
- `A -> src/C#/Kjitweb/wwwroot/images/andreas-lucas-github.jpg`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/Config-JITUI.ps1`
- `M -> src/Powershell/Scripts/ElevateUser.ps1`
- `A -> src/Powershell/Scripts/Register-WindowsAutopilotDevice.ps1`
- `M -> src/Powershell/Scripts/Request-AdminAccessUI.ps1`
- `M -> src/Powershell/Scripts/RequestAdminAccessUI.ps1`
- `M -> src/Powershell/Scripts/Show-KjitConfiguration.ps1`
- `M -> src/Powershell/Scripts/Tier1LocalAdminGroup.ps1`
- `M -> src/Powershell/Scripts/install-JIT.ps1`
- `M -> src/Powershell/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> src/Powershell/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-configuration.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-request.psm1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `M -> tests/PowerShell/Modules.Tests.ps1`
- `D -> tmp_ps51_test.ps1`
- `D -> tmp_release_test.ps1`

## 2026-10-04 08:05:49 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:5df2dc056b026d7bce57702b78b1b95cf48595b0 -->
- `5df2dc0` Refine KjitWeb utility navigation

Changed files:

- `M -> CHANGELOG.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/wwwroot/css/site.css`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/C#/Kjitweb/Views/Home/Index.cshtml`
- `M -> src/C#/Kjitweb/Views/Shared/_Layout.cshtml`
- `M -> src/C#/Kjitweb/wwwroot/css/site.css`
- `M -> src/Powershell/modules/Just-In-time.psd1`

## 2026-10-04 07:37:14 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:4f956fea10b07eea77893bfbda52104e2a37c718 -->
- `4f956fe` Add Group Policy provisioning and improve release workflow
<!-- commit:82c6bd9eb9c85955f349c3522d18b9b9a3fb8295 -->
- `82c6bd9` Filter KjitWeb servers and repair gMSA tasks
<!-- commit:030b48984f6d945c667e62c3d229ed39d3b1c124 -->
- `030b489` Fix gMSA scheduled task logon
<!-- commit:4b32deb8f48145f72f10e0a92656a8adf94c39e2 -->
- `4b32deb` Version changelog entries per commit
<!-- commit:44aa31da5294f4244e2c6d359eb67cdd99be37cf -->
- `44aa31d` Accept CRLF changelog versions
<!-- commit:c856aeafbf0371f634f5251a00fd415f7260a03b -->
- `c856aea` Exclude generated release from version checks
<!-- commit:da1c26fa7c6335b95107be26a0df526487c90400 -->
- `da1c26f` Add KjitWeb About menu and unify documentation
<!-- commit:352ccb020ebed10acb7d8f947c4bea3adba31615 -->
- `352ccb0` Document GitHub push history
<!-- commit:9c0db427de90fa7aa8089d0781c3ae68fda5f9ce -->
- `9c0db42` Allow versioned history metadata in pushes

Changed files:

- `M -> .githooks/pre-commit.ps1`
- `M -> .githooks/pre-push.ps1`
- `M -> CHANGELOG.md`
- `M -> Developer.md`
- `A -> GroupPolicy/New-T1JitLocalAdministratorsGpo.ps1`
- `A -> GroupPolicy/README.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> build/New-InstallationPackage.ps1`
- `M -> build/Push-GitHub.ps1`
- `M -> build/Update-Version.ps1`
- `M -> build/release_build.ps1`
- `M -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `A -> release/GroupPolicy/New-T1JitLocalAdministratorsGpo.ps1`
- `A -> release/GroupPolicy/README.md`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/install-JIT.ps1`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.xml`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `A -> release/kJITWeb/publish-service/wwwroot/css/site.css`
- `A -> release/kJITWeb/publish-service/wwwroot/images/andreas-lucas-github.jpg`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/C#/KjitCore/Models/JitConfigurationObject.cs`
- `M -> src/C#/KjitCore/Services/JitConfigurationReader.cs`
- `M -> src/C#/Kjitweb/Controllers/HomeController.cs`
- `M -> src/C#/Kjitweb/Resources/SharedResource.de.resx`
- `M -> src/C#/Kjitweb/Resources/SharedResource.en.resx`
- `M -> src/C#/Kjitweb/Services/ActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/EventLogWriter.cs`
- `M -> src/C#/Kjitweb/Services/IActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/configuration.cs`
- `M -> src/C#/Kjitweb/Views/Shared/_Layout.cshtml`
- `A -> src/C#/Kjitweb/wwwroot/css/site.css`
- `A -> src/C#/Kjitweb/wwwroot/images/andreas-lucas-github.jpg`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/install-JIT.ps1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `M -> tests/PowerShell/Modules.Tests.ps1`

## 2026-10-04 07:34:28 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:4f956fea10b07eea77893bfbda52104e2a37c718 -->
- `4f956fe` Add Group Policy provisioning and improve release workflow
<!-- commit:82c6bd9eb9c85955f349c3522d18b9b9a3fb8295 -->
- `82c6bd9` Filter KjitWeb servers and repair gMSA tasks
<!-- commit:030b48984f6d945c667e62c3d229ed39d3b1c124 -->
- `030b489` Fix gMSA scheduled task logon
<!-- commit:4b32deb8f48145f72f10e0a92656a8adf94c39e2 -->
- `4b32deb` Version changelog entries per commit
<!-- commit:44aa31da5294f4244e2c6d359eb67cdd99be37cf -->
- `44aa31d` Accept CRLF changelog versions
<!-- commit:c856aeafbf0371f634f5251a00fd415f7260a03b -->
- `c856aea` Exclude generated release from version checks
<!-- commit:da1c26fa7c6335b95107be26a0df526487c90400 -->
- `da1c26f` Add KjitWeb About menu and unify documentation

Changed files:

- `M -> .githooks/pre-commit.ps1`
- `M -> CHANGELOG.md`
- `M -> Developer.md`
- `A -> GroupPolicy/New-T1JitLocalAdministratorsGpo.ps1`
- `A -> GroupPolicy/README.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> build/New-InstallationPackage.ps1`
- `M -> build/Push-GitHub.ps1`
- `M -> build/Update-Version.ps1`
- `M -> build/release_build.ps1`
- `M -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `A -> release/GroupPolicy/New-T1JitLocalAdministratorsGpo.ps1`
- `A -> release/GroupPolicy/README.md`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/install-JIT.ps1`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.xml`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `A -> release/kJITWeb/publish-service/wwwroot/css/site.css`
- `A -> release/kJITWeb/publish-service/wwwroot/images/andreas-lucas-github.jpg`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/C#/KjitCore/Models/JitConfigurationObject.cs`
- `M -> src/C#/KjitCore/Services/JitConfigurationReader.cs`
- `M -> src/C#/Kjitweb/Controllers/HomeController.cs`
- `M -> src/C#/Kjitweb/Resources/SharedResource.de.resx`
- `M -> src/C#/Kjitweb/Resources/SharedResource.en.resx`
- `M -> src/C#/Kjitweb/Services/ActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/EventLogWriter.cs`
- `M -> src/C#/Kjitweb/Services/IActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/configuration.cs`
- `M -> src/C#/Kjitweb/Views/Shared/_Layout.cshtml`
- `A -> src/C#/Kjitweb/wwwroot/css/site.css`
- `A -> src/C#/Kjitweb/wwwroot/images/andreas-lucas-github.jpg`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/install-JIT.ps1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `M -> tests/PowerShell/Modules.Tests.ps1`

## 2026-10-03 19:26:20 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:404f423d14979275b49254ed2067fe89a3675961 -->
- `404f423` Relicense project under Apache 2.0

Changed files:

- `M -> .githooks/pre-commit.ps1`
- `M -> .githooks/pre-push.ps1`
- `A -> .mailmap`
- `M -> CHANGELOG.md`
- `M -> Developer.md`
- `M -> LICENSE`
- `M -> README.md`
- `M -> build/New-InstallationPackage.ps1`
- `M -> build/Push-GitHub.ps1`
- `M -> build/Test-PowerShellModules.ps1`
- `M -> build/Update-Version.ps1`
- `M -> build/release_build.ps1`
- `M -> release/Config-JIT.ps1`
- `M -> release/Config-JITUI.ps1`
- `M -> release/ElevateUser.ps1`
- `A -> release/LICENSE`
- `M -> release/Register-WindowsAutopilotDevice.ps1`
- `M -> release/Request-AdminAccessUI.ps1`
- `M -> release/RequestAdminAccessUI.ps1`
- `M -> release/Show-KjitConfiguration.ps1`
- `M -> release/Tier1LocalAdminGroup.ps1`
- `M -> release/install-JIT.ps1`
- `M -> release/kJITWeb/get-kjitweb-allowedclient.ps1`
- `M -> release/kJITWeb/install-kjitweb.ps1`
- `M -> release/kJITWeb/set-kjitweb-allowedclient.ps1`
- `M -> release/kJITWeb/update-kjitweb.ps1`
- `M -> release/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> release/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> release/modules/0.1/just-in-time-configuration.psm1`
- `M -> release/modules/0.1/just-in-time-request.psm1`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/C#/KjitCore.DebugHost/KjitCore.DebugHost.csproj`
- `M -> src/C#/KjitCore/KjitCore.csproj`
- `M -> src/C#/Kjitweb/KjitWeb.csproj`
- `M -> src/C#/Kjitweb/get-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `M -> src/C#/Kjitweb/set-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/uninstall-service.ps1`
- `M -> src/C#/Kjitweb/update-kjitweb.ps1`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/Config-JITUI.ps1`
- `M -> src/Powershell/Scripts/ElevateUser.ps1`
- `M -> src/Powershell/Scripts/Register-WindowsAutopilotDevice.ps1`
- `M -> src/Powershell/Scripts/Request-AdminAccessUI.ps1`
- `M -> src/Powershell/Scripts/RequestAdminAccessUI.ps1`
- `M -> src/Powershell/Scripts/Show-KjitConfiguration.ps1`
- `M -> src/Powershell/Scripts/Tier1LocalAdminGroup.ps1`
- `M -> src/Powershell/Scripts/install-JIT.ps1`
- `M -> src/Powershell/TestEnvironment/Install-T1JitTestInstallation.ps1`
- `M -> src/Powershell/TestEnvironment/New-T1JitTestEnvironment.ps1`
- `M -> src/Powershell/TestEnvironment/Remove-T1JitInstallation.ps1`
- `M -> src/Powershell/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> src/Powershell/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-configuration.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-request.psm1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `M -> tests/PowerShell/Modules.Tests.ps1`
- `D -> tmp_ps51_test.ps1`
- `D -> tmp_release_test.ps1`

## 2026-09-27 11:28:17 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:5efb76ba2e7e6d24f9a6efe931cd15ecb094740e -->
- `5efb76b` Extend KjitWeb client access management

Changed files:

- `M -> CHANGELOG.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> build/New-InstallationPackage.ps1`
- `M -> build/release_build.ps1`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `A -> release/kJITWeb/get-kjitweb-allowedclient.ps1`
- `M -> release/kJITWeb/install-kjitweb.ps1`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/kJITWeb/set-kjitweb-allowedclient.ps1`
- `M -> release/kJITWeb/update-kjitweb.ps1`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/Just-In-time.psd1`
- `A -> src/C#/Kjitweb/get-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `M -> src/C#/Kjitweb/set-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/update-kjitweb.ps1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `M -> tests/PowerShell/Modules.Tests.ps1`

## 2026-09-26 22:07:43 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:5624d9dfe5ce4b467c6e8a0ceb4ce5af7d083701 -->
- `5624d9d` Document C# APIs and harden KjitWeb firewall setup
<!-- commit:c0dfa31d46a80319aae9e178185af14b8952f184 -->
- `c0dfa31` Restructure documentation and harden release build

Changed files:

- `M -> CHANGELOG.md`
- `A -> Developer.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> build/release_build.ps1`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/install-kjitweb.ps1`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `A -> release/kJITWeb/publish-service/KjitWeb.xml`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/kJITWeb/set-kjitweb-allowedclient.ps1`
- `M -> release/kJITWeb/update-kjitweb.ps1`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/C#/KjitCore.DebugHost/KjitCore.DebugHost.csproj`
- `M -> src/C#/KjitCore.DebugHost/Program.cs`
- `M -> src/C#/KjitCore/Abstractions/IDistinguishedNameService.cs`
- `M -> src/C#/KjitCore/Abstractions/IIdentityNormalizer.cs`
- `M -> src/C#/KjitCore/KjitCore.cs`
- `M -> src/C#/KjitCore/KjitCore.csproj`
- `M -> src/C#/KjitCore/Models/JitConfigurationObject.cs`
- `M -> src/C#/KjitCore/Services/DistinguishedNameService.cs`
- `M -> src/C#/KjitCore/Services/IdentityNormalizer.cs`
- `M -> src/C#/KjitCore/Services/JitConfigurationReader.cs`
- `M -> src/C#/Kjitweb/Controllers/HomeController.cs`
- `M -> src/C#/Kjitweb/GlobalUsings.cs`
- `M -> src/C#/Kjitweb/KjitWeb.csproj`
- `M -> src/C#/Kjitweb/Models/ElevatedComputerViewModel.cs`
- `M -> src/C#/Kjitweb/Models/ServerSelectionViewModel.cs`
- `M -> src/C#/Kjitweb/Models/SwitchUserViewModel.cs`
- `M -> src/C#/Kjitweb/Program.cs`
- `M -> src/C#/Kjitweb/Services/ActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/BasicAuthenticationHandler.cs`
- `M -> src/C#/Kjitweb/Services/ConnectionAuditLogger.cs`
- `M -> src/C#/Kjitweb/Services/DebugFileLoggerProvider.cs`
- `M -> src/C#/Kjitweb/Services/DebugLogFileWriter.cs`
- `M -> src/C#/Kjitweb/Services/EventLogHealthMonitor.cs`
- `M -> src/C#/Kjitweb/Services/EventLogHealthSnapshot.cs`
- `M -> src/C#/Kjitweb/Services/EventLogWriter.cs`
- `M -> src/C#/Kjitweb/Services/IActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/IConnectionAuditLogger.cs`
- `M -> src/C#/Kjitweb/Services/IEventLogHealthMonitor.cs`
- `M -> src/C#/Kjitweb/Services/IEventLogWriter.cs`
- `M -> src/C#/Kjitweb/Services/JitConfigPathResolver.cs`
- `M -> src/C#/Kjitweb/Services/MutualTlsCertificateValidator.cs`
- `M -> src/C#/Kjitweb/Services/MutualTlsOptions.cs`
- `M -> src/C#/Kjitweb/Services/WindowsCredentialValidator.cs`
- `M -> src/C#/Kjitweb/Services/configuration.cs`
- `M -> src/C#/Kjitweb/SharedResource.cs`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `M -> src/C#/Kjitweb/set-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/update-kjitweb.ps1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `M -> tests/PowerShell/Modules.Tests.ps1`

## 2026-09-26 09:58:14 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:1f49deb40658670cc0d8c2bd300a409e954313bc -->
- `1f49deb` Complete module API documentation

Changed files:

- `M -> CHANGELOG.md`
- `M -> VERSION`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> release/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> release/modules/0.1/just-in-time-configuration.psm1`
- `M -> release/modules/0.1/just-in-time-request.psm1`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/C#/KjitCore/KjitCore.cs`
- `M -> src/Powershell/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> src/Powershell/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-configuration.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-request.psm1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `M -> tests/PowerShell/Modules.Tests.ps1`

## 2026-09-26 09:36:36 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:a14e8b5beb3578d66b87156fe91a90e22290832e -->
- `a14e8b5` Fix JIT configuration compatibility and gate packages
<!-- commit:382e294d7456028cdda6b5e04150174a3c887049 -->
- `382e294` Document GitHub push history
<!-- commit:c682ef837cca26255bed52155c080b969d264531 -->
- `c682ef8` Allow module version updates in history commits

Changed files:

- `M -> .githooks/pre-commit.ps1`
- `M -> .githooks/pre-push.ps1`
- `M -> CHANGELOG.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> build/New-InstallationPackage.ps1`
- `A -> build/Test-PowerShellModules.ps1`
- `M -> build/Update-Version.ps1`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> release/modules/0.1/just-in-time-configuration.psm1`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/C#/KjitCore/Models/JitConfigurationObject.cs`
- `M -> src/C#/KjitCore/Services/JitConfigurationReader.cs`
- `M -> src/Powershell/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-configuration.psm1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `A -> tests/PowerShell/Modules.Tests.ps1`

## 2026-09-26 09:34:25 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:a14e8b5beb3578d66b87156fe91a90e22290832e -->
- `a14e8b5` Fix JIT configuration compatibility and gate packages

Changed files:

- `M -> .githooks/pre-commit.ps1`
- `M -> CHANGELOG.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> build/New-InstallationPackage.ps1`
- `A -> build/Test-PowerShellModules.ps1`
- `M -> build/Update-Version.ps1`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> release/modules/0.1/just-in-time-configuration.psm1`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/C#/KjitCore/Models/JitConfigurationObject.cs`
- `M -> src/C#/KjitCore/Services/JitConfigurationReader.cs`
- `M -> src/Powershell/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-configuration.psm1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `A -> tests/PowerShell/Modules.Tests.ps1`

## 2026-09-25 19:00:44 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:18c6a91ea15604172e01c61618abda836ad42910 -->
- `18c6a91` Bump version scheme to 0.2 and condense CHANGELOG unreleased section

Changed files:

- `M -> CHANGELOG.md`
- `M -> VERSION`
- `M -> build/Update-Version.ps1`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`

## 2026-09-25 18:51:49 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:653456bb3120674056ccefcb65ffb3d5bb31c0de -->
- `653456b` Rename release output to kJITWeb, automate ZIP packaging, document KjitWeb updates
<!-- commit:0b4d13a65f53814704d065a7a4054fba1f21a848 -->
- `0b4d13a` Package installation output as a single ZIP named by version and branch
<!-- commit:e20024d7094eabfae077ba64feefb5b2764beb51 -->
- `e20024d` Add a user-facing CHANGELOG.md and wire it into the release process
<!-- commit:2ece1b5373a6069580e263938a2fe2ee14dc3346 -->
- `2ece1b5` Detect existing installations in install-JIT.ps1 and update in place
<!-- commit:923155d1754e2847103f74b5f530e4f9ff5d57ed -->
- `923155d` Add KjitWeb Kerberos SPN automation, GMSA permission handling, and persist management scripts

Changed files:

- `M -> .githooks/pre-commit.ps1`
- `M -> .gitignore`
- `A -> CHANGELOG.md`
- `A -> EVENTS.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> build/New-InstallationPackage.ps1`
- `M -> build/release_build.ps1`
- `M -> docs/Authentication.md`
- `M -> docs/Kerberos-Setup.md`
- `M -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/install-JIT.ps1`
- `R100 -> release/kjibweb/appsettings.Production.json -> release/kJITWeb/appsettings.Production.json`
- `R100 -> release/kjibweb/appsettings.json -> release/kJITWeb/appsettings.json`
- `R080 -> release/kjibweb/install-kjitweb.ps1 -> release/kJITWeb/install-kjitweb.ps1`
- `R100 -> release/kjibweb/kjitlogo.png -> release/kJITWeb/kjitlogo.png`
- `R095 -> release/kjibweb/publish-service/KjitWeb.deps.json -> release/kJITWeb/publish-service/KjitWeb.deps.json`
- `A -> release/kJITWeb/publish-service/KjitWeb.dll`
- `R099 -> release/kjibweb/publish-service/KjitWeb.exe -> release/kJITWeb/publish-service/KjitWeb.exe`
- `A -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `R100 -> release/kjibweb/publish-service/KjitWeb.runtimeconfig.json -> release/kJITWeb/publish-service/KjitWeb.runtimeconfig.json`
- `A -> release/kJITWeb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Antiforgery.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Antiforgery.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.BearerToken.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.BearerToken.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.Cookies.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Cookies.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.Core.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Core.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.OAuth.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.OAuth.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authorization.Policy.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authorization.Policy.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authorization.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authorization.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.Authorization.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Authorization.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.Endpoints.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Endpoints.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.Forms.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Forms.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.Server.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Server.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.Web.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Web.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Connections.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.CookiePolicy.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.CookiePolicy.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Cors.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cors.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Cryptography.Internal.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cryptography.Internal.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Cryptography.KeyDerivation.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cryptography.KeyDerivation.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.DataProtection.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.DataProtection.Extensions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.Extensions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.DataProtection.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Diagnostics.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Diagnostics.HealthChecks.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.HealthChecks.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Diagnostics.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.HostFiltering.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HostFiltering.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Hosting.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Hosting.Server.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.Server.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Hosting.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Html.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Html.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Connections.Common.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Connections.Common.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Connections.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Connections.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Extensions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Extensions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Features.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Features.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Results.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Results.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.HttpLogging.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpLogging.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.HttpOverrides.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpOverrides.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.HttpsPolicy.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpsPolicy.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Identity.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Identity.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Localization.Routing.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Localization.Routing.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Localization.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Localization.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Metadata.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Metadata.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.ApiExplorer.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.ApiExplorer.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Core.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Core.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Cors.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Cors.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.DataAnnotations.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.DataAnnotations.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Json.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Json.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Xml.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Xml.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Localization.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Localization.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Razor.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Razor.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.RazorPages.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.RazorPages.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.TagHelpers.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.TagHelpers.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.ViewFeatures.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.ViewFeatures.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.OutputCaching.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.OutputCaching.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.RateLimiting.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.RateLimiting.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Razor.Runtime.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Razor.Runtime.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Razor.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Razor.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.RequestDecompression.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.RequestDecompression.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.ResponseCaching.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCaching.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.ResponseCaching.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCaching.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.ResponseCompression.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCompression.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Rewrite.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Rewrite.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Routing.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Routing.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Routing.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Routing.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.HttpSys.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.HttpSys.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.IIS.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.IIS.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.IISIntegration.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.IISIntegration.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Core.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Core.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.NamedPipes.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.NamedPipes.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Quic.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Quic.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.Session.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Session.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.SignalR.Common.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Common.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.SignalR.Core.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Core.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.SignalR.Protocols.Json.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Protocols.Json.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.SignalR.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.StaticFiles.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.StaticFiles.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.WebSockets.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.WebSockets.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.WebUtilities.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.WebUtilities.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.AspNetCore.dll -> release/kJITWeb/publish-service/Microsoft.AspNetCore.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.CSharp.dll -> release/kJITWeb/publish-service/Microsoft.CSharp.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.DiaSymReader.Native.amd64.dll -> release/kJITWeb/publish-service/Microsoft.DiaSymReader.Native.amd64.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Caching.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Caching.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Caching.Memory.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Caching.Memory.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.Binder.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Binder.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.CommandLine.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.CommandLine.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.EnvironmentVariables.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.EnvironmentVariables.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.FileExtensions.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.FileExtensions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.Ini.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Ini.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.Json.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Json.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.KeyPerFile.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.KeyPerFile.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.UserSecrets.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.UserSecrets.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.Xml.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Xml.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.DependencyInjection.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.DependencyInjection.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.DependencyInjection.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.DependencyInjection.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Diagnostics.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Diagnostics.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Features.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.FileProviders.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.FileProviders.Composite.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Composite.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.FileProviders.Embedded.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Embedded.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.FileProviders.Physical.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Physical.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.FileSystemGlobbing.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.FileSystemGlobbing.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Hosting.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Hosting.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Http.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Http.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Identity.Core.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Identity.Core.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Identity.Stores.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Identity.Stores.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Localization.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Localization.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Localization.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Localization.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.Abstractions.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Abstractions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.Configuration.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Configuration.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.Console.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Console.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.Debug.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Debug.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.EventLog.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.EventLog.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.EventSource.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.EventSource.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.TraceSource.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.TraceSource.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.ObjectPool.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.ObjectPool.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Options.ConfigurationExtensions.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.ConfigurationExtensions.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Options.DataAnnotations.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.DataAnnotations.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Options.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.Primitives.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Primitives.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Extensions.WebEncoders.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.WebEncoders.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.JSInterop.dll -> release/kJITWeb/publish-service/Microsoft.JSInterop.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Net.Http.Headers.dll -> release/kJITWeb/publish-service/Microsoft.Net.Http.Headers.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.VisualBasic.Core.dll -> release/kJITWeb/publish-service/Microsoft.VisualBasic.Core.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.VisualBasic.dll -> release/kJITWeb/publish-service/Microsoft.VisualBasic.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Win32.Primitives.dll -> release/kJITWeb/publish-service/Microsoft.Win32.Primitives.dll`
- `R100 -> release/kjibweb/publish-service/Microsoft.Win32.Registry.dll -> release/kJITWeb/publish-service/Microsoft.Win32.Registry.dll`
- `R100 -> release/kjibweb/publish-service/System.AppContext.dll -> release/kJITWeb/publish-service/System.AppContext.dll`
- `R100 -> release/kjibweb/publish-service/System.Buffers.dll -> release/kJITWeb/publish-service/System.Buffers.dll`
- `R100 -> release/kjibweb/publish-service/System.Collections.Concurrent.dll -> release/kJITWeb/publish-service/System.Collections.Concurrent.dll`
- `R100 -> release/kjibweb/publish-service/System.Collections.Immutable.dll -> release/kJITWeb/publish-service/System.Collections.Immutable.dll`
- `R100 -> release/kjibweb/publish-service/System.Collections.NonGeneric.dll -> release/kJITWeb/publish-service/System.Collections.NonGeneric.dll`
- `R100 -> release/kjibweb/publish-service/System.Collections.Specialized.dll -> release/kJITWeb/publish-service/System.Collections.Specialized.dll`
- `R100 -> release/kjibweb/publish-service/System.Collections.dll -> release/kJITWeb/publish-service/System.Collections.dll`
- `R100 -> release/kjibweb/publish-service/System.ComponentModel.Annotations.dll -> release/kJITWeb/publish-service/System.ComponentModel.Annotations.dll`
- `R100 -> release/kjibweb/publish-service/System.ComponentModel.DataAnnotations.dll -> release/kJITWeb/publish-service/System.ComponentModel.DataAnnotations.dll`
- `R100 -> release/kjibweb/publish-service/System.ComponentModel.EventBasedAsync.dll -> release/kJITWeb/publish-service/System.ComponentModel.EventBasedAsync.dll`
- `R100 -> release/kjibweb/publish-service/System.ComponentModel.Primitives.dll -> release/kJITWeb/publish-service/System.ComponentModel.Primitives.dll`
- `R100 -> release/kjibweb/publish-service/System.ComponentModel.TypeConverter.dll -> release/kJITWeb/publish-service/System.ComponentModel.TypeConverter.dll`
- `R100 -> release/kjibweb/publish-service/System.ComponentModel.dll -> release/kJITWeb/publish-service/System.ComponentModel.dll`
- `R100 -> release/kjibweb/publish-service/System.Configuration.dll -> release/kJITWeb/publish-service/System.Configuration.dll`
- `R100 -> release/kjibweb/publish-service/System.Console.dll -> release/kJITWeb/publish-service/System.Console.dll`
- `R100 -> release/kjibweb/publish-service/System.Core.dll -> release/kJITWeb/publish-service/System.Core.dll`
- `R100 -> release/kjibweb/publish-service/System.Data.Common.dll -> release/kJITWeb/publish-service/System.Data.Common.dll`
- `R100 -> release/kjibweb/publish-service/System.Data.DataSetExtensions.dll -> release/kJITWeb/publish-service/System.Data.DataSetExtensions.dll`
- `R100 -> release/kjibweb/publish-service/System.Data.dll -> release/kJITWeb/publish-service/System.Data.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.Contracts.dll -> release/kJITWeb/publish-service/System.Diagnostics.Contracts.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.Debug.dll -> release/kJITWeb/publish-service/System.Diagnostics.Debug.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.DiagnosticSource.dll -> release/kJITWeb/publish-service/System.Diagnostics.DiagnosticSource.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.EventLog.Messages.dll -> release/kJITWeb/publish-service/System.Diagnostics.EventLog.Messages.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.EventLog.dll -> release/kJITWeb/publish-service/System.Diagnostics.EventLog.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.FileVersionInfo.dll -> release/kJITWeb/publish-service/System.Diagnostics.FileVersionInfo.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.Process.dll -> release/kJITWeb/publish-service/System.Diagnostics.Process.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.StackTrace.dll -> release/kJITWeb/publish-service/System.Diagnostics.StackTrace.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.TextWriterTraceListener.dll -> release/kJITWeb/publish-service/System.Diagnostics.TextWriterTraceListener.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.Tools.dll -> release/kJITWeb/publish-service/System.Diagnostics.Tools.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.TraceSource.dll -> release/kJITWeb/publish-service/System.Diagnostics.TraceSource.dll`
- `R100 -> release/kjibweb/publish-service/System.Diagnostics.Tracing.dll -> release/kJITWeb/publish-service/System.Diagnostics.Tracing.dll`
- `R100 -> release/kjibweb/publish-service/System.DirectoryServices.Protocols.dll -> release/kJITWeb/publish-service/System.DirectoryServices.Protocols.dll`
- `R100 -> release/kjibweb/publish-service/System.Drawing.Primitives.dll -> release/kJITWeb/publish-service/System.Drawing.Primitives.dll`
- `R100 -> release/kjibweb/publish-service/System.Drawing.dll -> release/kJITWeb/publish-service/System.Drawing.dll`
- `R100 -> release/kjibweb/publish-service/System.Dynamic.Runtime.dll -> release/kJITWeb/publish-service/System.Dynamic.Runtime.dll`
- `R100 -> release/kjibweb/publish-service/System.Formats.Asn1.dll -> release/kJITWeb/publish-service/System.Formats.Asn1.dll`
- `R100 -> release/kjibweb/publish-service/System.Formats.Tar.dll -> release/kJITWeb/publish-service/System.Formats.Tar.dll`
- `R100 -> release/kjibweb/publish-service/System.Globalization.Calendars.dll -> release/kJITWeb/publish-service/System.Globalization.Calendars.dll`
- `R100 -> release/kjibweb/publish-service/System.Globalization.Extensions.dll -> release/kJITWeb/publish-service/System.Globalization.Extensions.dll`
- `R100 -> release/kjibweb/publish-service/System.Globalization.dll -> release/kJITWeb/publish-service/System.Globalization.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.Compression.Brotli.dll -> release/kJITWeb/publish-service/System.IO.Compression.Brotli.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.Compression.FileSystem.dll -> release/kJITWeb/publish-service/System.IO.Compression.FileSystem.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.Compression.Native.dll -> release/kJITWeb/publish-service/System.IO.Compression.Native.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.Compression.ZipFile.dll -> release/kJITWeb/publish-service/System.IO.Compression.ZipFile.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.Compression.dll -> release/kJITWeb/publish-service/System.IO.Compression.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.FileSystem.AccessControl.dll -> release/kJITWeb/publish-service/System.IO.FileSystem.AccessControl.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.FileSystem.DriveInfo.dll -> release/kJITWeb/publish-service/System.IO.FileSystem.DriveInfo.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.FileSystem.Primitives.dll -> release/kJITWeb/publish-service/System.IO.FileSystem.Primitives.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.FileSystem.Watcher.dll -> release/kJITWeb/publish-service/System.IO.FileSystem.Watcher.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.FileSystem.dll -> release/kJITWeb/publish-service/System.IO.FileSystem.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.IsolatedStorage.dll -> release/kJITWeb/publish-service/System.IO.IsolatedStorage.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.MemoryMappedFiles.dll -> release/kJITWeb/publish-service/System.IO.MemoryMappedFiles.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.Pipelines.dll -> release/kJITWeb/publish-service/System.IO.Pipelines.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.Pipes.AccessControl.dll -> release/kJITWeb/publish-service/System.IO.Pipes.AccessControl.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.Pipes.dll -> release/kJITWeb/publish-service/System.IO.Pipes.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.UnmanagedMemoryStream.dll -> release/kJITWeb/publish-service/System.IO.UnmanagedMemoryStream.dll`
- `R100 -> release/kjibweb/publish-service/System.IO.dll -> release/kJITWeb/publish-service/System.IO.dll`
- `R100 -> release/kjibweb/publish-service/System.Linq.Expressions.dll -> release/kJITWeb/publish-service/System.Linq.Expressions.dll`
- `R100 -> release/kjibweb/publish-service/System.Linq.Parallel.dll -> release/kJITWeb/publish-service/System.Linq.Parallel.dll`
- `R100 -> release/kjibweb/publish-service/System.Linq.Queryable.dll -> release/kJITWeb/publish-service/System.Linq.Queryable.dll`
- `R100 -> release/kjibweb/publish-service/System.Linq.dll -> release/kJITWeb/publish-service/System.Linq.dll`
- `R100 -> release/kjibweb/publish-service/System.Memory.dll -> release/kJITWeb/publish-service/System.Memory.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.Http.Json.dll -> release/kJITWeb/publish-service/System.Net.Http.Json.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.Http.dll -> release/kJITWeb/publish-service/System.Net.Http.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.HttpListener.dll -> release/kJITWeb/publish-service/System.Net.HttpListener.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.Mail.dll -> release/kJITWeb/publish-service/System.Net.Mail.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.NameResolution.dll -> release/kJITWeb/publish-service/System.Net.NameResolution.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.NetworkInformation.dll -> release/kJITWeb/publish-service/System.Net.NetworkInformation.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.Ping.dll -> release/kJITWeb/publish-service/System.Net.Ping.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.Primitives.dll -> release/kJITWeb/publish-service/System.Net.Primitives.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.Quic.dll -> release/kJITWeb/publish-service/System.Net.Quic.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.Requests.dll -> release/kJITWeb/publish-service/System.Net.Requests.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.Security.dll -> release/kJITWeb/publish-service/System.Net.Security.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.ServicePoint.dll -> release/kJITWeb/publish-service/System.Net.ServicePoint.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.Sockets.dll -> release/kJITWeb/publish-service/System.Net.Sockets.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.WebClient.dll -> release/kJITWeb/publish-service/System.Net.WebClient.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.WebHeaderCollection.dll -> release/kJITWeb/publish-service/System.Net.WebHeaderCollection.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.WebProxy.dll -> release/kJITWeb/publish-service/System.Net.WebProxy.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.WebSockets.Client.dll -> release/kJITWeb/publish-service/System.Net.WebSockets.Client.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.WebSockets.dll -> release/kJITWeb/publish-service/System.Net.WebSockets.dll`
- `R100 -> release/kjibweb/publish-service/System.Net.dll -> release/kJITWeb/publish-service/System.Net.dll`
- `R100 -> release/kjibweb/publish-service/System.Numerics.Vectors.dll -> release/kJITWeb/publish-service/System.Numerics.Vectors.dll`
- `R100 -> release/kjibweb/publish-service/System.Numerics.dll -> release/kJITWeb/publish-service/System.Numerics.dll`
- `R100 -> release/kjibweb/publish-service/System.ObjectModel.dll -> release/kJITWeb/publish-service/System.ObjectModel.dll`
- `R100 -> release/kjibweb/publish-service/System.Private.CoreLib.dll -> release/kJITWeb/publish-service/System.Private.CoreLib.dll`
- `R100 -> release/kjibweb/publish-service/System.Private.DataContractSerialization.dll -> release/kJITWeb/publish-service/System.Private.DataContractSerialization.dll`
- `R100 -> release/kjibweb/publish-service/System.Private.Uri.dll -> release/kJITWeb/publish-service/System.Private.Uri.dll`
- `R100 -> release/kjibweb/publish-service/System.Private.Xml.Linq.dll -> release/kJITWeb/publish-service/System.Private.Xml.Linq.dll`
- `R100 -> release/kjibweb/publish-service/System.Private.Xml.dll -> release/kJITWeb/publish-service/System.Private.Xml.dll`
- `R100 -> release/kjibweb/publish-service/System.Reflection.DispatchProxy.dll -> release/kJITWeb/publish-service/System.Reflection.DispatchProxy.dll`
- `R100 -> release/kjibweb/publish-service/System.Reflection.Emit.ILGeneration.dll -> release/kJITWeb/publish-service/System.Reflection.Emit.ILGeneration.dll`
- `R100 -> release/kjibweb/publish-service/System.Reflection.Emit.Lightweight.dll -> release/kJITWeb/publish-service/System.Reflection.Emit.Lightweight.dll`
- `R100 -> release/kjibweb/publish-service/System.Reflection.Emit.dll -> release/kJITWeb/publish-service/System.Reflection.Emit.dll`
- `R100 -> release/kjibweb/publish-service/System.Reflection.Extensions.dll -> release/kJITWeb/publish-service/System.Reflection.Extensions.dll`
- `R100 -> release/kjibweb/publish-service/System.Reflection.Metadata.dll -> release/kJITWeb/publish-service/System.Reflection.Metadata.dll`
- `R100 -> release/kjibweb/publish-service/System.Reflection.Primitives.dll -> release/kJITWeb/publish-service/System.Reflection.Primitives.dll`
- `R100 -> release/kjibweb/publish-service/System.Reflection.TypeExtensions.dll -> release/kJITWeb/publish-service/System.Reflection.TypeExtensions.dll`
- `R100 -> release/kjibweb/publish-service/System.Reflection.dll -> release/kJITWeb/publish-service/System.Reflection.dll`
- `R100 -> release/kjibweb/publish-service/System.Resources.Reader.dll -> release/kJITWeb/publish-service/System.Resources.Reader.dll`
- `R100 -> release/kjibweb/publish-service/System.Resources.ResourceManager.dll -> release/kJITWeb/publish-service/System.Resources.ResourceManager.dll`
- `R100 -> release/kjibweb/publish-service/System.Resources.Writer.dll -> release/kJITWeb/publish-service/System.Resources.Writer.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.CompilerServices.Unsafe.dll -> release/kJITWeb/publish-service/System.Runtime.CompilerServices.Unsafe.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.CompilerServices.VisualC.dll -> release/kJITWeb/publish-service/System.Runtime.CompilerServices.VisualC.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.Extensions.dll -> release/kJITWeb/publish-service/System.Runtime.Extensions.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.Handles.dll -> release/kJITWeb/publish-service/System.Runtime.Handles.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.InteropServices.JavaScript.dll -> release/kJITWeb/publish-service/System.Runtime.InteropServices.JavaScript.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.InteropServices.RuntimeInformation.dll -> release/kJITWeb/publish-service/System.Runtime.InteropServices.RuntimeInformation.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.InteropServices.dll -> release/kJITWeb/publish-service/System.Runtime.InteropServices.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.Intrinsics.dll -> release/kJITWeb/publish-service/System.Runtime.Intrinsics.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.Loader.dll -> release/kJITWeb/publish-service/System.Runtime.Loader.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.Numerics.dll -> release/kJITWeb/publish-service/System.Runtime.Numerics.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.Serialization.Formatters.dll -> release/kJITWeb/publish-service/System.Runtime.Serialization.Formatters.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.Serialization.Json.dll -> release/kJITWeb/publish-service/System.Runtime.Serialization.Json.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.Serialization.Primitives.dll -> release/kJITWeb/publish-service/System.Runtime.Serialization.Primitives.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.Serialization.Xml.dll -> release/kJITWeb/publish-service/System.Runtime.Serialization.Xml.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.Serialization.dll -> release/kJITWeb/publish-service/System.Runtime.Serialization.dll`
- `R100 -> release/kjibweb/publish-service/System.Runtime.dll -> release/kJITWeb/publish-service/System.Runtime.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.AccessControl.dll -> release/kJITWeb/publish-service/System.Security.AccessControl.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Claims.dll -> release/kJITWeb/publish-service/System.Security.Claims.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Cryptography.Algorithms.dll -> release/kJITWeb/publish-service/System.Security.Cryptography.Algorithms.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Cryptography.Cng.dll -> release/kJITWeb/publish-service/System.Security.Cryptography.Cng.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Cryptography.Csp.dll -> release/kJITWeb/publish-service/System.Security.Cryptography.Csp.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Cryptography.Encoding.dll -> release/kJITWeb/publish-service/System.Security.Cryptography.Encoding.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Cryptography.OpenSsl.dll -> release/kJITWeb/publish-service/System.Security.Cryptography.OpenSsl.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Cryptography.Pkcs.dll -> release/kJITWeb/publish-service/System.Security.Cryptography.Pkcs.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Cryptography.Primitives.dll -> release/kJITWeb/publish-service/System.Security.Cryptography.Primitives.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Cryptography.X509Certificates.dll -> release/kJITWeb/publish-service/System.Security.Cryptography.X509Certificates.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Cryptography.Xml.dll -> release/kJITWeb/publish-service/System.Security.Cryptography.Xml.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Cryptography.dll -> release/kJITWeb/publish-service/System.Security.Cryptography.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Principal.Windows.dll -> release/kJITWeb/publish-service/System.Security.Principal.Windows.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.Principal.dll -> release/kJITWeb/publish-service/System.Security.Principal.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.SecureString.dll -> release/kJITWeb/publish-service/System.Security.SecureString.dll`
- `R100 -> release/kjibweb/publish-service/System.Security.dll -> release/kJITWeb/publish-service/System.Security.dll`
- `R100 -> release/kjibweb/publish-service/System.ServiceModel.Web.dll -> release/kJITWeb/publish-service/System.ServiceModel.Web.dll`
- `R100 -> release/kjibweb/publish-service/System.ServiceProcess.ServiceController.dll -> release/kJITWeb/publish-service/System.ServiceProcess.ServiceController.dll`
- `R100 -> release/kjibweb/publish-service/System.ServiceProcess.dll -> release/kJITWeb/publish-service/System.ServiceProcess.dll`
- `R100 -> release/kjibweb/publish-service/System.Text.Encoding.CodePages.dll -> release/kJITWeb/publish-service/System.Text.Encoding.CodePages.dll`
- `R100 -> release/kjibweb/publish-service/System.Text.Encoding.Extensions.dll -> release/kJITWeb/publish-service/System.Text.Encoding.Extensions.dll`
- `R100 -> release/kjibweb/publish-service/System.Text.Encoding.dll -> release/kJITWeb/publish-service/System.Text.Encoding.dll`
- `R100 -> release/kjibweb/publish-service/System.Text.Encodings.Web.dll -> release/kJITWeb/publish-service/System.Text.Encodings.Web.dll`
- `R100 -> release/kjibweb/publish-service/System.Text.Json.dll -> release/kJITWeb/publish-service/System.Text.Json.dll`
- `R100 -> release/kjibweb/publish-service/System.Text.RegularExpressions.dll -> release/kJITWeb/publish-service/System.Text.RegularExpressions.dll`
- `R100 -> release/kjibweb/publish-service/System.Threading.Channels.dll -> release/kJITWeb/publish-service/System.Threading.Channels.dll`
- `R100 -> release/kjibweb/publish-service/System.Threading.Overlapped.dll -> release/kJITWeb/publish-service/System.Threading.Overlapped.dll`
- `R100 -> release/kjibweb/publish-service/System.Threading.RateLimiting.dll -> release/kJITWeb/publish-service/System.Threading.RateLimiting.dll`
- `R100 -> release/kjibweb/publish-service/System.Threading.Tasks.Dataflow.dll -> release/kJITWeb/publish-service/System.Threading.Tasks.Dataflow.dll`
- `R100 -> release/kjibweb/publish-service/System.Threading.Tasks.Extensions.dll -> release/kJITWeb/publish-service/System.Threading.Tasks.Extensions.dll`
- `R100 -> release/kjibweb/publish-service/System.Threading.Tasks.Parallel.dll -> release/kJITWeb/publish-service/System.Threading.Tasks.Parallel.dll`
- `R100 -> release/kjibweb/publish-service/System.Threading.Tasks.dll -> release/kJITWeb/publish-service/System.Threading.Tasks.dll`
- `R100 -> release/kjibweb/publish-service/System.Threading.Thread.dll -> release/kJITWeb/publish-service/System.Threading.Thread.dll`
- `R100 -> release/kjibweb/publish-service/System.Threading.ThreadPool.dll -> release/kJITWeb/publish-service/System.Threading.ThreadPool.dll`
- `R100 -> release/kjibweb/publish-service/System.Threading.Timer.dll -> release/kJITWeb/publish-service/System.Threading.Timer.dll`
- `R100 -> release/kjibweb/publish-service/System.Threading.dll -> release/kJITWeb/publish-service/System.Threading.dll`
- `R100 -> release/kjibweb/publish-service/System.Transactions.Local.dll -> release/kJITWeb/publish-service/System.Transactions.Local.dll`
- `R100 -> release/kjibweb/publish-service/System.Transactions.dll -> release/kJITWeb/publish-service/System.Transactions.dll`
- `R100 -> release/kjibweb/publish-service/System.ValueTuple.dll -> release/kJITWeb/publish-service/System.ValueTuple.dll`
- `R100 -> release/kjibweb/publish-service/System.Web.HttpUtility.dll -> release/kJITWeb/publish-service/System.Web.HttpUtility.dll`
- `R100 -> release/kjibweb/publish-service/System.Web.dll -> release/kJITWeb/publish-service/System.Web.dll`
- `R100 -> release/kjibweb/publish-service/System.Windows.dll -> release/kJITWeb/publish-service/System.Windows.dll`
- `R100 -> release/kjibweb/publish-service/System.Xml.Linq.dll -> release/kJITWeb/publish-service/System.Xml.Linq.dll`
- `R100 -> release/kjibweb/publish-service/System.Xml.ReaderWriter.dll -> release/kJITWeb/publish-service/System.Xml.ReaderWriter.dll`
- `R100 -> release/kjibweb/publish-service/System.Xml.Serialization.dll -> release/kJITWeb/publish-service/System.Xml.Serialization.dll`
- `R100 -> release/kjibweb/publish-service/System.Xml.XDocument.dll -> release/kJITWeb/publish-service/System.Xml.XDocument.dll`
- `R100 -> release/kjibweb/publish-service/System.Xml.XPath.XDocument.dll -> release/kJITWeb/publish-service/System.Xml.XPath.XDocument.dll`
- `R100 -> release/kjibweb/publish-service/System.Xml.XPath.dll -> release/kJITWeb/publish-service/System.Xml.XPath.dll`
- `R100 -> release/kjibweb/publish-service/System.Xml.XmlDocument.dll -> release/kJITWeb/publish-service/System.Xml.XmlDocument.dll`
- `R100 -> release/kjibweb/publish-service/System.Xml.XmlSerializer.dll -> release/kJITWeb/publish-service/System.Xml.XmlSerializer.dll`
- `R100 -> release/kjibweb/publish-service/System.Xml.dll -> release/kJITWeb/publish-service/System.Xml.dll`
- `R100 -> release/kjibweb/publish-service/System.dll -> release/kJITWeb/publish-service/System.dll`
- `R100 -> release/kjibweb/publish-service/WindowsBase.dll -> release/kJITWeb/publish-service/WindowsBase.dll`
- `R100 -> release/kjibweb/publish-service/app_data/JIT.test.config -> release/kJITWeb/publish-service/app_data/JIT.test.config`
- `R100 -> release/kjibweb/publish-service/appsettings.Production.json -> release/kJITWeb/publish-service/appsettings.Production.json`
- `R100 -> release/kjibweb/publish-service/appsettings.json -> release/kJITWeb/publish-service/appsettings.json`
- `R100 -> release/kjibweb/publish-service/aspnetcorev2_inprocess.dll -> release/kJITWeb/publish-service/aspnetcorev2_inprocess.dll`
- `R100 -> release/kjibweb/publish-service/clretwrc.dll -> release/kJITWeb/publish-service/clretwrc.dll`
- `R100 -> release/kjibweb/publish-service/clrgc.dll -> release/kJITWeb/publish-service/clrgc.dll`
- `R100 -> release/kjibweb/publish-service/clrjit.dll -> release/kJITWeb/publish-service/clrjit.dll`
- `R100 -> release/kjibweb/publish-service/coreclr.dll -> release/kJITWeb/publish-service/coreclr.dll`
- `R100 -> release/kjibweb/publish-service/createdump.exe -> release/kJITWeb/publish-service/createdump.exe`
- `A -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `A -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `R100 -> release/kjibweb/publish-service/hostfxr.dll -> release/kJITWeb/publish-service/hostfxr.dll`
- `R100 -> release/kjibweb/publish-service/hostpolicy.dll -> release/kJITWeb/publish-service/hostpolicy.dll`
- `R100 -> release/kjibweb/publish-service/mscordaccore.dll -> release/kJITWeb/publish-service/mscordaccore.dll`
- `R100 -> release/kjibweb/publish-service/mscordaccore_amd64_amd64_8.0.2726.22922.dll -> release/kJITWeb/publish-service/mscordaccore_amd64_amd64_8.0.2726.22922.dll`
- `R100 -> release/kjibweb/publish-service/mscordbi.dll -> release/kJITWeb/publish-service/mscordbi.dll`
- `R100 -> release/kjibweb/publish-service/mscorlib.dll -> release/kJITWeb/publish-service/mscorlib.dll`
- `R100 -> release/kjibweb/publish-service/mscorrc.dll -> release/kJITWeb/publish-service/mscorrc.dll`
- `R100 -> release/kjibweb/publish-service/msquic.dll -> release/kJITWeb/publish-service/msquic.dll`
- `R100 -> release/kjibweb/publish-service/netstandard.dll -> release/kJITWeb/publish-service/netstandard.dll`
- `R100 -> release/kjibweb/publish-service/web.config -> release/kJITWeb/publish-service/web.config`
- `R100 -> release/kjibweb/publish-service/wwwroot/images/kjitlogo.png -> release/kJITWeb/publish-service/wwwroot/images/kjitlogo.png`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/bootstrap/css/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/bootstrap/css/bootstrap.min.css`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation-unobtrusive/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation/jquery.validate.min.js`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery/jquery.min.js`
- `A -> release/kJITWeb/set-kjitweb-allowedclient.ps1`
- `A -> release/kJITWeb/update-kjitweb.ps1`
- `D -> release/kjibweb/publish-service/KjitWeb.dll`
- `D -> release/kjibweb/publish-service/KjitWeb.pdb`
- `D -> release/kjibweb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `D -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.Negotiate.dll`
- `D -> release/kjibweb/publish-service/Microsoft.AspNetCore.Connections.Abstractions.dll`
- `D -> release/kjibweb/publish-service/Microsoft.Extensions.Features.dll`
- `D -> release/kjibweb/publish-service/de/KjitWeb.resources.dll`
- `D -> release/kjibweb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/0.1/just-in-time-configuration.psm1`
- `M -> src/C#/Kjitweb/Controllers/HomeController.cs`
- `M -> src/C#/Kjitweb/KjitWeb.csproj`
- `M -> src/C#/Kjitweb/Program.cs`
- `M -> src/C#/Kjitweb/Resources/SharedResource.de.resx`
- `M -> src/C#/Kjitweb/Resources/SharedResource.en.resx`
- `A -> src/C#/Kjitweb/Services/EventLogHealthMonitor.cs`
- `A -> src/C#/Kjitweb/Services/EventLogHealthSnapshot.cs`
- `A -> src/C#/Kjitweb/Services/IEventLogHealthMonitor.cs`
- `M -> src/C#/Kjitweb/Views/Home/Index.cshtml`
- `M -> src/C#/Kjitweb/Views/Shared/_Layout.cshtml`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `A -> src/C#/Kjitweb/set-kjitweb-allowedclient.ps1`
- `A -> src/C#/Kjitweb/update-kjitweb.ps1`
- `A -> src/C#/Kjitweb/wwwroot/lib/bootstrap/css/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/bootstrap/css/bootstrap.min.css`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation-unobtrusive/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation/jquery.validate.min.js`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery/jquery.min.js`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/install-JIT.ps1`
- `M -> src/Powershell/TestEnvironment/Install-T1JitTestInstallation.ps1`
- `M -> src/Powershell/modules/0.1/just-in-time-configuration.psm1`
- `M -> tmp_ps51_test.ps1`

## 2026-09-08 21:48:29 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:b0d0066a780a8298251d17ca4613821ab720727a -->
- `b0d0066` Fix KjitWeb delegation and automate release builds
<!-- commit:9196ebc83b70080337531ea127426c4e6bed5d09 -->
- `9196ebc` Fix relative KjitWeb search bases

Changed files:

- `M -> .githooks/pre-commit.ps1`
- `M -> .githooks/pre-push.ps1`
- `M -> VERSION`
- `M -> build/release_build.ps1`
- `M -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `M -> release/ElevateUser.ps1`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kjibweb/appsettings.Production.json`
- `M -> release/kjibweb/appsettings.json`
- `M -> release/kjibweb/install-kjitweb.ps1`
- `M -> release/kjibweb/publish-service/KjitWeb.dll`
- `M -> release/kjibweb/publish-service/KjitWeb.exe`
- `M -> release/kjibweb/publish-service/KjitWeb.pdb`
- `M -> release/kjibweb/publish-service/appsettings.Production.json`
- `M -> release/kjibweb/publish-service/appsettings.json`
- `M -> release/kjibweb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kjibweb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> release/modules/0.1/just-in-time-configuration.psm1`
- `M -> release/modules/0.1/just-in-time-request.psm1`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/C#/Kjitweb/Services/ActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/configuration.cs`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`

## 2026-09-08 20:36:46 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:eb4021a8bcf981deb392787c799e7f831c0bac81 -->
- `eb4021a` Prevent transient delegation config reads

Changed files:

- `M -> VERSION`
- `M -> file-versions.json`
- `M -> src/C#/Kjitweb/Services/configuration.cs`
- `M -> src/Powershell/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-configuration.psm1`

## 2026-09-08 20:01:27 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:0b30e312af34d4539b15cadb4255a0077064e6af -->
- `0b30e31` Secure KjitWeb access and logging

Changed files:

- `M -> README.md`
- `M -> VERSION`
- `M -> file-versions.json`
- `M -> release/kjibweb/publish-service/appsettings.json`
- `M -> src/C#/Kjitweb/Program.cs`
- `M -> src/C#/Kjitweb/Services/DebugLogFileWriter.cs`
- `A -> src/C#/Kjitweb/Services/MutualTlsCertificateValidator.cs`
- `A -> src/C#/Kjitweb/Services/MutualTlsOptions.cs`
- `M -> src/C#/Kjitweb/appsettings.Development.json`
- `M -> src/C#/Kjitweb/appsettings.Production.json`
- `M -> src/C#/Kjitweb/appsettings.json`
- `M -> src/C#/Kjitweb/publish-service/appsettings.json`
- `M -> src/Powershell/TestEnvironment/New-T1JitTestEnvironment.ps1`
- `M -> src/Powershell/TestEnvironment/Test-Environment.md`

## 2026-09-08 19:22:18 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:1f9fadf40e9bb4d24417a9fa62372ddadff55f06 -->
- `1f9fadf` Harden JIT provisioning and request handling

Changed files:

- `M -> README.md`
- `M -> VERSION`
- `M -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `M -> release/ElevateUser.ps1`
- `M -> release/Tier1LocalAdminGroup.ps1`
- `M -> release/modules/0.1/just-in-time-request.psm1`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/ElevateUser.ps1`
- `M -> src/Powershell/Scripts/Tier1LocalAdminGroup.ps1`
- `M -> src/Powershell/modules/0.1/just-in-time-request.psm1`

## 2026-09-08 08:16:47 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:2fa36140999b44cda8d554433a2658a1acd6e2e2 -->
- `2fa3614` Document Config-JIT workflow

Changed files:

- `M -> VERSION`
- `M -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`

## 2026-09-07 23:55:03 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:4c3754475610a98d10a1db135dc6c2264942bb06 -->
- `4c37544` Improve multi-domain search diagnostics

Changed files:

- `M -> VERSION`
- `M -> docs/Events.md`
- `M -> file-versions.json`
- `M -> release/Tier1LocalAdminGroup.ps1`
- `M -> src/Powershell/Scripts/README.md`
- `M -> src/Powershell/Scripts/Tier1LocalAdminGroup.ps1`

## 2026-09-07 23:37:47 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:12a5b6ebda697b0d4f783d59107fc61457b0d59e -->
- `12a5b6e` Harden JIT installation and diagnostics

Changed files:

- `M -> VERSION`
- `M -> build/release_build.ps1`
- `M -> docs/Events.md`
- `M -> docs/Installation.md`
- `M -> docs/config.jit.example`
- `M -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `M -> release/Tier1LocalAdminGroup.ps1`
- `M -> release/install-JIT.ps1`
- `M -> release/kjibweb/install-kjitweb.ps1`
- `M -> release/kjibweb/publish-service/KjitWeb.deps.json`
- `M -> release/kjibweb/publish-service/KjitWeb.dll`
- `M -> release/kjibweb/publish-service/KjitWeb.exe`
- `M -> release/kjibweb/publish-service/KjitWeb.pdb`
- `M -> release/kjibweb/publish-service/KjitWeb.runtimeconfig.json`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Antiforgery.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.BearerToken.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.Cookies.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.Core.dll`
- `M -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.Negotiate.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.OAuth.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authorization.Policy.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authorization.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.Authorization.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.Endpoints.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.Forms.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.Server.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.Web.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Components.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Connections.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.CookiePolicy.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Cors.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Cryptography.Internal.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Cryptography.KeyDerivation.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.DataProtection.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.DataProtection.Extensions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.DataProtection.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Diagnostics.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Diagnostics.HealthChecks.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Diagnostics.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.HostFiltering.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Hosting.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Hosting.Server.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Hosting.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Html.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Connections.Common.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Connections.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Extensions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Features.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.Results.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Http.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.HttpLogging.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.HttpOverrides.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.HttpsPolicy.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Identity.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Localization.Routing.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Localization.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Metadata.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.ApiExplorer.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Core.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Cors.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.DataAnnotations.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Json.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Xml.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Localization.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.Razor.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.RazorPages.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.TagHelpers.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.ViewFeatures.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Mvc.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.OutputCaching.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.RateLimiting.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Razor.Runtime.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Razor.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.RequestDecompression.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.ResponseCaching.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.ResponseCaching.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.ResponseCompression.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Rewrite.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Routing.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Routing.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.HttpSys.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.IIS.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.IISIntegration.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Core.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.NamedPipes.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Quic.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.Session.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.SignalR.Common.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.SignalR.Core.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.SignalR.Protocols.Json.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.SignalR.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.StaticFiles.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.WebSockets.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.WebUtilities.dll`
- `A -> release/kjibweb/publish-service/Microsoft.AspNetCore.dll`
- `A -> release/kjibweb/publish-service/Microsoft.CSharp.dll`
- `A -> release/kjibweb/publish-service/Microsoft.DiaSymReader.Native.amd64.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Caching.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Caching.Memory.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.Binder.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.CommandLine.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.EnvironmentVariables.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.FileExtensions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.Ini.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.Json.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.KeyPerFile.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.UserSecrets.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.Xml.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Configuration.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.DependencyInjection.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.DependencyInjection.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Diagnostics.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Diagnostics.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Features.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.FileProviders.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.FileProviders.Composite.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.FileProviders.Embedded.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.FileProviders.Physical.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.FileSystemGlobbing.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Hosting.Abstractions.dll`
- `M -> release/kjibweb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Hosting.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Http.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Identity.Core.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Identity.Stores.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Localization.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Localization.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.Abstractions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.Configuration.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.Console.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.Debug.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.EventLog.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.EventSource.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.TraceSource.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Logging.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.ObjectPool.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Options.ConfigurationExtensions.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Options.DataAnnotations.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Options.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.Primitives.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Extensions.WebEncoders.dll`
- `A -> release/kjibweb/publish-service/Microsoft.JSInterop.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Net.Http.Headers.dll`
- `A -> release/kjibweb/publish-service/Microsoft.VisualBasic.Core.dll`
- `A -> release/kjibweb/publish-service/Microsoft.VisualBasic.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Win32.Primitives.dll`
- `A -> release/kjibweb/publish-service/Microsoft.Win32.Registry.dll`
- `D -> release/kjibweb/publish-service/Novell.Directory.Ldap.NETStandard.dll`
- `A -> release/kjibweb/publish-service/System.AppContext.dll`
- `A -> release/kjibweb/publish-service/System.Buffers.dll`
- `A -> release/kjibweb/publish-service/System.Collections.Concurrent.dll`
- `A -> release/kjibweb/publish-service/System.Collections.Immutable.dll`
- `A -> release/kjibweb/publish-service/System.Collections.NonGeneric.dll`
- `A -> release/kjibweb/publish-service/System.Collections.Specialized.dll`
- `A -> release/kjibweb/publish-service/System.Collections.dll`
- `A -> release/kjibweb/publish-service/System.ComponentModel.Annotations.dll`
- `A -> release/kjibweb/publish-service/System.ComponentModel.DataAnnotations.dll`
- `A -> release/kjibweb/publish-service/System.ComponentModel.EventBasedAsync.dll`
- `A -> release/kjibweb/publish-service/System.ComponentModel.Primitives.dll`
- `A -> release/kjibweb/publish-service/System.ComponentModel.TypeConverter.dll`
- `A -> release/kjibweb/publish-service/System.ComponentModel.dll`
- `A -> release/kjibweb/publish-service/System.Configuration.dll`
- `A -> release/kjibweb/publish-service/System.Console.dll`
- `A -> release/kjibweb/publish-service/System.Core.dll`
- `A -> release/kjibweb/publish-service/System.Data.Common.dll`
- `A -> release/kjibweb/publish-service/System.Data.DataSetExtensions.dll`
- `A -> release/kjibweb/publish-service/System.Data.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.Contracts.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.Debug.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.DiagnosticSource.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.EventLog.Messages.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.EventLog.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.FileVersionInfo.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.Process.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.StackTrace.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.TextWriterTraceListener.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.Tools.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.TraceSource.dll`
- `A -> release/kjibweb/publish-service/System.Diagnostics.Tracing.dll`
- `M -> release/kjibweb/publish-service/System.DirectoryServices.Protocols.dll`
- `A -> release/kjibweb/publish-service/System.Drawing.Primitives.dll`
- `A -> release/kjibweb/publish-service/System.Drawing.dll`
- `A -> release/kjibweb/publish-service/System.Dynamic.Runtime.dll`
- `A -> release/kjibweb/publish-service/System.Formats.Asn1.dll`
- `A -> release/kjibweb/publish-service/System.Formats.Tar.dll`
- `A -> release/kjibweb/publish-service/System.Globalization.Calendars.dll`
- `A -> release/kjibweb/publish-service/System.Globalization.Extensions.dll`
- `A -> release/kjibweb/publish-service/System.Globalization.dll`
- `A -> release/kjibweb/publish-service/System.IO.Compression.Brotli.dll`
- `A -> release/kjibweb/publish-service/System.IO.Compression.FileSystem.dll`
- `A -> release/kjibweb/publish-service/System.IO.Compression.Native.dll`
- `A -> release/kjibweb/publish-service/System.IO.Compression.ZipFile.dll`
- `A -> release/kjibweb/publish-service/System.IO.Compression.dll`
- `A -> release/kjibweb/publish-service/System.IO.FileSystem.AccessControl.dll`
- `A -> release/kjibweb/publish-service/System.IO.FileSystem.DriveInfo.dll`
- `A -> release/kjibweb/publish-service/System.IO.FileSystem.Primitives.dll`
- `A -> release/kjibweb/publish-service/System.IO.FileSystem.Watcher.dll`
- `A -> release/kjibweb/publish-service/System.IO.FileSystem.dll`
- `A -> release/kjibweb/publish-service/System.IO.IsolatedStorage.dll`
- `A -> release/kjibweb/publish-service/System.IO.MemoryMappedFiles.dll`
- `A -> release/kjibweb/publish-service/System.IO.Pipelines.dll`
- `A -> release/kjibweb/publish-service/System.IO.Pipes.AccessControl.dll`
- `A -> release/kjibweb/publish-service/System.IO.Pipes.dll`
- `A -> release/kjibweb/publish-service/System.IO.UnmanagedMemoryStream.dll`
- `A -> release/kjibweb/publish-service/System.IO.dll`
- `A -> release/kjibweb/publish-service/System.Linq.Expressions.dll`
- `A -> release/kjibweb/publish-service/System.Linq.Parallel.dll`
- `A -> release/kjibweb/publish-service/System.Linq.Queryable.dll`
- `A -> release/kjibweb/publish-service/System.Linq.dll`
- `A -> release/kjibweb/publish-service/System.Memory.dll`
- `A -> release/kjibweb/publish-service/System.Net.Http.Json.dll`
- `A -> release/kjibweb/publish-service/System.Net.Http.dll`
- `A -> release/kjibweb/publish-service/System.Net.HttpListener.dll`
- `A -> release/kjibweb/publish-service/System.Net.Mail.dll`
- `A -> release/kjibweb/publish-service/System.Net.NameResolution.dll`
- `A -> release/kjibweb/publish-service/System.Net.NetworkInformation.dll`
- `A -> release/kjibweb/publish-service/System.Net.Ping.dll`
- `A -> release/kjibweb/publish-service/System.Net.Primitives.dll`
- `A -> release/kjibweb/publish-service/System.Net.Quic.dll`
- `A -> release/kjibweb/publish-service/System.Net.Requests.dll`
- `A -> release/kjibweb/publish-service/System.Net.Security.dll`
- `A -> release/kjibweb/publish-service/System.Net.ServicePoint.dll`
- `A -> release/kjibweb/publish-service/System.Net.Sockets.dll`
- `A -> release/kjibweb/publish-service/System.Net.WebClient.dll`
- `A -> release/kjibweb/publish-service/System.Net.WebHeaderCollection.dll`
- `A -> release/kjibweb/publish-service/System.Net.WebProxy.dll`
- `A -> release/kjibweb/publish-service/System.Net.WebSockets.Client.dll`
- `A -> release/kjibweb/publish-service/System.Net.WebSockets.dll`
- `A -> release/kjibweb/publish-service/System.Net.dll`
- `A -> release/kjibweb/publish-service/System.Numerics.Vectors.dll`
- `A -> release/kjibweb/publish-service/System.Numerics.dll`
- `A -> release/kjibweb/publish-service/System.ObjectModel.dll`
- `A -> release/kjibweb/publish-service/System.Private.CoreLib.dll`
- `A -> release/kjibweb/publish-service/System.Private.DataContractSerialization.dll`
- `A -> release/kjibweb/publish-service/System.Private.Uri.dll`
- `A -> release/kjibweb/publish-service/System.Private.Xml.Linq.dll`
- `A -> release/kjibweb/publish-service/System.Private.Xml.dll`
- `A -> release/kjibweb/publish-service/System.Reflection.DispatchProxy.dll`
- `A -> release/kjibweb/publish-service/System.Reflection.Emit.ILGeneration.dll`
- `A -> release/kjibweb/publish-service/System.Reflection.Emit.Lightweight.dll`
- `A -> release/kjibweb/publish-service/System.Reflection.Emit.dll`
- `A -> release/kjibweb/publish-service/System.Reflection.Extensions.dll`
- `A -> release/kjibweb/publish-service/System.Reflection.Metadata.dll`
- `A -> release/kjibweb/publish-service/System.Reflection.Primitives.dll`
- `A -> release/kjibweb/publish-service/System.Reflection.TypeExtensions.dll`
- `A -> release/kjibweb/publish-service/System.Reflection.dll`
- `A -> release/kjibweb/publish-service/System.Resources.Reader.dll`
- `A -> release/kjibweb/publish-service/System.Resources.ResourceManager.dll`
- `A -> release/kjibweb/publish-service/System.Resources.Writer.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.CompilerServices.Unsafe.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.CompilerServices.VisualC.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.Extensions.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.Handles.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.InteropServices.JavaScript.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.InteropServices.RuntimeInformation.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.InteropServices.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.Intrinsics.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.Loader.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.Numerics.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.Serialization.Formatters.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.Serialization.Json.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.Serialization.Primitives.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.Serialization.Xml.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.Serialization.dll`
- `A -> release/kjibweb/publish-service/System.Runtime.dll`
- `A -> release/kjibweb/publish-service/System.Security.AccessControl.dll`
- `A -> release/kjibweb/publish-service/System.Security.Claims.dll`
- `A -> release/kjibweb/publish-service/System.Security.Cryptography.Algorithms.dll`
- `A -> release/kjibweb/publish-service/System.Security.Cryptography.Cng.dll`
- `A -> release/kjibweb/publish-service/System.Security.Cryptography.Csp.dll`
- `A -> release/kjibweb/publish-service/System.Security.Cryptography.Encoding.dll`
- `A -> release/kjibweb/publish-service/System.Security.Cryptography.OpenSsl.dll`
- `A -> release/kjibweb/publish-service/System.Security.Cryptography.Pkcs.dll`
- `A -> release/kjibweb/publish-service/System.Security.Cryptography.Primitives.dll`
- `A -> release/kjibweb/publish-service/System.Security.Cryptography.X509Certificates.dll`
- `A -> release/kjibweb/publish-service/System.Security.Cryptography.Xml.dll`
- `A -> release/kjibweb/publish-service/System.Security.Cryptography.dll`
- `A -> release/kjibweb/publish-service/System.Security.Principal.Windows.dll`
- `A -> release/kjibweb/publish-service/System.Security.Principal.dll`
- `A -> release/kjibweb/publish-service/System.Security.SecureString.dll`
- `A -> release/kjibweb/publish-service/System.Security.dll`
- `A -> release/kjibweb/publish-service/System.ServiceModel.Web.dll`
- `M -> release/kjibweb/publish-service/System.ServiceProcess.ServiceController.dll`
- `A -> release/kjibweb/publish-service/System.ServiceProcess.dll`
- `A -> release/kjibweb/publish-service/System.Text.Encoding.CodePages.dll`
- `A -> release/kjibweb/publish-service/System.Text.Encoding.Extensions.dll`
- `A -> release/kjibweb/publish-service/System.Text.Encoding.dll`
- `A -> release/kjibweb/publish-service/System.Text.Encodings.Web.dll`
- `A -> release/kjibweb/publish-service/System.Text.Json.dll`
- `A -> release/kjibweb/publish-service/System.Text.RegularExpressions.dll`
- `A -> release/kjibweb/publish-service/System.Threading.Channels.dll`
- `A -> release/kjibweb/publish-service/System.Threading.Overlapped.dll`
- `A -> release/kjibweb/publish-service/System.Threading.RateLimiting.dll`
- `A -> release/kjibweb/publish-service/System.Threading.Tasks.Dataflow.dll`
- `A -> release/kjibweb/publish-service/System.Threading.Tasks.Extensions.dll`
- `A -> release/kjibweb/publish-service/System.Threading.Tasks.Parallel.dll`
- `A -> release/kjibweb/publish-service/System.Threading.Tasks.dll`
- `A -> release/kjibweb/publish-service/System.Threading.Thread.dll`
- `A -> release/kjibweb/publish-service/System.Threading.ThreadPool.dll`
- `A -> release/kjibweb/publish-service/System.Threading.Timer.dll`
- `A -> release/kjibweb/publish-service/System.Threading.dll`
- `A -> release/kjibweb/publish-service/System.Transactions.Local.dll`
- `A -> release/kjibweb/publish-service/System.Transactions.dll`
- `A -> release/kjibweb/publish-service/System.ValueTuple.dll`
- `A -> release/kjibweb/publish-service/System.Web.HttpUtility.dll`
- `A -> release/kjibweb/publish-service/System.Web.dll`
- `A -> release/kjibweb/publish-service/System.Windows.dll`
- `A -> release/kjibweb/publish-service/System.Xml.Linq.dll`
- `A -> release/kjibweb/publish-service/System.Xml.ReaderWriter.dll`
- `A -> release/kjibweb/publish-service/System.Xml.Serialization.dll`
- `A -> release/kjibweb/publish-service/System.Xml.XDocument.dll`
- `A -> release/kjibweb/publish-service/System.Xml.XPath.XDocument.dll`
- `A -> release/kjibweb/publish-service/System.Xml.XPath.dll`
- `A -> release/kjibweb/publish-service/System.Xml.XmlDocument.dll`
- `A -> release/kjibweb/publish-service/System.Xml.XmlSerializer.dll`
- `A -> release/kjibweb/publish-service/System.Xml.dll`
- `A -> release/kjibweb/publish-service/System.dll`
- `A -> release/kjibweb/publish-service/WindowsBase.dll`
- `D -> release/kjibweb/publish-service/appsettings.Development.json`
- `A -> release/kjibweb/publish-service/aspnetcorev2_inprocess.dll`
- `A -> release/kjibweb/publish-service/clretwrc.dll`
- `A -> release/kjibweb/publish-service/clrgc.dll`
- `A -> release/kjibweb/publish-service/clrjit.dll`
- `A -> release/kjibweb/publish-service/coreclr.dll`
- `A -> release/kjibweb/publish-service/createdump.exe`
- `M -> release/kjibweb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kjibweb/publish-service/en/KjitWeb.resources.dll`
- `A -> release/kjibweb/publish-service/hostfxr.dll`
- `A -> release/kjibweb/publish-service/hostpolicy.dll`
- `A -> release/kjibweb/publish-service/mscordaccore.dll`
- `A -> release/kjibweb/publish-service/mscordaccore_amd64_amd64_8.0.2726.22922.dll`
- `A -> release/kjibweb/publish-service/mscordbi.dll`
- `A -> release/kjibweb/publish-service/mscorlib.dll`
- `A -> release/kjibweb/publish-service/mscorrc.dll`
- `A -> release/kjibweb/publish-service/msquic.dll`
- `A -> release/kjibweb/publish-service/netstandard.dll`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.deps.json`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.runtimeconfig.json`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.staticwebassets.endpoints.json`
- `D -> release/kjibweb/publish-service/publish/appsettings.Development.json`
- `D -> release/kjibweb/publish-service/publish/appsettings.json`
- `D -> release/kjibweb/publish-service/publish/web.config`
- `D -> release/kjibweb/publish-service/runtimes/linux/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/osx/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.ServiceProcess.ServiceController.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> src/C#/KjitCore/Models/JitConfigurationObject.cs`
- `M -> src/C#/KjitCore/Services/JitConfigurationReader.cs`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.deps.json`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.dll`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.exe`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.pdb`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.runtimeconfig.json`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Antiforgery.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.BearerToken.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Cookies.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Core.dll`
- `M -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Negotiate.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.OAuth.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authorization.Policy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authorization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Authorization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Endpoints.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Forms.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Server.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Connections.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.CookiePolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cors.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cryptography.Internal.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cryptography.KeyDerivation.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.HealthChecks.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HostFiltering.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.Server.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Html.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Connections.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Connections.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Features.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Results.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpLogging.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpOverrides.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpsPolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Identity.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Localization.Routing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Metadata.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.ApiExplorer.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Cors.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Razor.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.RazorPages.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.TagHelpers.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.ViewFeatures.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.OutputCaching.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.RateLimiting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Razor.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Razor.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.RequestDecompression.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCaching.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCaching.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCompression.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Rewrite.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Routing.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Routing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.HttpSys.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.IIS.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.IISIntegration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.NamedPipes.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Quic.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Session.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Protocols.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.StaticFiles.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.WebSockets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.WebUtilities.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.CSharp.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.DiaSymReader.Native.amd64.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Caching.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Caching.Memory.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Binder.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.CommandLine.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.EnvironmentVariables.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.FileExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Ini.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.KeyPerFile.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.UserSecrets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.DependencyInjection.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.DependencyInjection.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Features.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Composite.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Embedded.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Physical.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileSystemGlobbing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.Abstractions.dll`
- `M -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Identity.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Identity.Stores.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Localization.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Console.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Debug.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.EventLog.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.EventSource.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.TraceSource.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.ObjectPool.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.ConfigurationExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.WebEncoders.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.JSInterop.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Net.Http.Headers.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.VisualBasic.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.VisualBasic.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Win32.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Win32.Registry.dll`
- `D -> src/C#/Kjitweb/publish-service/Novell.Directory.Ldap.NETStandard.dll`
- `A -> src/C#/Kjitweb/publish-service/System.AppContext.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Buffers.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Concurrent.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Immutable.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.NonGeneric.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Specialized.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.Annotations.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.EventBasedAsync.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.TypeConverter.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Console.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.DataSetExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Contracts.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Debug.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.DiagnosticSource.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.EventLog.Messages.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.EventLog.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.FileVersionInfo.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Process.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.StackTrace.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.TextWriterTraceListener.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Tools.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.TraceSource.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Tracing.dll`
- `M -> src/C#/Kjitweb/publish-service/System.DirectoryServices.Protocols.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Drawing.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Drawing.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Dynamic.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Formats.Asn1.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Formats.Tar.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.Calendars.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.Brotli.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.FileSystem.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.Native.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.ZipFile.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.DriveInfo.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.Watcher.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.IsolatedStorage.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.MemoryMappedFiles.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipelines.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipes.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipes.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.UnmanagedMemoryStream.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Expressions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Parallel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Queryable.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Memory.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Http.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.HttpListener.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Mail.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.NameResolution.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.NetworkInformation.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Ping.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Quic.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Requests.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Security.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.ServicePoint.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Sockets.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebClient.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebHeaderCollection.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebProxy.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebSockets.Client.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebSockets.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Numerics.Vectors.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Numerics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ObjectModel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.CoreLib.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.DataContractSerialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Uri.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Xml.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.DispatchProxy.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.ILGeneration.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.Lightweight.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Metadata.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.TypeExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.Reader.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.ResourceManager.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.Writer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.CompilerServices.Unsafe.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.CompilerServices.VisualC.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Handles.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.JavaScript.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.RuntimeInformation.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Intrinsics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Loader.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Numerics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Formatters.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Claims.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Algorithms.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Cng.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Csp.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Encoding.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.OpenSsl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Pkcs.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.X509Certificates.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Principal.Windows.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Principal.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.SecureString.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ServiceModel.Web.dll`
- `M -> src/C#/Kjitweb/publish-service/System.ServiceProcess.ServiceController.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ServiceProcess.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.CodePages.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encodings.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.RegularExpressions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Channels.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Overlapped.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.RateLimiting.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Dataflow.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Parallel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Thread.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.ThreadPool.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Timer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Transactions.Local.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Transactions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ValueTuple.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Web.HttpUtility.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Windows.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.ReaderWriter.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.Serialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XPath.XDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XPath.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XmlDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XmlSerializer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.dll`
- `A -> src/C#/Kjitweb/publish-service/WindowsBase.dll`
- `D -> src/C#/Kjitweb/publish-service/appsettings.Development.json`
- `A -> src/C#/Kjitweb/publish-service/aspnetcorev2_inprocess.dll`
- `A -> src/C#/Kjitweb/publish-service/clretwrc.dll`
- `A -> src/C#/Kjitweb/publish-service/clrgc.dll`
- `A -> src/C#/Kjitweb/publish-service/clrjit.dll`
- `A -> src/C#/Kjitweb/publish-service/coreclr.dll`
- `A -> src/C#/Kjitweb/publish-service/createdump.exe`
- `M -> src/C#/Kjitweb/publish-service/de/KjitWeb.resources.dll`
- `M -> src/C#/Kjitweb/publish-service/en/KjitWeb.resources.dll`
- `A -> src/C#/Kjitweb/publish-service/hostfxr.dll`
- `A -> src/C#/Kjitweb/publish-service/hostpolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordaccore.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordaccore_amd64_amd64_8.0.2726.22922.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordbi.dll`
- `A -> src/C#/Kjitweb/publish-service/mscorlib.dll`
- `A -> src/C#/Kjitweb/publish-service/mscorrc.dll`
- `A -> src/C#/Kjitweb/publish-service/msquic.dll`
- `A -> src/C#/Kjitweb/publish-service/netstandard.dll`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.deps.json`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.runtimeconfig.json`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.staticwebassets.endpoints.json`
- `D -> src/C#/Kjitweb/publish-service/publish/appsettings.Development.json`
- `D -> src/C#/Kjitweb/publish-service/publish/appsettings.json`
- `D -> src/C#/Kjitweb/publish-service/publish/web.config`
- `D -> src/C#/Kjitweb/publish-service/runtimes/linux/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/osx/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.ServiceProcess.ServiceController.dll`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/Tier1LocalAdminGroup.ps1`
- `M -> src/Powershell/Scripts/install-JIT.ps1`
- `M -> src/Powershell/TestEnvironment/New-T1JitTestEnvironment.ps1`
- `M -> src/Powershell/TestEnvironment/Test-Environment.md`

## 2026-09-07 22:53:51 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:351d80bb2fdecbaa375116bc84d5614ef8ef9305 -->
- `351d80b` Add repeatable JIT installation testing

Changed files:

- `M -> .githooks/pre-push.ps1`
- `M -> .github/workflows/version-policy.yml`
- `M -> VERSION`
- `M -> build/Update-Version.ps1`
- `M -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `M -> release/install-JIT.ps1`
- `M -> release/kjibweb/install-kjitweb.ps1`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/install-JIT.ps1`
- `A -> src/Powershell/TestEnvironment/Install-T1JitTestInstallation.ps1`
- `A -> src/Powershell/TestEnvironment/Remove-T1JitInstallation.ps1`
- `M -> src/Powershell/TestEnvironment/Test-Environment.md`

## 2026-09-07 21:49:14 +02:00 - `dev` to `origin/dev`

Commits:

<!-- commit:d5fcd9267054d85196da0d3a55931a0abfe7e719 -->
- `d5fcd92` Fix PowerShell module runtime compatibility

Changed files:

- `M -> VERSION`
- `M -> file-versions.json`
- `M -> release/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> release/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> release/modules/0.1/just-in-time-configuration.psm1`
- `M -> release/modules/0.1/just-in-time-request.psm1`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/Powershell/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> src/Powershell/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-configuration.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-request.psm1`
- `M -> src/Powershell/modules/Just-In-time.psd1`

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

## 2026-09-27 11:35:11 +02:00 - `release/kjitweb-allowedclient-20260927` to `origin/release/kjitweb-allowedclient-20260927`

Commits:

<!-- commit:5efb76ba2e7e6d24f9a6efe931cd15ecb094740e -->
- `5efb76b` Extend KjitWeb client access management
<!-- commit:0ffe3a33b90b4373d22afb8e06320b442ea3a715 -->
- `0ffe3a3` Document GitHub push history
<!-- commit:40eeef9f80949241a26be3c0ceb8e5c89fab760f -->
- `40eeef9` Merge dev KjitWeb access updates
<!-- commit:8e6866b23890117b1bf622d360b5581cf4aabaf4 -->
- `8e6866b` Prepare KjitWeb access release notes

Changed files:

- `M -> CHANGELOG.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> build/New-InstallationPackage.ps1`
- `M -> build/release_build.ps1`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `A -> release/kJITWeb/get-kjitweb-allowedclient.ps1`
- `M -> release/kJITWeb/install-kjitweb.ps1`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/kJITWeb/set-kjitweb-allowedclient.ps1`
- `M -> release/kJITWeb/update-kjitweb.ps1`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/Just-In-time.psd1`
- `A -> src/C#/Kjitweb/get-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `M -> src/C#/Kjitweb/set-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/update-kjitweb.ps1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `M -> tests/PowerShell/Modules.Tests.ps1`

## 2026-09-26 22:54:45 +02:00 - `docs/latest-download` to `origin/docs/latest-download`

Commits:

<!-- commit:9abe5dc345a8616951a9b4ded385b6308d7d5f57 -->
- `9abe5dc` Add stable installation package download

Changed files:

- `M -> CHANGELOG.md`
- `M -> Developer.md`
- `M -> README.md`
- `M -> VERSION`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/Powershell/modules/Just-In-time.psd1`

## 2026-09-26 22:39:27 +02:00 - `release/0.2.20260926.16` to `origin/release/0.2.20260926.16`

Commits:

<!-- commit:93d73625d363ff3aff475ca0dcded2a82af63932 -->
- `93d7362` Validate the pull request head version

Changed files:

- `M -> .github/workflows/version-policy.yml`
- `M -> CHANGELOG.md`
- `M -> VERSION`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/Powershell/modules/Just-In-time.psd1`

## 2026-09-26 22:34:48 +02:00 - `release/0.2.20260926.16` to `origin/release/0.2.20260926.16`

Commits:

<!-- commit:5ad47741d59865b0907d4e8d948aa3a7de2520ba -->
- `5ad4774` Align CI validation with version manifests

Changed files:

- `M -> .github/workflows/version-policy.yml`
- `M -> CHANGELOG.md`
- `M -> VERSION`
- `M -> build/Update-Version.ps1`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/Powershell/modules/Just-In-time.psd1`

## 2026-09-26 22:23:52 +02:00 - `release/0.2.20260926.16` to `origin/release/0.2.20260926.16`

Commits:

<!-- commit:a54f9adb6f79c492c8e80f9471943002fdc9eebd -->
- `a54f9ad` Fix production content workflow

Changed files:

- `M -> .github/workflows/version-policy.yml`
- `M -> CHANGELOG.md`
- `M -> VERSION`
- `M -> file-versions.json`
- `M -> release/VERSION`
- `M -> release/file-versions.json`
- `M -> release/kJITWeb/publish-service/KjitWeb.dll`
- `M -> release/kJITWeb/publish-service/KjitWeb.exe`
- `M -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `M -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `M -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `M -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/Just-In-time.psd1`
- `M -> src/Powershell/modules/Just-In-time.psd1`

## 2026-09-26 22:18:08 +02:00 - `main` to `origin/main`

Commits:

<!-- commit:5300906e99aeded5cf1c1574c90f2b94a8db862a -->
- `5300906` version 0.1.20260507
<!-- commit:9cd885f917b716436ac205a9ae1a8fa3407f1a95 -->
- `9cd885f` Add version policy and AD test environment
<!-- commit:7270377cd4f80b810cac79976c34f4fe56e2d152 -->
- `7270377` Version 0.1.20260824
<!-- commit:a11dbdc039fffc56405adcb574fe4e54958f9f30 -->
- `a11dbdc` Version 0.1.20260907: improve KjitWeb operations
<!-- commit:6fd798b0ef469dea38a1afd1119aab6f13eaae7c -->
- `6fd798b` Add push history and installation packaging
<!-- commit:69d64a83e7028fb9a0b05992aaaf98253320e822 -->
- `69d64a8` Document GitHub push history
<!-- commit:04d0b12477ed30b90e4989b93db5820badc97a4c -->
- `04d0b12` Improve installation and architecture documentation
<!-- commit:215d67b469108aa356f96c61ebd5d4b9a6203749 -->
- `215d67b` Document GitHub push history
<!-- commit:a95089e418ad9bee11e87cceb94179ae21a706eb -->
- `a95089e` Document T1JIT workflows
<!-- commit:4a5d93be94f8c632a88f9c05fa394b98376f4463 -->
- `4a5d93b` Document GitHub push history
<!-- commit:0d165416d85588781d1b582fb60302cddaaf85de -->
- `0d16541` Document secure T1JIT access workflows
<!-- commit:e16e1b342607bd6dd36d979625b204915a25cd1a -->
- `e16e1b3` Prepare test release 0.1.20260907.34
<!-- commit:7baa5e22f30d2723cfed88c389bebc87cabe064b -->
- `7baa5e2` Show KjitWeb version in footer
<!-- commit:3822ba9733201d8ead5c1696cec78f984ebb72fa -->
- `3822ba9` Improve PowerShell module documentation and configuration
<!-- commit:d5fcd9267054d85196da0d3a55931a0abfe7e719 -->
- `d5fcd92` Fix PowerShell module runtime compatibility
<!-- commit:c36efe53ad2ac918058d66160effeb67569df37b -->
- `c36efe5` Document GitHub push history
<!-- commit:351d80bb2fdecbaa375116bc84d5614ef8ef9305 -->
- `351d80b` Add repeatable JIT installation testing
<!-- commit:b31864acba61652f1fbb05a715ffde425ba05386 -->
- `b31864a` Document GitHub push history
<!-- commit:12a5b6ebda697b0d4f783d59107fc61457b0d59e -->
- `12a5b6e` Harden JIT installation and diagnostics
<!-- commit:b6e3f563ef329e9f442a5a69b79a5ddb36697c66 -->
- `b6e3f56` Document GitHub push history
<!-- commit:4c3754475610a98d10a1db135dc6c2264942bb06 -->
- `4c37544` Improve multi-domain search diagnostics
<!-- commit:51d348f1d940f25c6e7c85a2545aa79ddd327a36 -->
- `51d348f` Document GitHub push history
<!-- commit:2fa36140999b44cda8d554433a2658a1acd6e2e2 -->
- `2fa3614` Document Config-JIT workflow
<!-- commit:b71873be0a17403fde2ef3539a69192510713ecd -->
- `b71873b` Document GitHub push history
<!-- commit:1f9fadf40e9bb4d24417a9fa62372ddadff55f06 -->
- `1f9fadf` Harden JIT provisioning and request handling
<!-- commit:ffde186ec4fb1f98a73ace7a695102de577edd10 -->
- `ffde186` Document GitHub push history
<!-- commit:0b30e312af34d4539b15cadb4255a0077064e6af -->
- `0b30e31` Secure KjitWeb access and logging
<!-- commit:fee35327107eae3705954805a77579d4b5e33a3c -->
- `fee3532` Document GitHub push history
<!-- commit:eb4021a8bcf981deb392787c799e7f831c0bac81 -->
- `eb4021a` Prevent transient delegation config reads
<!-- commit:befb60253b846bfc8eec7cd60b0119aca0adb0d4 -->
- `befb602` Document GitHub push history
<!-- commit:b0d0066a780a8298251d17ca4613821ab720727a -->
- `b0d0066` Fix KjitWeb delegation and automate release builds
<!-- commit:9196ebc83b70080337531ea127426c4e6bed5d09 -->
- `9196ebc` Fix relative KjitWeb search bases
<!-- commit:a6350976e9b5cb8601405ef705a9f57c7d15b3da -->
- `a635097` Document GitHub push history
<!-- commit:653456bb3120674056ccefcb65ffb3d5bb31c0de -->
- `653456b` Rename release output to kJITWeb, automate ZIP packaging, document KjitWeb updates
<!-- commit:0b4d13a65f53814704d065a7a4054fba1f21a848 -->
- `0b4d13a` Package installation output as a single ZIP named by version and branch
<!-- commit:e20024d7094eabfae077ba64feefb5b2764beb51 -->
- `e20024d` Add a user-facing CHANGELOG.md and wire it into the release process
<!-- commit:2ece1b5373a6069580e263938a2fe2ee14dc3346 -->
- `2ece1b5` Detect existing installations in install-JIT.ps1 and update in place
<!-- commit:923155d1754e2847103f74b5f530e4f9ff5d57ed -->
- `923155d` Add KjitWeb Kerberos SPN automation, GMSA permission handling, and persist management scripts
<!-- commit:622577716c37bf1c5aea546f79b0d5567fb901ab -->
- `6225777` Document GitHub push history
<!-- commit:18c6a91ea15604172e01c61618abda836ad42910 -->
- `18c6a91` Bump version scheme to 0.2 and condense CHANGELOG unreleased section
<!-- commit:edb8886eb88f79c8958efb1469479e8bed8741c4 -->
- `edb8886` Document GitHub push history
<!-- commit:a14e8b5beb3578d66b87156fe91a90e22290832e -->
- `a14e8b5` Fix JIT configuration compatibility and gate packages
<!-- commit:382e294d7456028cdda6b5e04150174a3c887049 -->
- `382e294` Document GitHub push history
<!-- commit:c682ef837cca26255bed52155c080b969d264531 -->
- `c682ef8` Allow module version updates in history commits
<!-- commit:9b5b059085811564b226c4ce2443b5bff9f3eccb -->
- `9b5b059` Document GitHub push history
<!-- commit:1f49deb40658670cc0d8c2bd300a409e954313bc -->
- `1f49deb` Complete module API documentation
<!-- commit:25532c61aa1230d51caf22c273f7cb6f85e438dd -->
- `25532c6` Document GitHub push history
<!-- commit:5624d9dfe5ce4b467c6e8a0ceb4ce5af7d083701 -->
- `5624d9d` Document C# APIs and harden KjitWeb firewall setup
<!-- commit:c0dfa31d46a80319aae9e178185af14b8952f184 -->
- `c0dfa31` Restructure documentation and harden release build
<!-- commit:37ffc9e9933201aa3d9bedc1828670e54fe8e4f9 -->
- `37ffc9e` Document GitHub push history
<!-- commit:f1625f5d1aa22f6c5965da81512d85b25e6b64bb -->
- `f1625f5` Merge dev into main for production release
<!-- commit:07ec9d287e42c2d2b3e92cc5ccc35704872f9499 -->
- `07ec9d2` Prepare 0.2.20260926.12 production release
<!-- commit:24cf7da89e5312fe4403c7f888c9dfaf9795c644 -->
- `24cf7da` Document GitHub push history
<!-- commit:c3d5104518491d8259423b8e9984d1bf74aa5d56 -->
- `c3d5104` Exclude development test scripts from production
<!-- commit:a60a168f5cc87c9ac4959c40ac02f713dfda336b -->
- `a60a168` Document GitHub push history
<!-- commit:2e0b73db2a0eee171042e2ae62dafe47bff6875f -->
- `2e0b73d` Handle empty production test-script checks

Changed files:

- `A -> .githooks/pre-commit`
- `A -> .githooks/pre-commit.ps1`
- `A -> .githooks/pre-push`
- `A -> .githooks/pre-push.ps1`
- `A -> .github/workflows/version-policy.yml`
- `M -> .gitignore`
- `A -> .markdownlint.json`
- `A -> CHANGELOG.md`
- `A -> Developer.md`
- `A -> EVENTS.md`
- `M -> README.md`
- `A -> VERSION`
- `A -> build/New-InstallationPackage.ps1`
- `A -> build/Push-GitHub.ps1`
- `A -> build/Test-PowerShellModules.ps1`
- `A -> build/Update-Version.ps1`
- `M -> build/release_build.ps1`
- `M -> docs/Authentication.md`
- `M -> docs/Events.md`
- `M -> docs/Installation.md`
- `M -> docs/Kerberos-Setup.md`
- `M -> docs/config.jit.example`
- `A -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `M -> release/ElevateUser.ps1`
- `M -> release/RequestAdminAccessUI.ps1`
- `A -> release/Show-KjitConfiguration.ps1`
- `M -> release/Tier1LocalAdminGroup.ps1`
- `A -> release/VERSION`
- `A -> release/file-versions.json`
- `M -> release/install-JIT.ps1`
- `A -> release/kJITWeb/appsettings.Production.json`
- `A -> release/kJITWeb/appsettings.json`
- `R063 -> release/kjibweb/install-kjitweb.ps1 -> release/kJITWeb/install-kjitweb.ps1`
- `R100 -> release/kjibweb/kjitlogo.png -> release/kJITWeb/kjitlogo.png`
- `A -> release/kJITWeb/publish-service/KjitWeb.deps.json`
- `A -> release/kJITWeb/publish-service/KjitWeb.dll`
- `R097 -> release/kjibweb/publish-service/KjitWeb.exe -> release/kJITWeb/publish-service/KjitWeb.exe`
- `A -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `R084 -> release/kjibweb/publish-service/KjitWeb.runtimeconfig.json -> release/kJITWeb/publish-service/KjitWeb.runtimeconfig.json`
- `A -> release/kJITWeb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `A -> release/kJITWeb/publish-service/KjitWeb.xml`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Antiforgery.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.BearerToken.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Cookies.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.OAuth.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authorization.Policy.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authorization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Authorization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Endpoints.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Forms.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Server.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Web.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Connections.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.CookiePolicy.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cors.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cryptography.Internal.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cryptography.KeyDerivation.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.Extensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.HealthChecks.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HostFiltering.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.Server.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Html.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Connections.Common.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Connections.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Extensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Features.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Results.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpLogging.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpOverrides.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpsPolicy.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Identity.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Localization.Routing.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Localization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Metadata.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.ApiExplorer.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Cors.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.DataAnnotations.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Json.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Xml.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Localization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Razor.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.RazorPages.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.TagHelpers.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.ViewFeatures.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.OutputCaching.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.RateLimiting.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Razor.Runtime.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Razor.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.RequestDecompression.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCaching.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCaching.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCompression.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Rewrite.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Routing.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Routing.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.HttpSys.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.IIS.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.IISIntegration.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.NamedPipes.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Quic.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Session.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Common.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Protocols.Json.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.StaticFiles.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.WebSockets.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.WebUtilities.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.CSharp.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.DiaSymReader.Native.amd64.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Caching.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Caching.Memory.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Binder.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.CommandLine.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.EnvironmentVariables.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.FileExtensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Ini.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Json.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.KeyPerFile.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.UserSecrets.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Xml.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.DependencyInjection.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.DependencyInjection.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Features.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Composite.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Embedded.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Physical.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileSystemGlobbing.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.Abstractions.dll`
- `R070 -> release/kjibweb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Http.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Identity.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Identity.Stores.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Localization.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Localization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Configuration.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Console.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Debug.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.EventLog.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.EventSource.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.TraceSource.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.ObjectPool.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.ConfigurationExtensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.DataAnnotations.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Primitives.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.WebEncoders.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.JSInterop.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Net.Http.Headers.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.VisualBasic.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.VisualBasic.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Win32.Primitives.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Win32.Registry.dll`
- `A -> release/kJITWeb/publish-service/System.AppContext.dll`
- `A -> release/kJITWeb/publish-service/System.Buffers.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.Concurrent.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.Immutable.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.NonGeneric.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.Specialized.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.Annotations.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.DataAnnotations.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.EventBasedAsync.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.TypeConverter.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.dll`
- `A -> release/kJITWeb/publish-service/System.Configuration.dll`
- `A -> release/kJITWeb/publish-service/System.Console.dll`
- `A -> release/kJITWeb/publish-service/System.Core.dll`
- `A -> release/kJITWeb/publish-service/System.Data.Common.dll`
- `A -> release/kJITWeb/publish-service/System.Data.DataSetExtensions.dll`
- `A -> release/kJITWeb/publish-service/System.Data.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Contracts.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Debug.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.DiagnosticSource.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.EventLog.Messages.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.EventLog.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.FileVersionInfo.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Process.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.StackTrace.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.TextWriterTraceListener.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Tools.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.TraceSource.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Tracing.dll`
- `A -> release/kJITWeb/publish-service/System.DirectoryServices.Protocols.dll`
- `A -> release/kJITWeb/publish-service/System.Drawing.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Drawing.dll`
- `A -> release/kJITWeb/publish-service/System.Dynamic.Runtime.dll`
- `A -> release/kJITWeb/publish-service/System.Formats.Asn1.dll`
- `A -> release/kJITWeb/publish-service/System.Formats.Tar.dll`
- `A -> release/kJITWeb/publish-service/System.Globalization.Calendars.dll`
- `A -> release/kJITWeb/publish-service/System.Globalization.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Globalization.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.Brotli.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.FileSystem.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.Native.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.ZipFile.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.AccessControl.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.DriveInfo.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.Watcher.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.dll`
- `A -> release/kJITWeb/publish-service/System.IO.IsolatedStorage.dll`
- `A -> release/kJITWeb/publish-service/System.IO.MemoryMappedFiles.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Pipelines.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Pipes.AccessControl.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Pipes.dll`
- `A -> release/kJITWeb/publish-service/System.IO.UnmanagedMemoryStream.dll`
- `A -> release/kJITWeb/publish-service/System.IO.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.Expressions.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.Parallel.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.Queryable.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.dll`
- `A -> release/kJITWeb/publish-service/System.Memory.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Http.Json.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Http.dll`
- `A -> release/kJITWeb/publish-service/System.Net.HttpListener.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Mail.dll`
- `A -> release/kJITWeb/publish-service/System.Net.NameResolution.dll`
- `A -> release/kJITWeb/publish-service/System.Net.NetworkInformation.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Ping.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Quic.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Requests.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Security.dll`
- `A -> release/kJITWeb/publish-service/System.Net.ServicePoint.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Sockets.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebClient.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebHeaderCollection.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebProxy.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebSockets.Client.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebSockets.dll`
- `A -> release/kJITWeb/publish-service/System.Net.dll`
- `A -> release/kJITWeb/publish-service/System.Numerics.Vectors.dll`
- `A -> release/kJITWeb/publish-service/System.Numerics.dll`
- `A -> release/kJITWeb/publish-service/System.ObjectModel.dll`
- `A -> release/kJITWeb/publish-service/System.Private.CoreLib.dll`
- `A -> release/kJITWeb/publish-service/System.Private.DataContractSerialization.dll`
- `A -> release/kJITWeb/publish-service/System.Private.Uri.dll`
- `A -> release/kJITWeb/publish-service/System.Private.Xml.Linq.dll`
- `A -> release/kJITWeb/publish-service/System.Private.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.DispatchProxy.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Emit.ILGeneration.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Emit.Lightweight.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Emit.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Metadata.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.TypeExtensions.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.dll`
- `A -> release/kJITWeb/publish-service/System.Resources.Reader.dll`
- `A -> release/kJITWeb/publish-service/System.Resources.ResourceManager.dll`
- `A -> release/kJITWeb/publish-service/System.Resources.Writer.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.CompilerServices.Unsafe.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.CompilerServices.VisualC.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Handles.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.InteropServices.JavaScript.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.InteropServices.RuntimeInformation.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.InteropServices.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Intrinsics.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Loader.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Numerics.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Formatters.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Json.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.dll`
- `A -> release/kJITWeb/publish-service/System.Security.AccessControl.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Claims.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Algorithms.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Cng.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Csp.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Encoding.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.OpenSsl.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Pkcs.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.X509Certificates.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Principal.Windows.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Principal.dll`
- `A -> release/kJITWeb/publish-service/System.Security.SecureString.dll`
- `A -> release/kJITWeb/publish-service/System.Security.dll`
- `A -> release/kJITWeb/publish-service/System.ServiceModel.Web.dll`
- `R088 -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.ServiceProcess.ServiceController.dll -> release/kJITWeb/publish-service/System.ServiceProcess.ServiceController.dll`
- `A -> release/kJITWeb/publish-service/System.ServiceProcess.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encoding.CodePages.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encoding.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encoding.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encodings.Web.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Json.dll`
- `A -> release/kJITWeb/publish-service/System.Text.RegularExpressions.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Channels.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Overlapped.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.RateLimiting.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.Dataflow.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.Parallel.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Thread.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.ThreadPool.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Timer.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.dll`
- `A -> release/kJITWeb/publish-service/System.Transactions.Local.dll`
- `A -> release/kJITWeb/publish-service/System.Transactions.dll`
- `A -> release/kJITWeb/publish-service/System.ValueTuple.dll`
- `A -> release/kJITWeb/publish-service/System.Web.HttpUtility.dll`
- `A -> release/kJITWeb/publish-service/System.Web.dll`
- `A -> release/kJITWeb/publish-service/System.Windows.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.Linq.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.ReaderWriter.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.Serialization.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XDocument.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XPath.XDocument.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XPath.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XmlDocument.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XmlSerializer.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.dll`
- `A -> release/kJITWeb/publish-service/WindowsBase.dll`
- `R100 -> release/kjibweb/publish-service/app_data/JIT.test.config -> release/kJITWeb/publish-service/app_data/JIT.test.config`
- `R082 -> release/kjibweb/publish-service/appsettings.Production.json -> release/kJITWeb/publish-service/appsettings.Production.json`
- `A -> release/kJITWeb/publish-service/appsettings.json`
- `A -> release/kJITWeb/publish-service/aspnetcorev2_inprocess.dll`
- `A -> release/kJITWeb/publish-service/clretwrc.dll`
- `A -> release/kJITWeb/publish-service/clrgc.dll`
- `A -> release/kJITWeb/publish-service/clrjit.dll`
- `A -> release/kJITWeb/publish-service/coreclr.dll`
- `A -> release/kJITWeb/publish-service/createdump.exe`
- `A -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `A -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `A -> release/kJITWeb/publish-service/hostfxr.dll`
- `A -> release/kJITWeb/publish-service/hostpolicy.dll`
- `A -> release/kJITWeb/publish-service/mscordaccore.dll`
- `A -> release/kJITWeb/publish-service/mscordaccore_amd64_amd64_8.0.2726.22922.dll`
- `A -> release/kJITWeb/publish-service/mscordbi.dll`
- `A -> release/kJITWeb/publish-service/mscorlib.dll`
- `A -> release/kJITWeb/publish-service/mscorrc.dll`
- `A -> release/kJITWeb/publish-service/msquic.dll`
- `A -> release/kJITWeb/publish-service/netstandard.dll`
- `R100 -> release/kjibweb/publish-service/web.config -> release/kJITWeb/publish-service/web.config`
- `R100 -> release/kjibweb/publish-service/wwwroot/images/kjitlogo.png -> release/kJITWeb/publish-service/wwwroot/images/kjitlogo.png`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/bootstrap/css/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/bootstrap/css/bootstrap.min.css`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation-unobtrusive/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation/jquery.validate.min.js`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery/jquery.min.js`
- `A -> release/kJITWeb/set-kjitweb-allowedclient.ps1`
- `A -> release/kJITWeb/update-kjitweb.ps1`
- `D -> release/kjibweb/appsettings.Production.json`
- `D -> release/kjibweb/appsettings.json`
- `D -> release/kjibweb/publish-service/KjitWeb.deps.json`
- `D -> release/kjibweb/publish-service/KjitWeb.dll`
- `D -> release/kjibweb/publish-service/KjitWeb.pdb`
- `D -> release/kjibweb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `D -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.Negotiate.dll`
- `D -> release/kjibweb/publish-service/Novell.Directory.Ldap.NETStandard.dll`
- `D -> release/kjibweb/publish-service/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/System.ServiceProcess.ServiceController.dll`
- `D -> release/kjibweb/publish-service/appsettings.Development.json`
- `D -> release/kjibweb/publish-service/appsettings.json`
- `D -> release/kjibweb/publish-service/de/KjitWeb.resources.dll`
- `D -> release/kjibweb/publish-service/en/KjitWeb.resources.dll`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.deps.json`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.runtimeconfig.json`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.staticwebassets.endpoints.json`
- `D -> release/kjibweb/publish-service/publish/appsettings.Development.json`
- `D -> release/kjibweb/publish-service/publish/appsettings.json`
- `D -> release/kjibweb/publish-service/publish/web.config`
- `D -> release/kjibweb/publish-service/runtimes/linux/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/osx/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.ServiceProcess.ServiceController.dll`
- `A -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> release/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> release/modules/0.1/just-in-time-configuration.psm1`
- `M -> release/modules/0.1/just-in-time-request.psm1`
- `M -> release/modules/Just-In-time.psd1`
- `A -> src/C#/KjitCore.DebugHost/KjitCore.DebugHost.csproj`
- `A -> src/C#/KjitCore.DebugHost/Program.cs`
- `A -> src/C#/KjitCore/Abstractions/IDistinguishedNameService.cs`
- `A -> src/C#/KjitCore/Abstractions/IIdentityNormalizer.cs`
- `A -> src/C#/KjitCore/KjitCore.cs`
- `A -> src/C#/KjitCore/KjitCore.csproj`
- `A -> src/C#/KjitCore/Models/JitConfigurationObject.cs`
- `A -> src/C#/KjitCore/README.md`
- `A -> src/C#/KjitCore/Services/DistinguishedNameService.cs`
- `A -> src/C#/KjitCore/Services/IdentityNormalizer.cs`
- `A -> src/C#/KjitCore/Services/JitConfigurationReader.cs`
- `M -> src/C#/Kjitweb/Controllers/HomeController.cs`
- `M -> src/C#/Kjitweb/GlobalUsings.cs`
- `M -> src/C#/Kjitweb/KjitWeb.csproj`
- `A -> src/C#/Kjitweb/Models/ElevatedComputerViewModel.cs`
- `M -> src/C#/Kjitweb/Models/ServerSelectionViewModel.cs`
- `M -> src/C#/Kjitweb/Models/SwitchUserViewModel.cs`
- `M -> src/C#/Kjitweb/Program.cs`
- `M -> src/C#/Kjitweb/Resources/SharedResource.de.resx`
- `M -> src/C#/Kjitweb/Resources/SharedResource.en.resx`
- `M -> src/C#/Kjitweb/Services/ActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/BasicAuthenticationHandler.cs`
- `M -> src/C#/Kjitweb/Services/ConnectionAuditLogger.cs`
- `M -> src/C#/Kjitweb/Services/DebugFileLoggerProvider.cs`
- `M -> src/C#/Kjitweb/Services/DebugLogFileWriter.cs`
- `A -> src/C#/Kjitweb/Services/EventLogHealthMonitor.cs`
- `A -> src/C#/Kjitweb/Services/EventLogHealthSnapshot.cs`
- `M -> src/C#/Kjitweb/Services/EventLogWriter.cs`
- `M -> src/C#/Kjitweb/Services/IActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/IConnectionAuditLogger.cs`
- `A -> src/C#/Kjitweb/Services/IEventLogHealthMonitor.cs`
- `M -> src/C#/Kjitweb/Services/IEventLogWriter.cs`
- `M -> src/C#/Kjitweb/Services/JitConfigPathResolver.cs`
- `A -> src/C#/Kjitweb/Services/MutualTlsCertificateValidator.cs`
- `A -> src/C#/Kjitweb/Services/MutualTlsOptions.cs`
- `M -> src/C#/Kjitweb/Services/WindowsCredentialValidator.cs`
- `M -> src/C#/Kjitweb/Services/configuration.cs`
- `M -> src/C#/Kjitweb/SharedResource.cs`
- `M -> src/C#/Kjitweb/Views/Home/Index.cshtml`
- `M -> src/C#/Kjitweb/Views/Shared/_Layout.cshtml`
- `M -> src/C#/Kjitweb/appsettings.Development.json`
- `M -> src/C#/Kjitweb/appsettings.Production.json`
- `M -> src/C#/Kjitweb/appsettings.json`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.deps.json`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.dll`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.exe`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.pdb`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.runtimeconfig.json`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Antiforgery.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.BearerToken.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Cookies.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Core.dll`
- `M -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Negotiate.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.OAuth.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authorization.Policy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authorization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Authorization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Endpoints.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Forms.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Server.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Connections.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.CookiePolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cors.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cryptography.Internal.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cryptography.KeyDerivation.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.HealthChecks.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HostFiltering.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.Server.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Html.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Connections.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Connections.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Features.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Results.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpLogging.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpOverrides.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpsPolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Identity.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Localization.Routing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Metadata.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.ApiExplorer.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Cors.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Razor.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.RazorPages.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.TagHelpers.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.ViewFeatures.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.OutputCaching.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.RateLimiting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Razor.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Razor.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.RequestDecompression.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCaching.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCaching.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCompression.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Rewrite.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Routing.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Routing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.HttpSys.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.IIS.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.IISIntegration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.NamedPipes.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Quic.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Session.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Protocols.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.StaticFiles.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.WebSockets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.WebUtilities.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.CSharp.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.DiaSymReader.Native.amd64.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Caching.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Caching.Memory.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Binder.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.CommandLine.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.EnvironmentVariables.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.FileExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Ini.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.KeyPerFile.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.UserSecrets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.DependencyInjection.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.DependencyInjection.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Features.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Composite.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Embedded.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Physical.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileSystemGlobbing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.Abstractions.dll`
- `M -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Identity.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Identity.Stores.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Localization.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Console.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Debug.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.EventLog.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.EventSource.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.TraceSource.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.ObjectPool.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.ConfigurationExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.WebEncoders.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.JSInterop.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Net.Http.Headers.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.VisualBasic.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.VisualBasic.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Win32.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Win32.Registry.dll`
- `D -> src/C#/Kjitweb/publish-service/Novell.Directory.Ldap.NETStandard.dll`
- `A -> src/C#/Kjitweb/publish-service/System.AppContext.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Buffers.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Concurrent.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Immutable.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.NonGeneric.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Specialized.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.Annotations.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.EventBasedAsync.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.TypeConverter.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Console.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.DataSetExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Contracts.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Debug.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.DiagnosticSource.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.EventLog.Messages.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.EventLog.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.FileVersionInfo.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Process.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.StackTrace.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.TextWriterTraceListener.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Tools.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.TraceSource.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Tracing.dll`
- `M -> src/C#/Kjitweb/publish-service/System.DirectoryServices.Protocols.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Drawing.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Drawing.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Dynamic.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Formats.Asn1.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Formats.Tar.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.Calendars.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.Brotli.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.FileSystem.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.Native.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.ZipFile.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.DriveInfo.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.Watcher.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.IsolatedStorage.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.MemoryMappedFiles.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipelines.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipes.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipes.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.UnmanagedMemoryStream.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Expressions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Parallel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Queryable.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Memory.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Http.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.HttpListener.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Mail.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.NameResolution.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.NetworkInformation.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Ping.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Quic.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Requests.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Security.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.ServicePoint.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Sockets.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebClient.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebHeaderCollection.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebProxy.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebSockets.Client.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebSockets.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Numerics.Vectors.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Numerics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ObjectModel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.CoreLib.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.DataContractSerialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Uri.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Xml.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.DispatchProxy.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.ILGeneration.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.Lightweight.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Metadata.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.TypeExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.Reader.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.ResourceManager.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.Writer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.CompilerServices.Unsafe.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.CompilerServices.VisualC.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Handles.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.JavaScript.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.RuntimeInformation.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Intrinsics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Loader.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Numerics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Formatters.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Claims.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Algorithms.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Cng.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Csp.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Encoding.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.OpenSsl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Pkcs.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.X509Certificates.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Principal.Windows.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Principal.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.SecureString.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ServiceModel.Web.dll`
- `M -> src/C#/Kjitweb/publish-service/System.ServiceProcess.ServiceController.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ServiceProcess.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.CodePages.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encodings.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.RegularExpressions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Channels.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Overlapped.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.RateLimiting.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Dataflow.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Parallel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Thread.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.ThreadPool.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Timer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Transactions.Local.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Transactions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ValueTuple.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Web.HttpUtility.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Windows.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.ReaderWriter.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.Serialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XPath.XDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XPath.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XmlDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XmlSerializer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.dll`
- `A -> src/C#/Kjitweb/publish-service/WindowsBase.dll`
- `D -> src/C#/Kjitweb/publish-service/appsettings.Development.json`
- `M -> src/C#/Kjitweb/publish-service/appsettings.json`
- `A -> src/C#/Kjitweb/publish-service/aspnetcorev2_inprocess.dll`
- `A -> src/C#/Kjitweb/publish-service/clretwrc.dll`
- `A -> src/C#/Kjitweb/publish-service/clrgc.dll`
- `A -> src/C#/Kjitweb/publish-service/clrjit.dll`
- `A -> src/C#/Kjitweb/publish-service/coreclr.dll`
- `A -> src/C#/Kjitweb/publish-service/createdump.exe`
- `M -> src/C#/Kjitweb/publish-service/de/KjitWeb.resources.dll`
- `M -> src/C#/Kjitweb/publish-service/en/KjitWeb.resources.dll`
- `A -> src/C#/Kjitweb/publish-service/hostfxr.dll`
- `A -> src/C#/Kjitweb/publish-service/hostpolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordaccore.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordaccore_amd64_amd64_8.0.2726.22922.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordbi.dll`
- `A -> src/C#/Kjitweb/publish-service/mscorlib.dll`
- `A -> src/C#/Kjitweb/publish-service/mscorrc.dll`
- `A -> src/C#/Kjitweb/publish-service/msquic.dll`
- `A -> src/C#/Kjitweb/publish-service/netstandard.dll`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.deps.json`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.runtimeconfig.json`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.staticwebassets.endpoints.json`
- `D -> src/C#/Kjitweb/publish-service/publish/appsettings.Development.json`
- `D -> src/C#/Kjitweb/publish-service/publish/appsettings.json`
- `D -> src/C#/Kjitweb/publish-service/publish/web.config`
- `D -> src/C#/Kjitweb/publish-service/runtimes/linux/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/osx/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.dll`
- `A -> src/C#/Kjitweb/set-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/uninstall-service.ps1`
- `A -> src/C#/Kjitweb/update-kjitweb.ps1`
- `A -> src/C#/Kjitweb/wwwroot/lib/bootstrap/css/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/bootstrap/css/bootstrap.min.css`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation-unobtrusive/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation/jquery.validate.min.js`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery/jquery.min.js`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/ElevateUser.ps1`
- `M -> src/Powershell/Scripts/README.md`
- `M -> src/Powershell/Scripts/RequestAdminAccessUI.ps1`
- `A -> src/Powershell/Scripts/Show-KjitConfiguration.ps1`
- `M -> src/Powershell/Scripts/Tier1LocalAdminGroup.ps1`
- `M -> src/Powershell/Scripts/install-JIT.ps1`
- `A -> src/Powershell/TestEnvironment/Test-Environment.md`
- `M -> src/Powershell/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> src/Powershell/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-configuration.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-request.psm1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `A -> tests/PowerShell/Modules.Tests.ps1`
- `A -> tmp_ps51_test.ps1`
- `A -> tmp_release_test.ps1`

## 2026-09-26 22:16:07 +02:00 - `main` to `origin/main`

Commits:

<!-- commit:5300906e99aeded5cf1c1574c90f2b94a8db862a -->
- `5300906` version 0.1.20260507
<!-- commit:9cd885f917b716436ac205a9ae1a8fa3407f1a95 -->
- `9cd885f` Add version policy and AD test environment
<!-- commit:7270377cd4f80b810cac79976c34f4fe56e2d152 -->
- `7270377` Version 0.1.20260824
<!-- commit:a11dbdc039fffc56405adcb574fe4e54958f9f30 -->
- `a11dbdc` Version 0.1.20260907: improve KjitWeb operations
<!-- commit:6fd798b0ef469dea38a1afd1119aab6f13eaae7c -->
- `6fd798b` Add push history and installation packaging
<!-- commit:69d64a83e7028fb9a0b05992aaaf98253320e822 -->
- `69d64a8` Document GitHub push history
<!-- commit:04d0b12477ed30b90e4989b93db5820badc97a4c -->
- `04d0b12` Improve installation and architecture documentation
<!-- commit:215d67b469108aa356f96c61ebd5d4b9a6203749 -->
- `215d67b` Document GitHub push history
<!-- commit:a95089e418ad9bee11e87cceb94179ae21a706eb -->
- `a95089e` Document T1JIT workflows
<!-- commit:4a5d93be94f8c632a88f9c05fa394b98376f4463 -->
- `4a5d93b` Document GitHub push history
<!-- commit:0d165416d85588781d1b582fb60302cddaaf85de -->
- `0d16541` Document secure T1JIT access workflows
<!-- commit:e16e1b342607bd6dd36d979625b204915a25cd1a -->
- `e16e1b3` Prepare test release 0.1.20260907.34
<!-- commit:7baa5e22f30d2723cfed88c389bebc87cabe064b -->
- `7baa5e2` Show KjitWeb version in footer
<!-- commit:3822ba9733201d8ead5c1696cec78f984ebb72fa -->
- `3822ba9` Improve PowerShell module documentation and configuration
<!-- commit:d5fcd9267054d85196da0d3a55931a0abfe7e719 -->
- `d5fcd92` Fix PowerShell module runtime compatibility
<!-- commit:c36efe53ad2ac918058d66160effeb67569df37b -->
- `c36efe5` Document GitHub push history
<!-- commit:351d80bb2fdecbaa375116bc84d5614ef8ef9305 -->
- `351d80b` Add repeatable JIT installation testing
<!-- commit:b31864acba61652f1fbb05a715ffde425ba05386 -->
- `b31864a` Document GitHub push history
<!-- commit:12a5b6ebda697b0d4f783d59107fc61457b0d59e -->
- `12a5b6e` Harden JIT installation and diagnostics
<!-- commit:b6e3f563ef329e9f442a5a69b79a5ddb36697c66 -->
- `b6e3f56` Document GitHub push history
<!-- commit:4c3754475610a98d10a1db135dc6c2264942bb06 -->
- `4c37544` Improve multi-domain search diagnostics
<!-- commit:51d348f1d940f25c6e7c85a2545aa79ddd327a36 -->
- `51d348f` Document GitHub push history
<!-- commit:2fa36140999b44cda8d554433a2658a1acd6e2e2 -->
- `2fa3614` Document Config-JIT workflow
<!-- commit:b71873be0a17403fde2ef3539a69192510713ecd -->
- `b71873b` Document GitHub push history
<!-- commit:1f9fadf40e9bb4d24417a9fa62372ddadff55f06 -->
- `1f9fadf` Harden JIT provisioning and request handling
<!-- commit:ffde186ec4fb1f98a73ace7a695102de577edd10 -->
- `ffde186` Document GitHub push history
<!-- commit:0b30e312af34d4539b15cadb4255a0077064e6af -->
- `0b30e31` Secure KjitWeb access and logging
<!-- commit:fee35327107eae3705954805a77579d4b5e33a3c -->
- `fee3532` Document GitHub push history
<!-- commit:eb4021a8bcf981deb392787c799e7f831c0bac81 -->
- `eb4021a` Prevent transient delegation config reads
<!-- commit:befb60253b846bfc8eec7cd60b0119aca0adb0d4 -->
- `befb602` Document GitHub push history
<!-- commit:b0d0066a780a8298251d17ca4613821ab720727a -->
- `b0d0066` Fix KjitWeb delegation and automate release builds
<!-- commit:9196ebc83b70080337531ea127426c4e6bed5d09 -->
- `9196ebc` Fix relative KjitWeb search bases
<!-- commit:a6350976e9b5cb8601405ef705a9f57c7d15b3da -->
- `a635097` Document GitHub push history
<!-- commit:653456bb3120674056ccefcb65ffb3d5bb31c0de -->
- `653456b` Rename release output to kJITWeb, automate ZIP packaging, document KjitWeb updates
<!-- commit:0b4d13a65f53814704d065a7a4054fba1f21a848 -->
- `0b4d13a` Package installation output as a single ZIP named by version and branch
<!-- commit:e20024d7094eabfae077ba64feefb5b2764beb51 -->
- `e20024d` Add a user-facing CHANGELOG.md and wire it into the release process
<!-- commit:2ece1b5373a6069580e263938a2fe2ee14dc3346 -->
- `2ece1b5` Detect existing installations in install-JIT.ps1 and update in place
<!-- commit:923155d1754e2847103f74b5f530e4f9ff5d57ed -->
- `923155d` Add KjitWeb Kerberos SPN automation, GMSA permission handling, and persist management scripts
<!-- commit:622577716c37bf1c5aea546f79b0d5567fb901ab -->
- `6225777` Document GitHub push history
<!-- commit:18c6a91ea15604172e01c61618abda836ad42910 -->
- `18c6a91` Bump version scheme to 0.2 and condense CHANGELOG unreleased section
<!-- commit:edb8886eb88f79c8958efb1469479e8bed8741c4 -->
- `edb8886` Document GitHub push history
<!-- commit:a14e8b5beb3578d66b87156fe91a90e22290832e -->
- `a14e8b5` Fix JIT configuration compatibility and gate packages
<!-- commit:382e294d7456028cdda6b5e04150174a3c887049 -->
- `382e294` Document GitHub push history
<!-- commit:c682ef837cca26255bed52155c080b969d264531 -->
- `c682ef8` Allow module version updates in history commits
<!-- commit:9b5b059085811564b226c4ce2443b5bff9f3eccb -->
- `9b5b059` Document GitHub push history
<!-- commit:1f49deb40658670cc0d8c2bd300a409e954313bc -->
- `1f49deb` Complete module API documentation
<!-- commit:25532c61aa1230d51caf22c273f7cb6f85e438dd -->
- `25532c6` Document GitHub push history
<!-- commit:5624d9dfe5ce4b467c6e8a0ceb4ce5af7d083701 -->
- `5624d9d` Document C# APIs and harden KjitWeb firewall setup
<!-- commit:c0dfa31d46a80319aae9e178185af14b8952f184 -->
- `c0dfa31` Restructure documentation and harden release build
<!-- commit:37ffc9e9933201aa3d9bedc1828670e54fe8e4f9 -->
- `37ffc9e` Document GitHub push history
<!-- commit:f1625f5d1aa22f6c5965da81512d85b25e6b64bb -->
- `f1625f5` Merge dev into main for production release
<!-- commit:07ec9d287e42c2d2b3e92cc5ccc35704872f9499 -->
- `07ec9d2` Prepare 0.2.20260926.12 production release
<!-- commit:24cf7da89e5312fe4403c7f888c9dfaf9795c644 -->
- `24cf7da` Document GitHub push history
<!-- commit:c3d5104518491d8259423b8e9984d1bf74aa5d56 -->
- `c3d5104` Exclude development test scripts from production

Changed files:

- `A -> .githooks/pre-commit`
- `A -> .githooks/pre-commit.ps1`
- `A -> .githooks/pre-push`
- `A -> .githooks/pre-push.ps1`
- `A -> .github/workflows/version-policy.yml`
- `M -> .gitignore`
- `A -> .markdownlint.json`
- `A -> CHANGELOG.md`
- `A -> Developer.md`
- `A -> EVENTS.md`
- `M -> README.md`
- `A -> VERSION`
- `A -> build/New-InstallationPackage.ps1`
- `A -> build/Push-GitHub.ps1`
- `A -> build/Test-PowerShellModules.ps1`
- `A -> build/Update-Version.ps1`
- `M -> build/release_build.ps1`
- `M -> docs/Authentication.md`
- `M -> docs/Events.md`
- `M -> docs/Installation.md`
- `M -> docs/Kerberos-Setup.md`
- `M -> docs/config.jit.example`
- `A -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `M -> release/ElevateUser.ps1`
- `M -> release/RequestAdminAccessUI.ps1`
- `A -> release/Show-KjitConfiguration.ps1`
- `M -> release/Tier1LocalAdminGroup.ps1`
- `A -> release/VERSION`
- `A -> release/file-versions.json`
- `M -> release/install-JIT.ps1`
- `A -> release/kJITWeb/appsettings.Production.json`
- `A -> release/kJITWeb/appsettings.json`
- `R063 -> release/kjibweb/install-kjitweb.ps1 -> release/kJITWeb/install-kjitweb.ps1`
- `R100 -> release/kjibweb/kjitlogo.png -> release/kJITWeb/kjitlogo.png`
- `A -> release/kJITWeb/publish-service/KjitWeb.deps.json`
- `A -> release/kJITWeb/publish-service/KjitWeb.dll`
- `R097 -> release/kjibweb/publish-service/KjitWeb.exe -> release/kJITWeb/publish-service/KjitWeb.exe`
- `A -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `R084 -> release/kjibweb/publish-service/KjitWeb.runtimeconfig.json -> release/kJITWeb/publish-service/KjitWeb.runtimeconfig.json`
- `A -> release/kJITWeb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `A -> release/kJITWeb/publish-service/KjitWeb.xml`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Antiforgery.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.BearerToken.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Cookies.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.OAuth.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authorization.Policy.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authorization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Authorization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Endpoints.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Forms.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Server.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Web.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Connections.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.CookiePolicy.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cors.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cryptography.Internal.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cryptography.KeyDerivation.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.Extensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.HealthChecks.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HostFiltering.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.Server.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Html.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Connections.Common.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Connections.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Extensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Features.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Results.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpLogging.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpOverrides.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpsPolicy.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Identity.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Localization.Routing.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Localization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Metadata.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.ApiExplorer.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Cors.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.DataAnnotations.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Json.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Xml.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Localization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Razor.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.RazorPages.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.TagHelpers.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.ViewFeatures.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.OutputCaching.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.RateLimiting.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Razor.Runtime.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Razor.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.RequestDecompression.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCaching.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCaching.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCompression.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Rewrite.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Routing.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Routing.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.HttpSys.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.IIS.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.IISIntegration.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.NamedPipes.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Quic.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Session.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Common.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Protocols.Json.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.StaticFiles.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.WebSockets.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.WebUtilities.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.CSharp.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.DiaSymReader.Native.amd64.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Caching.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Caching.Memory.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Binder.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.CommandLine.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.EnvironmentVariables.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.FileExtensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Ini.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Json.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.KeyPerFile.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.UserSecrets.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Xml.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.DependencyInjection.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.DependencyInjection.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Features.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Composite.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Embedded.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Physical.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileSystemGlobbing.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.Abstractions.dll`
- `R070 -> release/kjibweb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Http.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Identity.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Identity.Stores.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Localization.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Localization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Configuration.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Console.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Debug.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.EventLog.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.EventSource.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.TraceSource.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.ObjectPool.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.ConfigurationExtensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.DataAnnotations.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Primitives.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.WebEncoders.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.JSInterop.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Net.Http.Headers.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.VisualBasic.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.VisualBasic.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Win32.Primitives.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Win32.Registry.dll`
- `A -> release/kJITWeb/publish-service/System.AppContext.dll`
- `A -> release/kJITWeb/publish-service/System.Buffers.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.Concurrent.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.Immutable.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.NonGeneric.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.Specialized.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.Annotations.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.DataAnnotations.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.EventBasedAsync.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.TypeConverter.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.dll`
- `A -> release/kJITWeb/publish-service/System.Configuration.dll`
- `A -> release/kJITWeb/publish-service/System.Console.dll`
- `A -> release/kJITWeb/publish-service/System.Core.dll`
- `A -> release/kJITWeb/publish-service/System.Data.Common.dll`
- `A -> release/kJITWeb/publish-service/System.Data.DataSetExtensions.dll`
- `A -> release/kJITWeb/publish-service/System.Data.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Contracts.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Debug.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.DiagnosticSource.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.EventLog.Messages.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.EventLog.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.FileVersionInfo.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Process.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.StackTrace.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.TextWriterTraceListener.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Tools.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.TraceSource.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Tracing.dll`
- `A -> release/kJITWeb/publish-service/System.DirectoryServices.Protocols.dll`
- `A -> release/kJITWeb/publish-service/System.Drawing.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Drawing.dll`
- `A -> release/kJITWeb/publish-service/System.Dynamic.Runtime.dll`
- `A -> release/kJITWeb/publish-service/System.Formats.Asn1.dll`
- `A -> release/kJITWeb/publish-service/System.Formats.Tar.dll`
- `A -> release/kJITWeb/publish-service/System.Globalization.Calendars.dll`
- `A -> release/kJITWeb/publish-service/System.Globalization.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Globalization.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.Brotli.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.FileSystem.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.Native.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.ZipFile.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.AccessControl.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.DriveInfo.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.Watcher.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.dll`
- `A -> release/kJITWeb/publish-service/System.IO.IsolatedStorage.dll`
- `A -> release/kJITWeb/publish-service/System.IO.MemoryMappedFiles.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Pipelines.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Pipes.AccessControl.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Pipes.dll`
- `A -> release/kJITWeb/publish-service/System.IO.UnmanagedMemoryStream.dll`
- `A -> release/kJITWeb/publish-service/System.IO.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.Expressions.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.Parallel.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.Queryable.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.dll`
- `A -> release/kJITWeb/publish-service/System.Memory.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Http.Json.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Http.dll`
- `A -> release/kJITWeb/publish-service/System.Net.HttpListener.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Mail.dll`
- `A -> release/kJITWeb/publish-service/System.Net.NameResolution.dll`
- `A -> release/kJITWeb/publish-service/System.Net.NetworkInformation.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Ping.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Quic.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Requests.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Security.dll`
- `A -> release/kJITWeb/publish-service/System.Net.ServicePoint.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Sockets.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebClient.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebHeaderCollection.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebProxy.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebSockets.Client.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebSockets.dll`
- `A -> release/kJITWeb/publish-service/System.Net.dll`
- `A -> release/kJITWeb/publish-service/System.Numerics.Vectors.dll`
- `A -> release/kJITWeb/publish-service/System.Numerics.dll`
- `A -> release/kJITWeb/publish-service/System.ObjectModel.dll`
- `A -> release/kJITWeb/publish-service/System.Private.CoreLib.dll`
- `A -> release/kJITWeb/publish-service/System.Private.DataContractSerialization.dll`
- `A -> release/kJITWeb/publish-service/System.Private.Uri.dll`
- `A -> release/kJITWeb/publish-service/System.Private.Xml.Linq.dll`
- `A -> release/kJITWeb/publish-service/System.Private.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.DispatchProxy.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Emit.ILGeneration.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Emit.Lightweight.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Emit.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Metadata.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.TypeExtensions.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.dll`
- `A -> release/kJITWeb/publish-service/System.Resources.Reader.dll`
- `A -> release/kJITWeb/publish-service/System.Resources.ResourceManager.dll`
- `A -> release/kJITWeb/publish-service/System.Resources.Writer.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.CompilerServices.Unsafe.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.CompilerServices.VisualC.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Handles.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.InteropServices.JavaScript.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.InteropServices.RuntimeInformation.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.InteropServices.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Intrinsics.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Loader.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Numerics.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Formatters.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Json.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.dll`
- `A -> release/kJITWeb/publish-service/System.Security.AccessControl.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Claims.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Algorithms.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Cng.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Csp.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Encoding.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.OpenSsl.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Pkcs.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.X509Certificates.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Principal.Windows.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Principal.dll`
- `A -> release/kJITWeb/publish-service/System.Security.SecureString.dll`
- `A -> release/kJITWeb/publish-service/System.Security.dll`
- `A -> release/kJITWeb/publish-service/System.ServiceModel.Web.dll`
- `R088 -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.ServiceProcess.ServiceController.dll -> release/kJITWeb/publish-service/System.ServiceProcess.ServiceController.dll`
- `A -> release/kJITWeb/publish-service/System.ServiceProcess.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encoding.CodePages.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encoding.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encoding.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encodings.Web.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Json.dll`
- `A -> release/kJITWeb/publish-service/System.Text.RegularExpressions.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Channels.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Overlapped.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.RateLimiting.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.Dataflow.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.Parallel.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Thread.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.ThreadPool.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Timer.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.dll`
- `A -> release/kJITWeb/publish-service/System.Transactions.Local.dll`
- `A -> release/kJITWeb/publish-service/System.Transactions.dll`
- `A -> release/kJITWeb/publish-service/System.ValueTuple.dll`
- `A -> release/kJITWeb/publish-service/System.Web.HttpUtility.dll`
- `A -> release/kJITWeb/publish-service/System.Web.dll`
- `A -> release/kJITWeb/publish-service/System.Windows.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.Linq.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.ReaderWriter.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.Serialization.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XDocument.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XPath.XDocument.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XPath.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XmlDocument.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XmlSerializer.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.dll`
- `A -> release/kJITWeb/publish-service/WindowsBase.dll`
- `R100 -> release/kjibweb/publish-service/app_data/JIT.test.config -> release/kJITWeb/publish-service/app_data/JIT.test.config`
- `R082 -> release/kjibweb/publish-service/appsettings.Production.json -> release/kJITWeb/publish-service/appsettings.Production.json`
- `A -> release/kJITWeb/publish-service/appsettings.json`
- `A -> release/kJITWeb/publish-service/aspnetcorev2_inprocess.dll`
- `A -> release/kJITWeb/publish-service/clretwrc.dll`
- `A -> release/kJITWeb/publish-service/clrgc.dll`
- `A -> release/kJITWeb/publish-service/clrjit.dll`
- `A -> release/kJITWeb/publish-service/coreclr.dll`
- `A -> release/kJITWeb/publish-service/createdump.exe`
- `A -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `A -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `A -> release/kJITWeb/publish-service/hostfxr.dll`
- `A -> release/kJITWeb/publish-service/hostpolicy.dll`
- `A -> release/kJITWeb/publish-service/mscordaccore.dll`
- `A -> release/kJITWeb/publish-service/mscordaccore_amd64_amd64_8.0.2726.22922.dll`
- `A -> release/kJITWeb/publish-service/mscordbi.dll`
- `A -> release/kJITWeb/publish-service/mscorlib.dll`
- `A -> release/kJITWeb/publish-service/mscorrc.dll`
- `A -> release/kJITWeb/publish-service/msquic.dll`
- `A -> release/kJITWeb/publish-service/netstandard.dll`
- `R100 -> release/kjibweb/publish-service/web.config -> release/kJITWeb/publish-service/web.config`
- `R100 -> release/kjibweb/publish-service/wwwroot/images/kjitlogo.png -> release/kJITWeb/publish-service/wwwroot/images/kjitlogo.png`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/bootstrap/css/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/bootstrap/css/bootstrap.min.css`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation-unobtrusive/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation/jquery.validate.min.js`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery/jquery.min.js`
- `A -> release/kJITWeb/set-kjitweb-allowedclient.ps1`
- `A -> release/kJITWeb/update-kjitweb.ps1`
- `D -> release/kjibweb/appsettings.Production.json`
- `D -> release/kjibweb/appsettings.json`
- `D -> release/kjibweb/publish-service/KjitWeb.deps.json`
- `D -> release/kjibweb/publish-service/KjitWeb.dll`
- `D -> release/kjibweb/publish-service/KjitWeb.pdb`
- `D -> release/kjibweb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `D -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.Negotiate.dll`
- `D -> release/kjibweb/publish-service/Novell.Directory.Ldap.NETStandard.dll`
- `D -> release/kjibweb/publish-service/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/System.ServiceProcess.ServiceController.dll`
- `D -> release/kjibweb/publish-service/appsettings.Development.json`
- `D -> release/kjibweb/publish-service/appsettings.json`
- `D -> release/kjibweb/publish-service/de/KjitWeb.resources.dll`
- `D -> release/kjibweb/publish-service/en/KjitWeb.resources.dll`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.deps.json`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.runtimeconfig.json`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.staticwebassets.endpoints.json`
- `D -> release/kjibweb/publish-service/publish/appsettings.Development.json`
- `D -> release/kjibweb/publish-service/publish/appsettings.json`
- `D -> release/kjibweb/publish-service/publish/web.config`
- `D -> release/kjibweb/publish-service/runtimes/linux/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/osx/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.ServiceProcess.ServiceController.dll`
- `A -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> release/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> release/modules/0.1/just-in-time-configuration.psm1`
- `M -> release/modules/0.1/just-in-time-request.psm1`
- `M -> release/modules/Just-In-time.psd1`
- `A -> src/C#/KjitCore.DebugHost/KjitCore.DebugHost.csproj`
- `A -> src/C#/KjitCore.DebugHost/Program.cs`
- `A -> src/C#/KjitCore/Abstractions/IDistinguishedNameService.cs`
- `A -> src/C#/KjitCore/Abstractions/IIdentityNormalizer.cs`
- `A -> src/C#/KjitCore/KjitCore.cs`
- `A -> src/C#/KjitCore/KjitCore.csproj`
- `A -> src/C#/KjitCore/Models/JitConfigurationObject.cs`
- `A -> src/C#/KjitCore/README.md`
- `A -> src/C#/KjitCore/Services/DistinguishedNameService.cs`
- `A -> src/C#/KjitCore/Services/IdentityNormalizer.cs`
- `A -> src/C#/KjitCore/Services/JitConfigurationReader.cs`
- `M -> src/C#/Kjitweb/Controllers/HomeController.cs`
- `M -> src/C#/Kjitweb/GlobalUsings.cs`
- `M -> src/C#/Kjitweb/KjitWeb.csproj`
- `A -> src/C#/Kjitweb/Models/ElevatedComputerViewModel.cs`
- `M -> src/C#/Kjitweb/Models/ServerSelectionViewModel.cs`
- `M -> src/C#/Kjitweb/Models/SwitchUserViewModel.cs`
- `M -> src/C#/Kjitweb/Program.cs`
- `M -> src/C#/Kjitweb/Resources/SharedResource.de.resx`
- `M -> src/C#/Kjitweb/Resources/SharedResource.en.resx`
- `M -> src/C#/Kjitweb/Services/ActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/BasicAuthenticationHandler.cs`
- `M -> src/C#/Kjitweb/Services/ConnectionAuditLogger.cs`
- `M -> src/C#/Kjitweb/Services/DebugFileLoggerProvider.cs`
- `M -> src/C#/Kjitweb/Services/DebugLogFileWriter.cs`
- `A -> src/C#/Kjitweb/Services/EventLogHealthMonitor.cs`
- `A -> src/C#/Kjitweb/Services/EventLogHealthSnapshot.cs`
- `M -> src/C#/Kjitweb/Services/EventLogWriter.cs`
- `M -> src/C#/Kjitweb/Services/IActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/IConnectionAuditLogger.cs`
- `A -> src/C#/Kjitweb/Services/IEventLogHealthMonitor.cs`
- `M -> src/C#/Kjitweb/Services/IEventLogWriter.cs`
- `M -> src/C#/Kjitweb/Services/JitConfigPathResolver.cs`
- `A -> src/C#/Kjitweb/Services/MutualTlsCertificateValidator.cs`
- `A -> src/C#/Kjitweb/Services/MutualTlsOptions.cs`
- `M -> src/C#/Kjitweb/Services/WindowsCredentialValidator.cs`
- `M -> src/C#/Kjitweb/Services/configuration.cs`
- `M -> src/C#/Kjitweb/SharedResource.cs`
- `M -> src/C#/Kjitweb/Views/Home/Index.cshtml`
- `M -> src/C#/Kjitweb/Views/Shared/_Layout.cshtml`
- `M -> src/C#/Kjitweb/appsettings.Development.json`
- `M -> src/C#/Kjitweb/appsettings.Production.json`
- `M -> src/C#/Kjitweb/appsettings.json`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.deps.json`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.dll`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.exe`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.pdb`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.runtimeconfig.json`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Antiforgery.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.BearerToken.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Cookies.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Core.dll`
- `M -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Negotiate.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.OAuth.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authorization.Policy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authorization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Authorization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Endpoints.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Forms.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Server.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Connections.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.CookiePolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cors.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cryptography.Internal.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cryptography.KeyDerivation.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.HealthChecks.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HostFiltering.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.Server.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Html.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Connections.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Connections.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Features.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Results.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpLogging.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpOverrides.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpsPolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Identity.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Localization.Routing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Metadata.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.ApiExplorer.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Cors.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Razor.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.RazorPages.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.TagHelpers.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.ViewFeatures.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.OutputCaching.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.RateLimiting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Razor.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Razor.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.RequestDecompression.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCaching.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCaching.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCompression.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Rewrite.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Routing.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Routing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.HttpSys.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.IIS.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.IISIntegration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.NamedPipes.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Quic.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Session.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Protocols.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.StaticFiles.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.WebSockets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.WebUtilities.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.CSharp.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.DiaSymReader.Native.amd64.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Caching.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Caching.Memory.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Binder.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.CommandLine.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.EnvironmentVariables.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.FileExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Ini.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.KeyPerFile.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.UserSecrets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.DependencyInjection.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.DependencyInjection.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Features.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Composite.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Embedded.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Physical.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileSystemGlobbing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.Abstractions.dll`
- `M -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Identity.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Identity.Stores.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Localization.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Console.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Debug.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.EventLog.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.EventSource.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.TraceSource.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.ObjectPool.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.ConfigurationExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.WebEncoders.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.JSInterop.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Net.Http.Headers.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.VisualBasic.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.VisualBasic.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Win32.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Win32.Registry.dll`
- `D -> src/C#/Kjitweb/publish-service/Novell.Directory.Ldap.NETStandard.dll`
- `A -> src/C#/Kjitweb/publish-service/System.AppContext.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Buffers.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Concurrent.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Immutable.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.NonGeneric.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Specialized.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.Annotations.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.EventBasedAsync.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.TypeConverter.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Console.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.DataSetExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Contracts.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Debug.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.DiagnosticSource.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.EventLog.Messages.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.EventLog.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.FileVersionInfo.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Process.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.StackTrace.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.TextWriterTraceListener.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Tools.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.TraceSource.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Tracing.dll`
- `M -> src/C#/Kjitweb/publish-service/System.DirectoryServices.Protocols.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Drawing.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Drawing.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Dynamic.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Formats.Asn1.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Formats.Tar.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.Calendars.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.Brotli.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.FileSystem.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.Native.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.ZipFile.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.DriveInfo.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.Watcher.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.IsolatedStorage.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.MemoryMappedFiles.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipelines.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipes.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipes.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.UnmanagedMemoryStream.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Expressions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Parallel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Queryable.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Memory.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Http.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.HttpListener.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Mail.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.NameResolution.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.NetworkInformation.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Ping.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Quic.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Requests.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Security.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.ServicePoint.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Sockets.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebClient.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebHeaderCollection.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebProxy.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebSockets.Client.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebSockets.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Numerics.Vectors.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Numerics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ObjectModel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.CoreLib.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.DataContractSerialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Uri.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Xml.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.DispatchProxy.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.ILGeneration.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.Lightweight.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Metadata.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.TypeExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.Reader.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.ResourceManager.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.Writer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.CompilerServices.Unsafe.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.CompilerServices.VisualC.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Handles.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.JavaScript.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.RuntimeInformation.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Intrinsics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Loader.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Numerics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Formatters.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Claims.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Algorithms.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Cng.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Csp.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Encoding.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.OpenSsl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Pkcs.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.X509Certificates.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Principal.Windows.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Principal.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.SecureString.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ServiceModel.Web.dll`
- `M -> src/C#/Kjitweb/publish-service/System.ServiceProcess.ServiceController.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ServiceProcess.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.CodePages.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encodings.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.RegularExpressions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Channels.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Overlapped.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.RateLimiting.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Dataflow.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Parallel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Thread.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.ThreadPool.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Timer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Transactions.Local.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Transactions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ValueTuple.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Web.HttpUtility.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Windows.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.ReaderWriter.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.Serialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XPath.XDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XPath.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XmlDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XmlSerializer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.dll`
- `A -> src/C#/Kjitweb/publish-service/WindowsBase.dll`
- `D -> src/C#/Kjitweb/publish-service/appsettings.Development.json`
- `M -> src/C#/Kjitweb/publish-service/appsettings.json`
- `A -> src/C#/Kjitweb/publish-service/aspnetcorev2_inprocess.dll`
- `A -> src/C#/Kjitweb/publish-service/clretwrc.dll`
- `A -> src/C#/Kjitweb/publish-service/clrgc.dll`
- `A -> src/C#/Kjitweb/publish-service/clrjit.dll`
- `A -> src/C#/Kjitweb/publish-service/coreclr.dll`
- `A -> src/C#/Kjitweb/publish-service/createdump.exe`
- `M -> src/C#/Kjitweb/publish-service/de/KjitWeb.resources.dll`
- `M -> src/C#/Kjitweb/publish-service/en/KjitWeb.resources.dll`
- `A -> src/C#/Kjitweb/publish-service/hostfxr.dll`
- `A -> src/C#/Kjitweb/publish-service/hostpolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordaccore.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordaccore_amd64_amd64_8.0.2726.22922.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordbi.dll`
- `A -> src/C#/Kjitweb/publish-service/mscorlib.dll`
- `A -> src/C#/Kjitweb/publish-service/mscorrc.dll`
- `A -> src/C#/Kjitweb/publish-service/msquic.dll`
- `A -> src/C#/Kjitweb/publish-service/netstandard.dll`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.deps.json`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.runtimeconfig.json`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.staticwebassets.endpoints.json`
- `D -> src/C#/Kjitweb/publish-service/publish/appsettings.Development.json`
- `D -> src/C#/Kjitweb/publish-service/publish/appsettings.json`
- `D -> src/C#/Kjitweb/publish-service/publish/web.config`
- `D -> src/C#/Kjitweb/publish-service/runtimes/linux/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/osx/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.dll`
- `A -> src/C#/Kjitweb/set-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/uninstall-service.ps1`
- `A -> src/C#/Kjitweb/update-kjitweb.ps1`
- `A -> src/C#/Kjitweb/wwwroot/lib/bootstrap/css/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/bootstrap/css/bootstrap.min.css`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation-unobtrusive/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation/jquery.validate.min.js`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery/jquery.min.js`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/ElevateUser.ps1`
- `M -> src/Powershell/Scripts/README.md`
- `M -> src/Powershell/Scripts/RequestAdminAccessUI.ps1`
- `A -> src/Powershell/Scripts/Show-KjitConfiguration.ps1`
- `M -> src/Powershell/Scripts/Tier1LocalAdminGroup.ps1`
- `M -> src/Powershell/Scripts/install-JIT.ps1`
- `A -> src/Powershell/TestEnvironment/Test-Environment.md`
- `M -> src/Powershell/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> src/Powershell/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-configuration.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-request.psm1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `A -> tests/PowerShell/Modules.Tests.ps1`
- `A -> tmp_ps51_test.ps1`
- `A -> tmp_release_test.ps1`

## 2026-09-26 22:13:45 +02:00 - `main` to `origin/main`

Commits:

<!-- commit:5300906e99aeded5cf1c1574c90f2b94a8db862a -->
- `5300906` version 0.1.20260507
<!-- commit:9cd885f917b716436ac205a9ae1a8fa3407f1a95 -->
- `9cd885f` Add version policy and AD test environment
<!-- commit:7270377cd4f80b810cac79976c34f4fe56e2d152 -->
- `7270377` Version 0.1.20260824
<!-- commit:a11dbdc039fffc56405adcb574fe4e54958f9f30 -->
- `a11dbdc` Version 0.1.20260907: improve KjitWeb operations
<!-- commit:6fd798b0ef469dea38a1afd1119aab6f13eaae7c -->
- `6fd798b` Add push history and installation packaging
<!-- commit:69d64a83e7028fb9a0b05992aaaf98253320e822 -->
- `69d64a8` Document GitHub push history
<!-- commit:04d0b12477ed30b90e4989b93db5820badc97a4c -->
- `04d0b12` Improve installation and architecture documentation
<!-- commit:215d67b469108aa356f96c61ebd5d4b9a6203749 -->
- `215d67b` Document GitHub push history
<!-- commit:a95089e418ad9bee11e87cceb94179ae21a706eb -->
- `a95089e` Document T1JIT workflows
<!-- commit:4a5d93be94f8c632a88f9c05fa394b98376f4463 -->
- `4a5d93b` Document GitHub push history
<!-- commit:0d165416d85588781d1b582fb60302cddaaf85de -->
- `0d16541` Document secure T1JIT access workflows
<!-- commit:e16e1b342607bd6dd36d979625b204915a25cd1a -->
- `e16e1b3` Prepare test release 0.1.20260907.34
<!-- commit:7baa5e22f30d2723cfed88c389bebc87cabe064b -->
- `7baa5e2` Show KjitWeb version in footer
<!-- commit:3822ba9733201d8ead5c1696cec78f984ebb72fa -->
- `3822ba9` Improve PowerShell module documentation and configuration
<!-- commit:d5fcd9267054d85196da0d3a55931a0abfe7e719 -->
- `d5fcd92` Fix PowerShell module runtime compatibility
<!-- commit:c36efe53ad2ac918058d66160effeb67569df37b -->
- `c36efe5` Document GitHub push history
<!-- commit:351d80bb2fdecbaa375116bc84d5614ef8ef9305 -->
- `351d80b` Add repeatable JIT installation testing
<!-- commit:b31864acba61652f1fbb05a715ffde425ba05386 -->
- `b31864a` Document GitHub push history
<!-- commit:12a5b6ebda697b0d4f783d59107fc61457b0d59e -->
- `12a5b6e` Harden JIT installation and diagnostics
<!-- commit:b6e3f563ef329e9f442a5a69b79a5ddb36697c66 -->
- `b6e3f56` Document GitHub push history
<!-- commit:4c3754475610a98d10a1db135dc6c2264942bb06 -->
- `4c37544` Improve multi-domain search diagnostics
<!-- commit:51d348f1d940f25c6e7c85a2545aa79ddd327a36 -->
- `51d348f` Document GitHub push history
<!-- commit:2fa36140999b44cda8d554433a2658a1acd6e2e2 -->
- `2fa3614` Document Config-JIT workflow
<!-- commit:b71873be0a17403fde2ef3539a69192510713ecd -->
- `b71873b` Document GitHub push history
<!-- commit:1f9fadf40e9bb4d24417a9fa62372ddadff55f06 -->
- `1f9fadf` Harden JIT provisioning and request handling
<!-- commit:ffde186ec4fb1f98a73ace7a695102de577edd10 -->
- `ffde186` Document GitHub push history
<!-- commit:0b30e312af34d4539b15cadb4255a0077064e6af -->
- `0b30e31` Secure KjitWeb access and logging
<!-- commit:fee35327107eae3705954805a77579d4b5e33a3c -->
- `fee3532` Document GitHub push history
<!-- commit:eb4021a8bcf981deb392787c799e7f831c0bac81 -->
- `eb4021a` Prevent transient delegation config reads
<!-- commit:befb60253b846bfc8eec7cd60b0119aca0adb0d4 -->
- `befb602` Document GitHub push history
<!-- commit:b0d0066a780a8298251d17ca4613821ab720727a -->
- `b0d0066` Fix KjitWeb delegation and automate release builds
<!-- commit:9196ebc83b70080337531ea127426c4e6bed5d09 -->
- `9196ebc` Fix relative KjitWeb search bases
<!-- commit:a6350976e9b5cb8601405ef705a9f57c7d15b3da -->
- `a635097` Document GitHub push history
<!-- commit:653456bb3120674056ccefcb65ffb3d5bb31c0de -->
- `653456b` Rename release output to kJITWeb, automate ZIP packaging, document KjitWeb updates
<!-- commit:0b4d13a65f53814704d065a7a4054fba1f21a848 -->
- `0b4d13a` Package installation output as a single ZIP named by version and branch
<!-- commit:e20024d7094eabfae077ba64feefb5b2764beb51 -->
- `e20024d` Add a user-facing CHANGELOG.md and wire it into the release process
<!-- commit:2ece1b5373a6069580e263938a2fe2ee14dc3346 -->
- `2ece1b5` Detect existing installations in install-JIT.ps1 and update in place
<!-- commit:923155d1754e2847103f74b5f530e4f9ff5d57ed -->
- `923155d` Add KjitWeb Kerberos SPN automation, GMSA permission handling, and persist management scripts
<!-- commit:622577716c37bf1c5aea546f79b0d5567fb901ab -->
- `6225777` Document GitHub push history
<!-- commit:18c6a91ea15604172e01c61618abda836ad42910 -->
- `18c6a91` Bump version scheme to 0.2 and condense CHANGELOG unreleased section
<!-- commit:edb8886eb88f79c8958efb1469479e8bed8741c4 -->
- `edb8886` Document GitHub push history
<!-- commit:a14e8b5beb3578d66b87156fe91a90e22290832e -->
- `a14e8b5` Fix JIT configuration compatibility and gate packages
<!-- commit:382e294d7456028cdda6b5e04150174a3c887049 -->
- `382e294` Document GitHub push history
<!-- commit:c682ef837cca26255bed52155c080b969d264531 -->
- `c682ef8` Allow module version updates in history commits
<!-- commit:9b5b059085811564b226c4ce2443b5bff9f3eccb -->
- `9b5b059` Document GitHub push history
<!-- commit:1f49deb40658670cc0d8c2bd300a409e954313bc -->
- `1f49deb` Complete module API documentation
<!-- commit:25532c61aa1230d51caf22c273f7cb6f85e438dd -->
- `25532c6` Document GitHub push history
<!-- commit:5624d9dfe5ce4b467c6e8a0ceb4ce5af7d083701 -->
- `5624d9d` Document C# APIs and harden KjitWeb firewall setup
<!-- commit:c0dfa31d46a80319aae9e178185af14b8952f184 -->
- `c0dfa31` Restructure documentation and harden release build
<!-- commit:37ffc9e9933201aa3d9bedc1828670e54fe8e4f9 -->
- `37ffc9e` Document GitHub push history
<!-- commit:f1625f5d1aa22f6c5965da81512d85b25e6b64bb -->
- `f1625f5` Merge dev into main for production release
<!-- commit:07ec9d287e42c2d2b3e92cc5ccc35704872f9499 -->
- `07ec9d2` Prepare 0.2.20260926.12 production release

Changed files:

- `A -> .githooks/pre-commit`
- `A -> .githooks/pre-commit.ps1`
- `A -> .githooks/pre-push`
- `A -> .githooks/pre-push.ps1`
- `A -> .github/workflows/version-policy.yml`
- `M -> .gitignore`
- `A -> .markdownlint.json`
- `A -> CHANGELOG.md`
- `A -> Developer.md`
- `A -> EVENTS.md`
- `M -> README.md`
- `A -> VERSION`
- `A -> build/New-InstallationPackage.ps1`
- `A -> build/Push-GitHub.ps1`
- `A -> build/Test-PowerShellModules.ps1`
- `A -> build/Update-Version.ps1`
- `M -> build/release_build.ps1`
- `M -> docs/Authentication.md`
- `M -> docs/Events.md`
- `M -> docs/Installation.md`
- `M -> docs/Kerberos-Setup.md`
- `M -> docs/config.jit.example`
- `A -> file-versions.json`
- `M -> release/Config-JIT.ps1`
- `M -> release/ElevateUser.ps1`
- `M -> release/RequestAdminAccessUI.ps1`
- `A -> release/Show-KjitConfiguration.ps1`
- `M -> release/Tier1LocalAdminGroup.ps1`
- `A -> release/VERSION`
- `A -> release/file-versions.json`
- `M -> release/install-JIT.ps1`
- `A -> release/kJITWeb/appsettings.Production.json`
- `A -> release/kJITWeb/appsettings.json`
- `R063 -> release/kjibweb/install-kjitweb.ps1 -> release/kJITWeb/install-kjitweb.ps1`
- `R100 -> release/kjibweb/kjitlogo.png -> release/kJITWeb/kjitlogo.png`
- `A -> release/kJITWeb/publish-service/KjitWeb.deps.json`
- `A -> release/kJITWeb/publish-service/KjitWeb.dll`
- `R097 -> release/kjibweb/publish-service/KjitWeb.exe -> release/kJITWeb/publish-service/KjitWeb.exe`
- `A -> release/kJITWeb/publish-service/KjitWeb.pdb`
- `R084 -> release/kjibweb/publish-service/KjitWeb.runtimeconfig.json -> release/kJITWeb/publish-service/KjitWeb.runtimeconfig.json`
- `A -> release/kJITWeb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `A -> release/kJITWeb/publish-service/KjitWeb.xml`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Antiforgery.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.BearerToken.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Cookies.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.OAuth.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authentication.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authorization.Policy.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Authorization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Authorization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Endpoints.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Forms.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Server.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.Web.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Components.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Connections.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.CookiePolicy.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cors.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cryptography.Internal.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Cryptography.KeyDerivation.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.Extensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.DataProtection.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.HealthChecks.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Diagnostics.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HostFiltering.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.Server.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Hosting.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Html.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Connections.Common.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Connections.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Extensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Features.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.Results.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Http.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpLogging.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpOverrides.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.HttpsPolicy.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Identity.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Localization.Routing.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Localization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Metadata.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.ApiExplorer.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Cors.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.DataAnnotations.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Json.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Xml.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Localization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.Razor.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.RazorPages.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.TagHelpers.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.ViewFeatures.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Mvc.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.OutputCaching.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.RateLimiting.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Razor.Runtime.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Razor.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.RequestDecompression.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCaching.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCaching.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.ResponseCompression.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Rewrite.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Routing.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Routing.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.HttpSys.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.IIS.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.IISIntegration.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.NamedPipes.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Quic.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Server.Kestrel.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.Session.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Common.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.Protocols.Json.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.SignalR.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.StaticFiles.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.WebSockets.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.WebUtilities.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.AspNetCore.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.CSharp.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.DiaSymReader.Native.amd64.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Caching.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Caching.Memory.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Binder.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.CommandLine.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.EnvironmentVariables.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.FileExtensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Ini.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Json.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.KeyPerFile.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.UserSecrets.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.Xml.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Configuration.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.DependencyInjection.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.DependencyInjection.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Diagnostics.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Features.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Composite.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Embedded.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileProviders.Physical.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.FileSystemGlobbing.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.Abstractions.dll`
- `R070 -> release/kjibweb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Hosting.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Http.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Identity.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Identity.Stores.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Localization.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Localization.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Abstractions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Configuration.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Console.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.Debug.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.EventLog.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.EventSource.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.TraceSource.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Logging.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.ObjectPool.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.ConfigurationExtensions.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.DataAnnotations.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Options.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.Primitives.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Extensions.WebEncoders.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.JSInterop.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Net.Http.Headers.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.VisualBasic.Core.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.VisualBasic.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Win32.Primitives.dll`
- `A -> release/kJITWeb/publish-service/Microsoft.Win32.Registry.dll`
- `A -> release/kJITWeb/publish-service/System.AppContext.dll`
- `A -> release/kJITWeb/publish-service/System.Buffers.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.Concurrent.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.Immutable.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.NonGeneric.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.Specialized.dll`
- `A -> release/kJITWeb/publish-service/System.Collections.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.Annotations.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.DataAnnotations.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.EventBasedAsync.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.TypeConverter.dll`
- `A -> release/kJITWeb/publish-service/System.ComponentModel.dll`
- `A -> release/kJITWeb/publish-service/System.Configuration.dll`
- `A -> release/kJITWeb/publish-service/System.Console.dll`
- `A -> release/kJITWeb/publish-service/System.Core.dll`
- `A -> release/kJITWeb/publish-service/System.Data.Common.dll`
- `A -> release/kJITWeb/publish-service/System.Data.DataSetExtensions.dll`
- `A -> release/kJITWeb/publish-service/System.Data.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Contracts.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Debug.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.DiagnosticSource.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.EventLog.Messages.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.EventLog.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.FileVersionInfo.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Process.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.StackTrace.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.TextWriterTraceListener.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Tools.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.TraceSource.dll`
- `A -> release/kJITWeb/publish-service/System.Diagnostics.Tracing.dll`
- `A -> release/kJITWeb/publish-service/System.DirectoryServices.Protocols.dll`
- `A -> release/kJITWeb/publish-service/System.Drawing.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Drawing.dll`
- `A -> release/kJITWeb/publish-service/System.Dynamic.Runtime.dll`
- `A -> release/kJITWeb/publish-service/System.Formats.Asn1.dll`
- `A -> release/kJITWeb/publish-service/System.Formats.Tar.dll`
- `A -> release/kJITWeb/publish-service/System.Globalization.Calendars.dll`
- `A -> release/kJITWeb/publish-service/System.Globalization.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Globalization.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.Brotli.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.FileSystem.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.Native.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.ZipFile.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Compression.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.AccessControl.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.DriveInfo.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.Watcher.dll`
- `A -> release/kJITWeb/publish-service/System.IO.FileSystem.dll`
- `A -> release/kJITWeb/publish-service/System.IO.IsolatedStorage.dll`
- `A -> release/kJITWeb/publish-service/System.IO.MemoryMappedFiles.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Pipelines.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Pipes.AccessControl.dll`
- `A -> release/kJITWeb/publish-service/System.IO.Pipes.dll`
- `A -> release/kJITWeb/publish-service/System.IO.UnmanagedMemoryStream.dll`
- `A -> release/kJITWeb/publish-service/System.IO.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.Expressions.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.Parallel.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.Queryable.dll`
- `A -> release/kJITWeb/publish-service/System.Linq.dll`
- `A -> release/kJITWeb/publish-service/System.Memory.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Http.Json.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Http.dll`
- `A -> release/kJITWeb/publish-service/System.Net.HttpListener.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Mail.dll`
- `A -> release/kJITWeb/publish-service/System.Net.NameResolution.dll`
- `A -> release/kJITWeb/publish-service/System.Net.NetworkInformation.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Ping.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Quic.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Requests.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Security.dll`
- `A -> release/kJITWeb/publish-service/System.Net.ServicePoint.dll`
- `A -> release/kJITWeb/publish-service/System.Net.Sockets.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebClient.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebHeaderCollection.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebProxy.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebSockets.Client.dll`
- `A -> release/kJITWeb/publish-service/System.Net.WebSockets.dll`
- `A -> release/kJITWeb/publish-service/System.Net.dll`
- `A -> release/kJITWeb/publish-service/System.Numerics.Vectors.dll`
- `A -> release/kJITWeb/publish-service/System.Numerics.dll`
- `A -> release/kJITWeb/publish-service/System.ObjectModel.dll`
- `A -> release/kJITWeb/publish-service/System.Private.CoreLib.dll`
- `A -> release/kJITWeb/publish-service/System.Private.DataContractSerialization.dll`
- `A -> release/kJITWeb/publish-service/System.Private.Uri.dll`
- `A -> release/kJITWeb/publish-service/System.Private.Xml.Linq.dll`
- `A -> release/kJITWeb/publish-service/System.Private.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.DispatchProxy.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Emit.ILGeneration.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Emit.Lightweight.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Emit.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Metadata.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.TypeExtensions.dll`
- `A -> release/kJITWeb/publish-service/System.Reflection.dll`
- `A -> release/kJITWeb/publish-service/System.Resources.Reader.dll`
- `A -> release/kJITWeb/publish-service/System.Resources.ResourceManager.dll`
- `A -> release/kJITWeb/publish-service/System.Resources.Writer.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.CompilerServices.Unsafe.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.CompilerServices.VisualC.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Handles.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.InteropServices.JavaScript.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.InteropServices.RuntimeInformation.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.InteropServices.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Intrinsics.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Loader.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Numerics.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Formatters.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Json.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.Serialization.dll`
- `A -> release/kJITWeb/publish-service/System.Runtime.dll`
- `A -> release/kJITWeb/publish-service/System.Security.AccessControl.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Claims.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Algorithms.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Cng.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Csp.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Encoding.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.OpenSsl.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Pkcs.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Primitives.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.X509Certificates.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Cryptography.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Principal.Windows.dll`
- `A -> release/kJITWeb/publish-service/System.Security.Principal.dll`
- `A -> release/kJITWeb/publish-service/System.Security.SecureString.dll`
- `A -> release/kJITWeb/publish-service/System.Security.dll`
- `A -> release/kJITWeb/publish-service/System.ServiceModel.Web.dll`
- `R088 -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.ServiceProcess.ServiceController.dll -> release/kJITWeb/publish-service/System.ServiceProcess.ServiceController.dll`
- `A -> release/kJITWeb/publish-service/System.ServiceProcess.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encoding.CodePages.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encoding.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encoding.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Encodings.Web.dll`
- `A -> release/kJITWeb/publish-service/System.Text.Json.dll`
- `A -> release/kJITWeb/publish-service/System.Text.RegularExpressions.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Channels.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Overlapped.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.RateLimiting.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.Dataflow.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.Extensions.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.Parallel.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Tasks.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Thread.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.ThreadPool.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.Timer.dll`
- `A -> release/kJITWeb/publish-service/System.Threading.dll`
- `A -> release/kJITWeb/publish-service/System.Transactions.Local.dll`
- `A -> release/kJITWeb/publish-service/System.Transactions.dll`
- `A -> release/kJITWeb/publish-service/System.ValueTuple.dll`
- `A -> release/kJITWeb/publish-service/System.Web.HttpUtility.dll`
- `A -> release/kJITWeb/publish-service/System.Web.dll`
- `A -> release/kJITWeb/publish-service/System.Windows.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.Linq.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.ReaderWriter.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.Serialization.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XDocument.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XPath.XDocument.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XPath.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XmlDocument.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.XmlSerializer.dll`
- `A -> release/kJITWeb/publish-service/System.Xml.dll`
- `A -> release/kJITWeb/publish-service/System.dll`
- `A -> release/kJITWeb/publish-service/WindowsBase.dll`
- `R100 -> release/kjibweb/publish-service/app_data/JIT.test.config -> release/kJITWeb/publish-service/app_data/JIT.test.config`
- `R082 -> release/kjibweb/publish-service/appsettings.Production.json -> release/kJITWeb/publish-service/appsettings.Production.json`
- `A -> release/kJITWeb/publish-service/appsettings.json`
- `A -> release/kJITWeb/publish-service/aspnetcorev2_inprocess.dll`
- `A -> release/kJITWeb/publish-service/clretwrc.dll`
- `A -> release/kJITWeb/publish-service/clrgc.dll`
- `A -> release/kJITWeb/publish-service/clrjit.dll`
- `A -> release/kJITWeb/publish-service/coreclr.dll`
- `A -> release/kJITWeb/publish-service/createdump.exe`
- `A -> release/kJITWeb/publish-service/de/KjitWeb.resources.dll`
- `A -> release/kJITWeb/publish-service/en/KjitWeb.resources.dll`
- `A -> release/kJITWeb/publish-service/hostfxr.dll`
- `A -> release/kJITWeb/publish-service/hostpolicy.dll`
- `A -> release/kJITWeb/publish-service/mscordaccore.dll`
- `A -> release/kJITWeb/publish-service/mscordaccore_amd64_amd64_8.0.2726.22922.dll`
- `A -> release/kJITWeb/publish-service/mscordbi.dll`
- `A -> release/kJITWeb/publish-service/mscorlib.dll`
- `A -> release/kJITWeb/publish-service/mscorrc.dll`
- `A -> release/kJITWeb/publish-service/msquic.dll`
- `A -> release/kJITWeb/publish-service/netstandard.dll`
- `R100 -> release/kjibweb/publish-service/web.config -> release/kJITWeb/publish-service/web.config`
- `R100 -> release/kjibweb/publish-service/wwwroot/images/kjitlogo.png -> release/kJITWeb/publish-service/wwwroot/images/kjitlogo.png`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/bootstrap/css/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/bootstrap/css/bootstrap.min.css`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation-unobtrusive/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery-validation/jquery.validate.min.js`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery/LICENSE`
- `A -> release/kJITWeb/publish-service/wwwroot/lib/jquery/jquery.min.js`
- `A -> release/kJITWeb/set-kjitweb-allowedclient.ps1`
- `A -> release/kJITWeb/update-kjitweb.ps1`
- `D -> release/kjibweb/appsettings.Production.json`
- `D -> release/kjibweb/appsettings.json`
- `D -> release/kjibweb/publish-service/KjitWeb.deps.json`
- `D -> release/kjibweb/publish-service/KjitWeb.dll`
- `D -> release/kjibweb/publish-service/KjitWeb.pdb`
- `D -> release/kjibweb/publish-service/KjitWeb.staticwebassets.endpoints.json`
- `D -> release/kjibweb/publish-service/Microsoft.AspNetCore.Authentication.Negotiate.dll`
- `D -> release/kjibweb/publish-service/Novell.Directory.Ldap.NETStandard.dll`
- `D -> release/kjibweb/publish-service/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/System.ServiceProcess.ServiceController.dll`
- `D -> release/kjibweb/publish-service/appsettings.Development.json`
- `D -> release/kjibweb/publish-service/appsettings.json`
- `D -> release/kjibweb/publish-service/de/KjitWeb.resources.dll`
- `D -> release/kjibweb/publish-service/en/KjitWeb.resources.dll`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.deps.json`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.runtimeconfig.json`
- `D -> release/kjibweb/publish-service/publish/KjitWeb.staticwebassets.endpoints.json`
- `D -> release/kjibweb/publish-service/publish/appsettings.Development.json`
- `D -> release/kjibweb/publish-service/publish/appsettings.json`
- `D -> release/kjibweb/publish-service/publish/web.config`
- `D -> release/kjibweb/publish-service/runtimes/linux/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/osx/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.dll`
- `D -> release/kjibweb/publish-service/runtimes/win/lib/net8.0/System.ServiceProcess.ServiceController.dll`
- `A -> release/modules/0.1/KjitCore.dll`
- `M -> release/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> release/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> release/modules/0.1/just-in-time-configuration.psm1`
- `M -> release/modules/0.1/just-in-time-request.psm1`
- `M -> release/modules/Just-In-time.psd1`
- `A -> src/C#/KjitCore.DebugHost/KjitCore.DebugHost.csproj`
- `A -> src/C#/KjitCore.DebugHost/Program.cs`
- `A -> src/C#/KjitCore/Abstractions/IDistinguishedNameService.cs`
- `A -> src/C#/KjitCore/Abstractions/IIdentityNormalizer.cs`
- `A -> src/C#/KjitCore/KjitCore.cs`
- `A -> src/C#/KjitCore/KjitCore.csproj`
- `A -> src/C#/KjitCore/Models/JitConfigurationObject.cs`
- `A -> src/C#/KjitCore/README.md`
- `A -> src/C#/KjitCore/Services/DistinguishedNameService.cs`
- `A -> src/C#/KjitCore/Services/IdentityNormalizer.cs`
- `A -> src/C#/KjitCore/Services/JitConfigurationReader.cs`
- `M -> src/C#/Kjitweb/Controllers/HomeController.cs`
- `M -> src/C#/Kjitweb/GlobalUsings.cs`
- `M -> src/C#/Kjitweb/KjitWeb.csproj`
- `A -> src/C#/Kjitweb/Models/ElevatedComputerViewModel.cs`
- `M -> src/C#/Kjitweb/Models/ServerSelectionViewModel.cs`
- `M -> src/C#/Kjitweb/Models/SwitchUserViewModel.cs`
- `M -> src/C#/Kjitweb/Program.cs`
- `M -> src/C#/Kjitweb/Resources/SharedResource.de.resx`
- `M -> src/C#/Kjitweb/Resources/SharedResource.en.resx`
- `M -> src/C#/Kjitweb/Services/ActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/BasicAuthenticationHandler.cs`
- `M -> src/C#/Kjitweb/Services/ConnectionAuditLogger.cs`
- `M -> src/C#/Kjitweb/Services/DebugFileLoggerProvider.cs`
- `M -> src/C#/Kjitweb/Services/DebugLogFileWriter.cs`
- `A -> src/C#/Kjitweb/Services/EventLogHealthMonitor.cs`
- `A -> src/C#/Kjitweb/Services/EventLogHealthSnapshot.cs`
- `M -> src/C#/Kjitweb/Services/EventLogWriter.cs`
- `M -> src/C#/Kjitweb/Services/IActiveDirectoryService.cs`
- `M -> src/C#/Kjitweb/Services/IConnectionAuditLogger.cs`
- `A -> src/C#/Kjitweb/Services/IEventLogHealthMonitor.cs`
- `M -> src/C#/Kjitweb/Services/IEventLogWriter.cs`
- `M -> src/C#/Kjitweb/Services/JitConfigPathResolver.cs`
- `A -> src/C#/Kjitweb/Services/MutualTlsCertificateValidator.cs`
- `A -> src/C#/Kjitweb/Services/MutualTlsOptions.cs`
- `M -> src/C#/Kjitweb/Services/WindowsCredentialValidator.cs`
- `M -> src/C#/Kjitweb/Services/configuration.cs`
- `M -> src/C#/Kjitweb/SharedResource.cs`
- `M -> src/C#/Kjitweb/Views/Home/Index.cshtml`
- `M -> src/C#/Kjitweb/Views/Shared/_Layout.cshtml`
- `M -> src/C#/Kjitweb/appsettings.Development.json`
- `M -> src/C#/Kjitweb/appsettings.Production.json`
- `M -> src/C#/Kjitweb/appsettings.json`
- `M -> src/C#/Kjitweb/install-kjitweb.ps1`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.deps.json`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.dll`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.exe`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.pdb`
- `M -> src/C#/Kjitweb/publish-service/KjitWeb.runtimeconfig.json`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Antiforgery.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.BearerToken.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Cookies.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Core.dll`
- `M -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.Negotiate.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.OAuth.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authentication.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authorization.Policy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Authorization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Authorization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Endpoints.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Forms.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Server.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Components.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Connections.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.CookiePolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cors.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cryptography.Internal.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Cryptography.KeyDerivation.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.DataProtection.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.HealthChecks.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Diagnostics.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HostFiltering.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.Server.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Hosting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Html.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Connections.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Connections.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Features.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.Results.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpLogging.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpOverrides.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.HttpsPolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Identity.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Localization.Routing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Metadata.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.ApiExplorer.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Cors.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Formatters.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.Razor.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.RazorPages.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.TagHelpers.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.ViewFeatures.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Mvc.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.OutputCaching.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.RateLimiting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Razor.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Razor.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.RequestDecompression.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCaching.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCaching.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.ResponseCompression.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Rewrite.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Routing.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Routing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.HttpSys.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.IIS.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.IISIntegration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.NamedPipes.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Quic.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.Transport.Sockets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Server.Kestrel.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.Session.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.Protocols.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.SignalR.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.StaticFiles.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.WebSockets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.WebUtilities.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.AspNetCore.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.CSharp.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.DiaSymReader.Native.amd64.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Caching.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Caching.Memory.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Binder.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.CommandLine.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.EnvironmentVariables.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.FileExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Ini.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.KeyPerFile.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.UserSecrets.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.DependencyInjection.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.DependencyInjection.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.HealthChecks.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Diagnostics.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Features.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Composite.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Embedded.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileProviders.Physical.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.FileSystemGlobbing.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.Abstractions.dll`
- `M -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.WindowsServices.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Hosting.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Identity.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Identity.Stores.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Localization.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Localization.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Abstractions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Console.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.Debug.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.EventLog.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.EventSource.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.TraceSource.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Logging.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.ObjectPool.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.ConfigurationExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Options.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Extensions.WebEncoders.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.JSInterop.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Net.Http.Headers.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.VisualBasic.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.VisualBasic.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Win32.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/Microsoft.Win32.Registry.dll`
- `D -> src/C#/Kjitweb/publish-service/Novell.Directory.Ldap.NETStandard.dll`
- `A -> src/C#/Kjitweb/publish-service/System.AppContext.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Buffers.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Concurrent.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Immutable.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.NonGeneric.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.Specialized.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Collections.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.Annotations.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.DataAnnotations.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.EventBasedAsync.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.TypeConverter.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ComponentModel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Configuration.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Console.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Core.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.Common.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.DataSetExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Data.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Contracts.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Debug.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.DiagnosticSource.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.EventLog.Messages.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.EventLog.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.FileVersionInfo.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Process.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.StackTrace.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.TextWriterTraceListener.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Tools.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.TraceSource.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Diagnostics.Tracing.dll`
- `M -> src/C#/Kjitweb/publish-service/System.DirectoryServices.Protocols.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Drawing.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Drawing.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Dynamic.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Formats.Asn1.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Formats.Tar.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.Calendars.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Globalization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.Brotli.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.FileSystem.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.Native.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.ZipFile.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Compression.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.DriveInfo.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.Watcher.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.FileSystem.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.IsolatedStorage.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.MemoryMappedFiles.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipelines.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipes.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.Pipes.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.UnmanagedMemoryStream.dll`
- `A -> src/C#/Kjitweb/publish-service/System.IO.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Expressions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Parallel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.Queryable.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Memory.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Http.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Http.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.HttpListener.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Mail.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.NameResolution.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.NetworkInformation.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Ping.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Quic.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Requests.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Security.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.ServicePoint.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.Sockets.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebClient.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebHeaderCollection.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebProxy.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebSockets.Client.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.WebSockets.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Net.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Numerics.Vectors.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Numerics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ObjectModel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.CoreLib.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.DataContractSerialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Uri.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Xml.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Private.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.DispatchProxy.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.ILGeneration.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.Lightweight.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Emit.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Metadata.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.TypeExtensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Reflection.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.Reader.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.ResourceManager.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Resources.Writer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.CompilerServices.Unsafe.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.CompilerServices.VisualC.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Handles.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.JavaScript.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.RuntimeInformation.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.InteropServices.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Intrinsics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Loader.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Numerics.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Formatters.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.Serialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Runtime.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.AccessControl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Claims.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Algorithms.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Cng.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Csp.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Encoding.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.OpenSsl.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Pkcs.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Primitives.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.X509Certificates.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Cryptography.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Principal.Windows.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.Principal.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.SecureString.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Security.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ServiceModel.Web.dll`
- `M -> src/C#/Kjitweb/publish-service/System.ServiceProcess.ServiceController.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ServiceProcess.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.CodePages.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encoding.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Encodings.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.Json.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Text.RegularExpressions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Channels.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Overlapped.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.RateLimiting.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Dataflow.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Extensions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.Parallel.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Tasks.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Thread.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.ThreadPool.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.Timer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Threading.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Transactions.Local.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Transactions.dll`
- `A -> src/C#/Kjitweb/publish-service/System.ValueTuple.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Web.HttpUtility.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Web.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Windows.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.Linq.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.ReaderWriter.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.Serialization.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XPath.XDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XPath.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XmlDocument.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.XmlSerializer.dll`
- `A -> src/C#/Kjitweb/publish-service/System.Xml.dll`
- `A -> src/C#/Kjitweb/publish-service/System.dll`
- `A -> src/C#/Kjitweb/publish-service/WindowsBase.dll`
- `D -> src/C#/Kjitweb/publish-service/appsettings.Development.json`
- `M -> src/C#/Kjitweb/publish-service/appsettings.json`
- `A -> src/C#/Kjitweb/publish-service/aspnetcorev2_inprocess.dll`
- `A -> src/C#/Kjitweb/publish-service/clretwrc.dll`
- `A -> src/C#/Kjitweb/publish-service/clrgc.dll`
- `A -> src/C#/Kjitweb/publish-service/clrjit.dll`
- `A -> src/C#/Kjitweb/publish-service/coreclr.dll`
- `A -> src/C#/Kjitweb/publish-service/createdump.exe`
- `M -> src/C#/Kjitweb/publish-service/de/KjitWeb.resources.dll`
- `M -> src/C#/Kjitweb/publish-service/en/KjitWeb.resources.dll`
- `A -> src/C#/Kjitweb/publish-service/hostfxr.dll`
- `A -> src/C#/Kjitweb/publish-service/hostpolicy.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordaccore.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordaccore_amd64_amd64_8.0.2726.22922.dll`
- `A -> src/C#/Kjitweb/publish-service/mscordbi.dll`
- `A -> src/C#/Kjitweb/publish-service/mscorlib.dll`
- `A -> src/C#/Kjitweb/publish-service/mscorrc.dll`
- `A -> src/C#/Kjitweb/publish-service/msquic.dll`
- `A -> src/C#/Kjitweb/publish-service/netstandard.dll`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.deps.json`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.runtimeconfig.json`
- `D -> src/C#/Kjitweb/publish-service/publish/KjitWeb.staticwebassets.endpoints.json`
- `D -> src/C#/Kjitweb/publish-service/publish/appsettings.Development.json`
- `D -> src/C#/Kjitweb/publish-service/publish/appsettings.json`
- `D -> src/C#/Kjitweb/publish-service/publish/web.config`
- `D -> src/C#/Kjitweb/publish-service/runtimes/linux/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/osx/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.Protocols.dll`
- `D -> src/C#/Kjitweb/publish-service/runtimes/win/lib/net8.0/System.DirectoryServices.dll`
- `A -> src/C#/Kjitweb/set-kjitweb-allowedclient.ps1`
- `M -> src/C#/Kjitweb/uninstall-service.ps1`
- `A -> src/C#/Kjitweb/update-kjitweb.ps1`
- `A -> src/C#/Kjitweb/wwwroot/lib/bootstrap/css/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/bootstrap/css/bootstrap.min.css`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation-unobtrusive/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation-unobtrusive/jquery.validate.unobtrusive.min.js`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery-validation/jquery.validate.min.js`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery/LICENSE`
- `A -> src/C#/Kjitweb/wwwroot/lib/jquery/jquery.min.js`
- `M -> src/Powershell/Scripts/Config-JIT.ps1`
- `M -> src/Powershell/Scripts/ElevateUser.ps1`
- `M -> src/Powershell/Scripts/README.md`
- `M -> src/Powershell/Scripts/RequestAdminAccessUI.ps1`
- `A -> src/Powershell/Scripts/Show-KjitConfiguration.ps1`
- `M -> src/Powershell/Scripts/Tier1LocalAdminGroup.ps1`
- `M -> src/Powershell/Scripts/install-JIT.ps1`
- `A -> src/Powershell/TestEnvironment/Install-T1JitTestInstallation.ps1`
- `A -> src/Powershell/TestEnvironment/New-T1JitTestEnvironment.ps1`
- `A -> src/Powershell/TestEnvironment/Remove-T1JitInstallation.ps1`
- `A -> src/Powershell/TestEnvironment/Test-Environment.md`
- `M -> src/Powershell/modules/0.1/just-in-Time-DelegationConfig.psm1`
- `M -> src/Powershell/modules/0.1/just-in-Time-GUIs.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-configuration.psm1`
- `M -> src/Powershell/modules/0.1/just-in-time-request.psm1`
- `M -> src/Powershell/modules/Just-In-time.psd1`
- `A -> tests/PowerShell/Modules.Tests.ps1`
- `A -> tmp_ps51_test.ps1`
- `A -> tmp_release_test.ps1`




