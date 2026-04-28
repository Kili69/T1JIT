<# 
Script Info

Author: Andreas Lucas [MSFT]
Download: 

Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
damages whatsoever (including, without limitation, damages for loss of business profits, business 
interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages

.SYNOPSIS
    install the KJITweb service on the local machine.
.DESCRIPTION
    This script installs the KJITweb service on the local machine. It copies the necessary files, configures the service, and sets up the required firewall rules.
.PARAMETER DebugLogPath
    Optional path for debug logging. If not provided, the service will look for a DebugLog.Path setting in appsettings.json. If that is also not set, debug logging will be disabled.
.PARAMETER JitConfig
    Path to the Just-In-Time configuration file (JIT.config). If not provided, the script will attempt to determine a default path based on the current domain and prompt the user if the file is not found.
.PARAMETER BinaryPath
    Optional path to the KJITweb executable. If not provided, the script assumes it is located in the installation folder (Program Files\KJITWEB\KJITweb.exe).
.PARAMETER AllowedClient
    Optional hostname or IP address of the allowed client for connecting to the service. Defaults to "localhost". Use "*" to allow any remote client (not recommended for production use).
.EXAMPLE
    .\install-kjitweb.ps1 -JitConfig "C:\Configs\JIT.config" -DebugLogPath "C:\Logs\kjitweb-debug.log" -AllowedClient "adminpc.domain.local"
    Installs the KJITweb service with a specific JIT configuration file, debug log path, and allows connections from a specific client.
.EXAMPLE
    .\install-kjitweb.ps1
    Installs the KJITweb service using default settings, which includes looking for JIT.config in the SYSVOL folder of the current domain, no debug logging, and allowing only localhost connections
.NOTE
    This script must be run with administrator privileges to successfully install the service and configure firewall rules. 
    -Version 0.1.20260430
    initial version 
#>
#Requires -RunAsAdministrator
param(
    # Optional path for debug logging. If not provided, the service will look for a DebugLog.Path setting in appsettings.json. If that is also not set, debug logging will be disabled.
    [string]$DebugLogPath,
    # Path to the Just-In-Time configuration file (JIT.config). If not provided, the script will attempt to determine a default path based on the current domain and prompt the user if the file is not found.
    [string]$JitConfig,
    # Optional path to the KJITweb executable. If not provided, the script assumes it is located in the installation folder (Program Files\KJITWEB\KJITweb.exe).
    [string]$BinaryPath,
    # Optional hostname or IP address of the allowed client for connecting to the service. Defaults to "localhost". Use "*" to allow any remote client (not recommended for production use).
    [string]$AllowedClient
)
# region Initialization and defaults
$_scriptVersion = "0.1.20260430" # Script version for reference. This can be updated with each change to help track versions and ensure that users are aware of the version they are running, especially if there are breaking changes or important updates in future versions. 
$ServiceName  = "KjitWeb" # Service name must not contain spaces for sc.exe compatibility, but display name can have spaces.
$DisplayName  = "KjitWeb Just-In-Time Admin Access" # User-friendly name shown in Services.msc
$Description  = "Browser-based Tier-1 JIT elevation with Kerberos authentication." # Service description shown in Services.msc
$InstallRoot = Join-Path $env:ProgramFiles "KJITWEB" # Installation folder for the service binaries and config. Can be customized if needed, but defaults to Program Files.
$SourceRoot = $PSScriptRoot # Assuming the script is located in the root of the published output folder. Adjust if your layout is different.
$SourceServiceFolder = Join-Path $SourceRoot "publish-service" # Subfolder containing the service binaries and config to be copied to the install location. Adjust if your layout is different.
$InstallServiceFolder = $InstallRoot # Target folder for the service binaries and config. By default, this is a subfolder under Program Files, but it can be customized if needed.
$FirewallRuleName = "KjitWeb Port 5240 Client Restriction" #    
#
$BinaryPath   = if ([string]::IsNullOrWhiteSpace($BinaryPath)) {
    Join-Path $InstallServiceFolder "KjitWeb.exe"
}
else {
    $BinaryPath.Trim()
    Join-Path $InstallServiceFolder "KjitWeb.exe"
}
$ServiceUrl   = $null # Will be determined based on AllowedClient
#endregion
#region Helper functions
<#
.SYNOPSIS
    Copies service files from the source folder to the target installation folder, ensuring the target folder is clean before copying.
.PARAMETER SourceServiceFolder
    The folder containing the service binaries and configuration files to be copied.
.PARAMETER TargetServiceFolder
    The destination folder where the service files should be copied to. This folder will be created if it does not exist, or cleaned if it already exists.
.returns
    None. Exits with an error if the source folder does not exist or if copying fails.
.EXAMPLE
    Copy-ServiceFiles -SourceServiceFolder "C:\Temp\KJITWEB\publish-service" -TargetServiceFolder "C:\Program Files\KJITWEB"
    Copies the service files from the specified source folder to the target folder under Program Files, ensuring that the target folder is clean before copying.
#>
function Copy-ServiceFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceServiceFolder,
        [Parameter(Mandatory = $true)]  
        [string]$TargetServiceFolder
    )
    # Validate source folder exists
    if (-not (Test-Path -Path $SourceServiceFolder -PathType Container)) {
        Write-Error "Source service folder not found: $SourceServiceFolder"
        exit 1
    }
    # Ensure target folder is clean before copying
    if (Test-Path -Path $TargetServiceFolder) {
        Remove-Item -Path $TargetServiceFolder -Recurse -Force
    }
    # Create target folder and copy files
    New-Item -Path $TargetServiceFolder -ItemType Directory -Force | Out-Null
    Copy-Item -Path (Join-Path $SourceServiceFolder "*") -Destination $TargetServiceFolder -Recurse -Force
}

<#
.SYNOPSIS
    Retrieves the current domain name of the computer.
.DESCRIPTION
    This function attempts to determine the current domain name of the computer. It first tries to get the domain using the Active Directory API. If that fails (for example, if the computer is not joined to a domain), it falls back to checking environment variables that may contain the domain information. If it cannot determine the domain, it writes an error and exits.
.RETURNS
    The current domain name as a string.
.EXAMPLE
    $domain = Get-CurrentDomainName
    Retrieves the current domain name of the computer.
#>
function Get-CurrentDomainName {
    try {
        # Attempt to get the domain name using Active Directory API
        return [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name
    }
    catch {
        #
        if (-not [string]::IsNullOrWhiteSpace($env:USERDNSDOMAIN)) {
            return $env:USERDNSDOMAIN
        }
        Write-Error "Could not determine the current domain automatically. Please provide -JitConfig explicitly."
        exit 1
    }
}

<#
.SYNOPSIS
    Retrieves the default path to the JIT configuration file based on the current domain.
.RETURNS
    The default JIT configuration file path as a string.
.EXAMPLE
    $configPath = Get-DefaultJitConfigPath
    Retrieves the default JIT configuration file path based on the current domain.
#>
function Get-DefaultJitConfigPath {
    $currentDomain = Get-CurrentDomainName # Evaluate current domain to construct the default path to JIT.config in the SYSVOL share. This is a common location for domain-wide configuration files, but it can be customized if needed.
    return "\\$currentDomain\SYSVOL\$currentDomain\Just-In-Time\JIT.config"
}

<#
.SYNOPSIS
    Resolves the path to the debug log file based on the provided override path or configuration directory.
.PARAMETER OverridePath
    An optional path to override the default debug log path.
.PARAMETER ConfigDirectory
    The directory containing the configuration file (appsettings.json) to determine the debug log path.
.RETURNS
    The resolved debug log path as a string, or $null if it cannot be determined.
.EXAMPLE
    $logPath = Resolve-DebugLogPath -OverridePath "C:\Logs\debug.log" -ConfigDirectory "C:\Config"
    Resolves the debug log path based on the provided override path or configuration directory.
#>
function Resolve-DebugLogPath {
    param(
        [Parameter(Mandatory = $false)]
        [string]$OverridePath,
        [Parameter(Mandatory = $true)]
        [string]$ConfigDirectory
    )

    # If an override path is provided and not empty, use it directly
    if (-not [string]::IsNullOrWhiteSpace($OverridePath)) {
        return $OverridePath
    }
    # If no override, attempt to read from appsettings.json in the config directory
    $configPath = Join-Path $ConfigDirectory "appsettings.json"
    if (-not (Test-Path $configPath)) {
        return $null
    }

    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json # Attempt to read DebugLog:Path from appsettings.json if it exists. This allows configuration of the debug log path without needing to specify it during installation, while still allowing an override if needed.
        if ($null -ne $config.DebugLog -and -not [string]::IsNullOrWhiteSpace($config.DebugLog.Path)) {
            return [string]$config.DebugLog.Path
        }
    }
    catch {
        # Could not parse appsettings.json, return $null
        Write-Warning "Could not parse $configPath to resolve DebugLog path: $($_.Exception.Message)"
    }

    return $null
}

<#
.SYNOPSIS
    Retrieves the process IDs of processes listening on a specified port.
.PARAMETER Port
    The port number to check for listening processes.
.RETURNS
    An array of process IDs listening on the specified port.
.EXAMPLE
    $pids = Get-PortProcessIds -Port 8080
    Retrieves the process IDs of processes listening on port 8080.
#>
function Get-PortProcessIds {
    param([int]$Port)

    $ids = @()

    $getNetTcpConnection = Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue
    if ($getNetTcpConnection) {
        $ids = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty OwningProcess -Unique
    }
    else {
        $ids = netstat -ano -p tcp |
            Select-String ":$Port\s" |
            ForEach-Object {
                $parts = ($_ -split "\s+") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                if ($parts.Count -gt 0) { [int]$parts[-1] }
            } |
            Select-Object -Unique
    }

    return @($ids | Where-Object { $_ -and $_ -gt 0 })
}

<#
.SYNOPSIS
    Stops all processes listening on a specified port.
.PARAMETER Port
    The port number to stop processes on.
#>
function Stop-ProcessesListeningOnPort {
    [Parameter (Mandatory = $true)]
    param([int]$Port)

    $pids = Get-PortProcessIds -Port $Port # Get process IDs of processes listening on the specified port. This is important to ensure that the KJITweb service can start successfully without port conflicts. If
    foreach ($processId in $pids) {
        try {
            $process = Get-Process -Id $processId -ErrorAction Stop # Attempt to get the process information for better logging. If the process has already exited, this will throw an error and we can skip it.
            Write-Host "Stopping process on port ${Port}: $($process.ProcessName) (PID $processId)"
            Stop-Process -Id $processId -Force -ErrorAction Stop # Attempt to stop the process gracefully, and if that fails, force it. If the process has already exited, this will throw an error and we can skip it.
        }
        catch {
            # If we fail to get the process or stop it, log a warning but continue with the installation. The port might still be in use, and if so, the service will fail to start, but we want to allow the installation to complete so that the user can address the issue (for example by rebooting) without having to rerun the installer.
            Write-Warning "Could not stop PID $processId on port ${Port}: $($_.Exception.Message)"
        }
    }
}

<#
.SYNOPSIS
    Resolves the allowed client addresses for a given client identifier.
.PARAMETER Client
    The client identifier (e.g., hostname, IP address, or wildcard).
.RETURNS
    An array of IP addresses corresponding to the allowed client.
#>
function Resolve-AllowedClientAddresses {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Client
    )

    if ([string]::IsNullOrWhiteSpace($Client)) {
        return @("127.0.0.1", "::1")
    }

    $candidate = $Client.Trim()
    if ($candidate -ieq "localhost") {
        return @("127.0.0.1", "::1")
    }

    # Wildcard: allow connections from any remote address
    if ($candidate -eq "*") {
        return @("Any")
    }

    try {
        $addresses = [System.Net.Dns]::GetHostAddresses($candidate) |
            Select-Object -ExpandProperty IPAddressToString -Unique
        if (-not $addresses -or $addresses.Count -eq 0) {
            throw "No IP addresses resolved."
        }
        return @($addresses)
    }
    catch {
        Write-Error "Could not resolve allowed client '$candidate' to IP address(es): $($_.Exception.Message)"
        exit 1
    }
}

<#
.SYNOPSIS
    Retrieves the service URL based on the allowed client.
.PARAMETER Client
    The client identifier (e.g., hostname, IP address, or wildcard).
.RETURNS
    The service URL corresponding to the allowed client.
#>
function Get-ServiceUrlFromAllowedClient {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Client
    )

    if ([string]::IsNullOrWhiteSpace($Client) -or $Client.Trim() -ieq "localhost") {
        return "http://localhost:5240"
    }

    return "http://*:5240"
}

<#
.SYNOPSIS
    Retrieves the AllowedHosts value for ASP.NET Core host filtering based on the allowed client.
.PARAMETER Client
    The client identifier (e.g., hostname, IP address, or wildcard).
.RETURNS
    A semicolon-separated string for AllowedHosts.
#>
function Get-AllowedHostsFromAllowedClient {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Client
    )

    if ([string]::IsNullOrWhiteSpace($Client)) {
        return "localhost"
    }

    $candidate = $Client.Trim()
    if ($candidate -eq "*") {
        return "*"
    }

    if ($candidate -ieq "localhost") {
        return "localhost"
    }

    # Keep localhost access for local troubleshooting while allowing the configured client.
    return "localhost;$candidate"
}

<#
.SYNOPSIS
    Retrieves the required .NET major version for a given binary.
.PARAMETER BinaryPath
    The path to the binary file.
.RETURNS
    The required .NET major version.
#>
function Get-RequiredDotnetMajorVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BinaryPath
    )

    $runtimeConfigPath = [System.IO.Path]::ChangeExtension($BinaryPath, ".runtimeconfig.json") # The .runtimeconfig.json file is typically located next to the binary and contains information about the required .NET runtime. If this file is missing or cannot be parsed, we will default to requiring .NET 8, which is the minimum supported runtime for KJITweb.
    if (-not (Test-Path -Path $runtimeConfigPath -PathType Leaf)) {
        return 8
    }

    try {
        $runtimeConfig = Get-Content -Path $runtimeConfigPath -Raw | ConvertFrom-Json # Attempt to read the .runtimeconfig.json file to determine the required .NET runtime version. This allows the installer to automatically determine the correct runtime version to install based on the actual binary, which is especially useful if different versions of KJITweb may require different runtimes in the future.
        $frameworkVersion = $null

        if ($runtimeConfig.runtimeOptions.framework.version) {
            $frameworkVersion = [string]$runtimeConfig.runtimeOptions.framework.version # First, check the top-level "framework" section which is used for self-contained deployments. This is the most common case for KJITweb, as it is typically published as a self-contained application. If this section exists, it indicates the required .NET runtime version directly.
        }
        elseif ($runtimeConfig.runtimeOptions.frameworks) {
            # If the "framework" section is not present, check the "frameworks" array which is used for framework-dependent deployments that may target multiple frameworks. In this case, we look for the first entry that matches either "Microsoft.NETCore.App" or "Microsoft.AspNetCore.App", as KJITweb requires both the .NET runtime and ASP.NET Core runtime. This allows us to support more complex deployment scenarios while still correctly determining the required runtime version.
            $fx = $runtimeConfig.runtimeOptions.frameworks |
                Where-Object { $_.name -in @("Microsoft.NETCore.App", "Microsoft.AspNetCore.App") } |
                Select-Object -First 1
            # If we find a matching framework entry, we take its version as the required runtime version. If there are multiple entries, we assume they all require the same major version, which is a common scenario when targeting both the .NET runtime and ASP.NET Core runtime.
            if ($fx -and $fx.version) {
                $frameworkVersion = [string]$fx.version
            }
        }
        # If we cannot find a valid version in the runtime config, default to requiring .NET 8, which is the minimum supported runtime for KJITweb. This ensures that we have a reasonable fallback in case the runtime config is missing or malformed, while still allowing us to support automatic runtime detection when the config is present and valid.
        if ([string]::IsNullOrWhiteSpace($frameworkVersion)) {
            return 8
        }

        return ([version]$frameworkVersion).Major
    }
    catch {
        Write-Warning "Could not parse runtime config '$runtimeConfigPath'. Falling back to .NET 8 runtime requirement."
        return 8
    }
}

<#
.SYNOPSIS
    Tests if a specific .NET runtime is installed.
.PARAMETER MajorVersion
    The major version of the .NET runtime to check.
.PARAMETER FrameworkName
    The name of the framework to check (e.g., "Microsoft.NETCore.App" or "Microsoft.AspNetCore.App").
.RETURNS
    $true if the specified runtime is installed, $false otherwise.
#>
function Test-DotnetRuntimeInstalled {
    param(
        [Parameter(Mandatory = $true)]
        [int]$MajorVersion,
        [Parameter(Mandatory = $true)]
        [string]$FrameworkName
    )

    $dotnetCmd = Get-Command dotnet -ErrorAction SilentlyContinue # Check if the dotnet command is available. If it is not, we cannot check for installed runtimes, so we return false and let the installer attempt to install the runtime, which will also handle the case where dotnet is not currently installed.
    if (-not $dotnetCmd) {
        return $false
    }

    $versionPattern = "^$([regex]::Escape($FrameworkName))\s+$MajorVersion\."   # We check for the presence of the required .NET runtime by looking for entries in the output of "dotnet --list-runtimes" that match both the framework name and the major version. This allows us to verify that the correct runtime is installed before attempting to start the service, which can help prevent runtime-related startup failures.
    $runtimes = dotnet --list-runtimes 2>$null
    return @($runtimes | Where-Object { $_ -match $versionPattern }).Count -gt 0
}

<#
.SYNOPSIS
    Installs the specified .NET runtime using winget.
.PARAMETER MajorVersion
    The major version of the .NET runtime to install.
.RETURNS
    $true if the installation was successful, $false otherwise.
.EXAMPLE
    $success = Install-DotnetRuntimeWithWinget -MajorVersion 8
    Installs the .NET runtime version 8 using winget.
#>
function Install-DotnetRuntimeWithWinget {
    param(
        [Parameter(Mandatory = $true)]
        [int]$MajorVersion
    )

    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue # Check if winget is available. If it is not, we cannot perform the installation, so we return false and let the installer prompt the user to install the runtime manually, which will also allow them to choose an alternative installation method if they do not have winget.
    if (-not $wingetCmd) {
        return $false
    }
    # We attempt to install both the .NET runtime and the ASP.NET Core runtime for the required major version, as KJITweb depends on both. The package IDs are based on the naming convention used by the official Microsoft packages in winget, but they may need to be adjusted if the package names change in the future. We use the --silent flag to perform a silent installation, and we accept all agreements to allow for an unattended installation experience.
    $packageIds = @(
        "Microsoft.DotNet.Runtime.$MajorVersion",
        "Microsoft.DotNet.AspNetCore.$MajorVersion"
    )
    # We loop through the required package IDs and attempt to install each one using winget. If any installation fails, we log a warning and return false to indicate that the installation was not fully successful, which will prompt the user to perform a manual installation of the runtime.
    foreach ($packageId in $packageIds) {
        Write-Host "Installing runtime package via winget: $packageId"
        winget install --id $packageId -e --silent --accept-package-agreements --accept-source-agreements | Out-Null # We check the exit code of the winget command to determine if the installation was successful. If it was not, we log a warning with the package ID and the exit code, and we return false to indicate that the installation was not fully successful.
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "winget installation failed for $packageId (exit code: $LASTEXITCODE)."
            return $false
        }
    }

    return $true
}

<#
.SYNOPSIS
    Ensures that the required .NET runtime is installed.
.PARAMETER BinaryPath
    The path to the binary that requires the .NET runtime.
#>
function Test-RequiredDotnetRuntime {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BinaryPath
    )

    $requiredMajor = Get-RequiredDotnetMajorVersion -BinaryPath $BinaryPath # Determine the required .NET major version based on the binary's runtime configuration. This allows the installer to automatically handle different runtime requirements for different versions of KJITweb, and ensures that we check for the correct runtime before attempting to start the service.
    $netCoreInstalled = Test-DotnetRuntimeInstalled -MajorVersion $requiredMajor -FrameworkName "Microsoft.NETCore.App" # We check for both the .NET runtime and the ASP.NET Core runtime, as KJITweb depends on both. If either one is missing, we will attempt to install them automatically.
    $aspNetInstalled = Test-DotnetRuntimeInstalled -MajorVersion $requiredMajor -FrameworkName "Microsoft.AspNetCore.App" # If both runtimes are installed, we can proceed with the installation. If either one is missing, we will attempt to install them automatically using winget, and then verify that the installation was successful before proceeding.

    if ($netCoreInstalled -and $aspNetInstalled) {
        Write-Host ".NET runtime prerequisites are installed (major: $requiredMajor)."
        return
    }
    # If we are missing the required runtime, we attempt to install it automatically using winget. This provides a smoother installation experience for users who may not have the runtime installed, and helps ensure that the service can start successfully after installation. If the automatic installation fails (for example, if winget is not available), we log an error and prompt the user to install the runtime manually, which allows them to choose their preferred installation method.
    Write-Host "Missing required .NET runtime (major: $requiredMajor). Starting automatic installation..."
    $installOk = Install-DotnetRuntimeWithWinget -MajorVersion $requiredMajor # After attempting the installation, we check again to verify that the required runtimes are now installed. If they are still missing, we log an error and prompt the user to perform a manual installation, which may be necessary if the automatic installation failed or if there are other issues preventing the runtime from being installed correctly.
    if (-not $installOk) {
        Write-Error "Automatic runtime installation failed. Install .NET Runtime and ASP.NET Core Runtime (major $requiredMajor) manually and retry."
        exit 1
    }

    $netCoreInstalled = Test-DotnetRuntimeInstalled -MajorVersion $requiredMajor -FrameworkName "Microsoft.NETCore.App" # After the installation attempt, we check again to verify that both the .NET runtime and the ASP.NET Core runtime are now installed. This is important to ensure that we have the correct runtime environment for KJITweb before we proceed with starting the service, which can help prevent runtime-related startup failures and provide a better user experience.
    $aspNetInstalled = Test-DotnetRuntimeInstalled -MajorVersion $requiredMajor -FrameworkName "Microsoft.AspNetCore.App" # If either runtime is still missing after the installation attempt, we log an error and prompt the user to perform a manual installation, which may be necessary if the automatic installation failed or if there are other issues preventing the runtime from being installed correctly. This ensures that we do not proceed with an incomplete installation that would lead to service startup failures, and provides clear guidance to the user on how to resolve the issue.
    if (-not ($netCoreInstalled -and $aspNetInstalled)) {
        Write-Error "Runtime installation finished but required runtimes are still missing. Please reboot and retry, or install manually."
        exit 1
    }

    Write-Host ".NET runtime installation successful."
}

<#
.SYNOPSIS
    Configures a Windows Firewall rule to allow inbound TCP traffic on a specified port from specified remote addresses.
.PARAMETER RuleName
    The display name of the firewall rule to create or update.
.PARAMETER RemoteAddresses
    An array of remote IP addresses or hostnames that are allowed to connect. Use "Any" to allow all remote addresses.
.PARAMETER Port
    The local port number that the firewall rule applies to.
.DESCRIPTION
    This function creates or updates a Windows Firewall rule to allow inbound TCP traffic on the specified port from the specified remote addresses. If a rule with the same name already exists, it will be removed and recreated with the new settings. For localhost-only mode (where remote addresses are limited to loopback
    addresses), the function will skip creating a firewall rule, as the service binding will already prevent remote access. This helps to avoid unnecessary firewall rules and potential confusion for users who are running in a secure, localhost-only configuration.
#>
function Set-ClientAccessFirewallRule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RuleName,
        [Parameter(Mandatory = $true)]
        [string[]]$RemoteAddresses,
        [Parameter(Mandatory = $true)]
        [int]$Port
    )
    # First, we remove any existing firewall rule with the same name to ensure that we do not have conflicting rules. This allows us to update the allowed remote addresses and port if the installer is run multiple times with different settings, without leaving behind old rules that could cause confusion or security issues.
    Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue |
        Remove-NetFirewallRule -ErrorAction SilentlyContinue | Out-Null

    # For localhost-only mode, service binding already prevents remote access.
    $addresses = @($RemoteAddresses | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $isLoopbackOnly = ($addresses.Count -gt 0) -and (($addresses | Where-Object { $_ -notin @("127.0.0.1", "::1") }).Count -eq 0)
    if ($isLoopbackOnly) {
        Write-Host "Skipping firewall rule for localhost-only mode."
        return
    }
    # For non-localhost modes, we create a firewall rule to allow inbound access on the specified port from the specified remote addresses. This is necessary to allow remote clients to connect to the KJITweb service when it is configured to allow remote access. By specifying the allowed remote addresses, we can help to secure the service by restricting access to known clients, while still allowing the necessary connectivity for JIT administration.
    New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port -RemoteAddress $addresses -Profile Any | Out-Null
}

<#
.SYNOPSIS
    Writes installer-resolved values into appsettings.json in the installed service folder.
.PARAMETER AppSettingsPath
    Full path to appsettings.json that should be updated.
.PARAMETER JitConfigPath
    Resolved path to JIT.config used by the service.
.PARAMETER AllowedClient
    Allowed client identifier entered during installation.
.PARAMETER ServiceUrl
    Service URL binding resolved from AllowedClient.
.PARAMETER DebugLogPath
    Optional debug log path override. If empty, existing appsettings value is kept.
#>
function Update-AppSettingsForInstall {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppSettingsPath,
        [Parameter(Mandatory = $true)]
        [string]$JitConfigPath,
        [Parameter(Mandatory = $true)]
        [string]$AllowedClient,
        [Parameter(Mandatory = $true)]
        [string]$ServiceUrl,
        [Parameter(Mandatory = $false)]
        [string]$DebugLogPath
    )

    if (-not (Test-Path -Path $AppSettingsPath -PathType Leaf)) {
        Write-Warning "appsettings.json not found at '$AppSettingsPath'. Skipping appsettings update."
        return
    }

    try {
        $appSettings = Get-Content -Path $AppSettingsPath -Raw | ConvertFrom-Json

        if ($null -eq $appSettings.ActiveDirectory) {
            $appSettings | Add-Member -MemberType NoteProperty -Name "ActiveDirectory" -Value ([PSCustomObject]@{}) -Force
        }
        $appSettings.ActiveDirectory | Add-Member -MemberType NoteProperty -Name "JitConfigPath" -Value $JitConfigPath -Force

        $allowedHosts = Get-AllowedHostsFromAllowedClient -Client $AllowedClient
        $appSettings | Add-Member -MemberType NoteProperty -Name "AllowedHosts" -Value $allowedHosts -Force

        if ($null -eq $appSettings.KjitWebInstall) {
            $appSettings | Add-Member -MemberType NoteProperty -Name "KjitWebInstall" -Value ([PSCustomObject]@{}) -Force
        }
        $appSettings.KjitWebInstall | Add-Member -MemberType NoteProperty -Name "AllowedClient" -Value $AllowedClient -Force
        $appSettings.KjitWebInstall | Add-Member -MemberType NoteProperty -Name "ServiceUrl" -Value $ServiceUrl -Force

        if (-not [string]::IsNullOrWhiteSpace($DebugLogPath)) {
            if ($null -eq $appSettings.DebugLog) {
                $appSettings | Add-Member -MemberType NoteProperty -Name "DebugLog" -Value ([PSCustomObject]@{}) -Force
            }
            $appSettings.DebugLog | Add-Member -MemberType NoteProperty -Name "Path" -Value $DebugLogPath -Force
        }

        $appSettings | ConvertTo-Json -Depth 20 | Set-Content -Path $AppSettingsPath -Encoding UTF8
        Write-Host "Updated $(Split-Path -Path $AppSettingsPath -Leaf) with installer values."
    }
    catch {
        Write-Warning "Could not update appsettings.json at '$AppSettingsPath': $($_.Exception.Message)"
    }
}
#endregion

##############################################################################################################
# Main script logic starts here
##############################################################################################################
Write-Host "Starting KJITweb service installation..." -ForegroundColor Green
Write-Host "script version $_scriptVersion"
$defaultJitConfig = Get-DefaultJitConfigPath # Determine the default JIT.config path based on the current domain. This allows for a convenient default configuration location that can be used in domain environments, while still allowing for flexibility if the user wants to specify a different location for the JIT.config file.
if ([string]::IsNullOrWhiteSpace($JitConfig)) {
    Write-Host "JITConfig was not provided."

    while ($true) {
        # We prompt the user to provide the path to the JIT.config file, showing the default path as a reference. If the user presses Enter without providing a path, we will use the default path. We then check if the specified file exists, and if it does, we proceed with that path. If it does not exist, we show a warning and prompt again. This loop continues until we get a valid file path, which ensures that we have a valid JIT.config file to work with for the service configuration.
        $inputJitConfig = Read-Host "JITConfig [$defaultJitConfig]"
        $candidateJitConfig = if ([string]::IsNullOrWhiteSpace($inputJitConfig)) {
            $defaultJitConfig
        }
        else {
            $inputJitConfig.Trim()
        }
        # We check if the candidate JIT.config file exists at the specified path. If it does, we set $JitConfig to that path and break out of the loop to continue with the installation. If it does not exist, we show a warning message and prompt the user again. This ensures that we do not proceed with an invalid JIT.config path, which is critical for the correct operation of the KJITweb service.
        if (Test-Path -Path $candidateJitConfig -PathType Leaf) {
            $JitConfig = $candidateJitConfig
            break
        }
        Write-Warning "JITConfig file not found: $candidateJitConfig"
    }
}

Write-Host "Using JITConfig: $JitConfig"

$defaultAllowedClient = "localhost"
if ([string]::IsNullOrWhiteSpace($AllowedClient)) {
    # We prompt the user to provide the allowed client host/IP, showing the default value as a reference. If the user presses Enter without providing a value, we will use the default value. This allows for a convenient default configuration while still allowing flexibility if the user wants to specify a different allowed client.
    $inputAllowedClient = Read-Host "Allowed client host/IP [$defaultAllowedClient]"
    $AllowedClient = if ([string]::IsNullOrWhiteSpace($inputAllowedClient)) { $defaultAllowedClient } else { $inputAllowedClient.Trim() }
}
else {
    $AllowedClient = $AllowedClient.Trim()
}

$allowedRemoteAddresses = Resolve-AllowedClientAddresses -Client $AllowedClient # Resolve the allowed client to specific remote addresses. This allows us to configure the service binding and firewall rules correctly based on the user's input, whether they specify a hostname, an IP address, or a wildcard. By resolving the hostname to IP addresses, we can ensure that the firewall rules are configured with the correct remote addresses to allow access to the service while maintaining security.
$ServiceUrl = Get-ServiceUrlFromAllowedClient -Client $AllowedClient # Determine the service URL binding based on the allowed client. If the allowed client is localhost-only, we bind to http://localhost:5240. If the allowed client allows remote access, we bind to http://*:5240 to allow connections from any remote address. This ensures that the service is configured with the correct URL binding based on the user's desired access level, and helps to prevent misconfiguration that could lead to connectivity issues or security vulnerabilities.
Write-Host "Allowed client: $AllowedClient"
Write-Host "Allowed remote address(es): $($allowedRemoteAddresses -join ', ')"
Write-Host "Service URL binding: $ServiceUrl"
Write-Host "Debug log path: $DebugLogPath"


$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue # Check if a service with the same name already exists. If it does, we will stop and remove it before proceeding with the installation of the new service. This allows us to handle upgrades or reconfigurations of the service without leaving behind old service instances that could cause confusion or conflicts.
if ($existing) {
    Write-Host "Stopping existing service..."
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    sc.exe delete $ServiceName | Out-Null # We use sc.exe to delete the service because it provides a more reliable way to remove the service entry from the SCM database, especially in cases where the service may be in a failed state or when there are issues with the service control manager. After issuing the delete command, we wait for the service to be fully removed before proceeding with the installation of the new service, which helps to prevent conflicts and ensure a clean installation.

    Write-Host "Waiting for service to be fully removed..."
    $waited = 0
    # We wait for up to 30 seconds for the service to be fully removed from the SCM database. This is important because if we attempt to create a new service with the same name before the old service is fully removed, we may encounter errors or conflicts. By waiting and checking for the existence of the service, we can ensure that we have a clean slate before proceeding with the installation of the new service. If after 30 seconds the service still exists, we log an error and prompt the user to close Services.msc or reboot, as these actions can sometimes cause locks on the service entry that prevent it from being removed.
    while ((Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) -and $waited -lt 30) {
        Start-Sleep -Seconds 1
        $waited++
    }
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        Write-Error "Service '$ServiceName' could not be removed after 30 seconds. Close Services.msc or reboot and retry."
        exit 1
    }
}

Write-Host "Copying service files to $InstallRoot ..."
Copy-ServiceFiles -SourceServiceFolder $SourceServiceFolder -TargetServiceFolder $InstallServiceFolder

$installedAppSettingsPath = Join-Path $InstallServiceFolder "appsettings.json"
Update-AppSettingsForInstall -AppSettingsPath $installedAppSettingsPath -JitConfigPath $JitConfig -AllowedClient $AllowedClient -ServiceUrl $ServiceUrl -DebugLogPath $DebugLogPath

$installedProductionAppSettingsPath = Join-Path $InstallServiceFolder "appsettings.Production.json"
Update-AppSettingsForInstall -AppSettingsPath $installedProductionAppSettingsPath -JitConfigPath $JitConfig -AllowedClient $AllowedClient -ServiceUrl $ServiceUrl -DebugLogPath $DebugLogPath

if (-not (Test-Path $BinaryPath)) { Write-Error "Binary not found: $BinaryPath"; exit 1 }
Write-Host "Checking .NET runtime prerequisites for $BinaryPath ..."
Test-RequiredDotnetRuntime -BinaryPath $BinaryPath

Write-Host "Creating service..."
New-Service -Name $ServiceName -BinaryPathName $BinaryPath -DisplayName $DisplayName -Description $Description -StartupType Automatic
Write-Host "Configuring service account: NetworkService"
sc.exe config $ServiceName obj= "NT AUTHORITY\NetworkService" password= "" | Out-Null

# On reboot, a short delayed start reduces race conditions with other startup workloads.
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName" -Name DelayedAutoStart -Value 1 -Type DWord

# If startup fails (for example transient port contention), let SCM retry automatically.
sc.exe failure $ServiceName reset= 86400 actions= restart/10000/restart/30000/restart/60000 | Out-Null
sc.exe failureflag $ServiceName 1 | Out-Null

$envRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName"

$envValues = @(
    "ASPNETCORE_ENVIRONMENT=Production",
    "ASPNETCORE_URLS=$ServiceUrl",
    "JustInTimeConfig=$JitConfig"
)

# Only set DebugLog__Path if explicitly provided; otherwise let appsettings.json control it
if (-not [string]::IsNullOrWhiteSpace($DebugLogPath)) {
    $resolvedDebugLogPath = $DebugLogPath.Trim()
    $logDir = Split-Path -Path $resolvedDebugLogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    $envValues += "DebugLog__Path=$resolvedDebugLogPath"
    Write-Host "DebugLog path configured for service (from parameter): $resolvedDebugLogPath"
}
else {
    Write-Host "DebugLog path will be resolved from appsettings.json at runtime."
}

New-ItemProperty -Path $envRegPath -Name "Environment" -PropertyType MultiString -Value $envValues -Force | Out-Null

Write-Host "Configuring firewall rule '$FirewallRuleName' for port 5240 ..."
Set-ClientAccessFirewallRule -RuleName $FirewallRuleName -RemoteAddresses $allowedRemoteAddresses -Port 5240

Write-Host "Ensuring port 5240 is free..."
Stop-ProcessesListeningOnPort -Port 5240

Write-Host "Starting service..."
Start-Service -Name $ServiceName

$status = Get-Service -Name $ServiceName
Write-Host "Status: $($status.Status)"
Write-Host "URL   : http://$($env:COMPUTERNAME).$($env:USERDNSDOMAIN):5240"
if ($status.Status -eq "Running") { Write-Host "Service is running." -ForegroundColor Green }
else {
    Write-Warning "Service did not start. Check: Get-EventLog -LogName Application -Source KjitWeb -Newest 10"
    Write-Host "Port 5240 currently used by:"
    Get-PortProcessIds -Port 5240 | ForEach-Object {
        $p = Get-Process -Id $_ -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host "  $($p.ProcessName) (PID $($_))"
        }
        else {
            Write-Host "  PID $($_)"
        }
    }
}