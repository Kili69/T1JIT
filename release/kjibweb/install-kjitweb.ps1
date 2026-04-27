#Requires -RunAsAdministrator
param(
    [string]$DebugLogPath,
    [string]$JitConfig,
    [string]$BinaryPath,
    [string]$AllowedClient
)

$ServiceName  = "KjitWeb"
$DisplayName  = "KjitWeb Just-In-Time Admin Access"
$Description  = "Browser-based Tier-1 JIT elevation with Kerberos authentication."
$InstallRoot = Join-Path $env:ProgramFiles "KJITWEB"
$SourceRoot = $PSScriptRoot
$SourceServiceFolder = Join-Path $SourceRoot "publish-service"
$InstallServiceFolder = $InstallRoot 
$FirewallRuleName = "KjitWeb Port 5240 Client Restriction"
$BinaryPath   = if ([string]::IsNullOrWhiteSpace($BinaryPath)) {
    Join-Path $InstallServiceFolder "KjitWeb.exe"
}
else {
    $BinaryPath.Trim()
}
$ServiceUrl   = $null

function Copy-ServiceFiles {
    param(
        [string]$SourceServiceFolder,
        [string]$TargetServiceFolder
    )

    if (-not (Test-Path -Path $SourceServiceFolder -PathType Container)) {
        Write-Error "Source service folder not found: $SourceServiceFolder"
        exit 1
    }

    if (Test-Path -Path $TargetServiceFolder) {
        Remove-Item -Path $TargetServiceFolder -Recurse -Force
    }

    New-Item -Path $TargetServiceFolder -ItemType Directory -Force | Out-Null
    Copy-Item -Path (Join-Path $SourceServiceFolder "*") -Destination $TargetServiceFolder -Recurse -Force
}

function Get-CurrentDomainName {
    try {
        return [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain().Name
    }
    catch {
        if (-not [string]::IsNullOrWhiteSpace($env:USERDNSDOMAIN)) {
            return $env:USERDNSDOMAIN
        }

        if (-not [string]::IsNullOrWhiteSpace($env:USERDOMAIN)) {
            return $env:USERDOMAIN
        }

        Write-Error "Could not determine the current domain automatically. Please provide -JitConfig explicitly."
        exit 1
    }
}

function Get-DefaultJitConfigPath {
    $currentDomain = Get-CurrentDomainName
    return "\\$currentDomain\SYSVOL\$currentDomain\Just-In-Time\JIT.config"
}

function Resolve-DebugLogPath {
    param(
        [string]$OverridePath,
        [string]$ConfigDirectory
    )

    if (-not [string]::IsNullOrWhiteSpace($OverridePath)) {
        return $OverridePath
    }

    $configPath = Join-Path $ConfigDirectory "appsettings.json"
    if (-not (Test-Path $configPath)) {
        return $null
    }

    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        if ($null -ne $config.DebugLog -and -not [string]::IsNullOrWhiteSpace($config.DebugLog.Path)) {
            return [string]$config.DebugLog.Path
        }
    }
    catch {
        Write-Warning "Could not parse $configPath to resolve DebugLog path: $($_.Exception.Message)"
    }

    return $null
}

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

function Stop-ProcessesListeningOnPort {
    param([int]$Port)

    $pids = Get-PortProcessIds -Port $Port
    foreach ($processId in $pids) {
        try {
            $process = Get-Process -Id $processId -ErrorAction Stop
            Write-Host "Stopping process on port ${Port}: $($process.ProcessName) (PID $processId)"
            Stop-Process -Id $processId -Force -ErrorAction Stop
        }
        catch {
            Write-Warning "Could not stop PID $processId on port ${Port}: $($_.Exception.Message)"
        }
    }
}

function Resolve-AllowedClientAddresses {
    param([string]$Client)

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

function Get-ServiceUrlFromAllowedClient {
    param([string]$Client)

    if ([string]::IsNullOrWhiteSpace($Client) -or $Client.Trim() -ieq "localhost") {
        return "http://localhost:5240"
    }

    return "http://*:5240"
}

function Set-ClientAccessFirewallRule {
    param(
        [string]$RuleName,
        [string[]]$RemoteAddresses,
        [int]$Port
    )

    Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue |
        Remove-NetFirewallRule -ErrorAction SilentlyContinue | Out-Null

    New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Port -RemoteAddress ($RemoteAddresses -join ",") -Profile Any | Out-Null
}

$defaultJitConfig = Get-DefaultJitConfigPath
if ([string]::IsNullOrWhiteSpace($JitConfig)) {
    Write-Host "JITConfig was not provided."

    while ($true) {
        $inputJitConfig = Read-Host "JITConfig [$defaultJitConfig]"
        $candidateJitConfig = if ([string]::IsNullOrWhiteSpace($inputJitConfig)) {
            $defaultJitConfig
        }
        else {
            $inputJitConfig.Trim()
        }

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
    $inputAllowedClient = Read-Host "Allowed client host/IP [$defaultAllowedClient]"
    $AllowedClient = if ([string]::IsNullOrWhiteSpace($inputAllowedClient)) { $defaultAllowedClient } else { $inputAllowedClient.Trim() }
}
else {
    $AllowedClient = $AllowedClient.Trim()
}

$allowedRemoteAddresses = Resolve-AllowedClientAddresses -Client $AllowedClient
$ServiceUrl = Get-ServiceUrlFromAllowedClient -Client $AllowedClient

Write-Host "Allowed client: $AllowedClient"
Write-Host "Allowed remote address(es): $($allowedRemoteAddresses -join ', ')"
Write-Host "Service URL binding: $ServiceUrl"

$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Stopping existing service..."
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    sc.exe delete $ServiceName | Out-Null

    Write-Host "Waiting for service to be fully removed..."
    $waited = 0
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

if (-not (Test-Path $BinaryPath)) { Write-Error "Binary not found: $BinaryPath"; exit 1 }

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

# Default: NetworkService APPDATA so logs land in the service account profile
$networkServiceAppData = "C:\Windows\ServiceProfiles\NetworkService\AppData\Roaming"
$resolvedDebugLogPath = if (-not [string]::IsNullOrWhiteSpace($DebugLogPath)) {
    $DebugLogPath.Trim()
} else {
    Join-Path $networkServiceAppData "KjitWeb\kjitweb.log"
}

$logDir = Split-Path -Path $resolvedDebugLogPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

$envValues = @(
    "ASPNETCORE_ENVIRONMENT=Production",
    "ASPNETCORE_URLS=$ServiceUrl",
    "JustInTimeConfig=$JitConfig",
    "DebugLog__Path=$resolvedDebugLogPath"
)

Write-Host "DebugLog path configured for service: $resolvedDebugLogPath"

New-ItemProperty -Path $envRegPath -Name "Environment" -PropertyType MultiString -Value $envValues -Force | Out-Null

Write-Host "Configuring firewall rule '$FirewallRuleName' for port 5240 ..."
Set-ClientAccessFirewallRule -RuleName $FirewallRuleName -RemoteAddresses $allowedRemoteAddresses -Port 5240

Write-Host "Ensuring port 5240 is free..."
Stop-ProcessesListeningOnPort -Port 5240

Write-Host "Starting service..."
Start-Service -Name $ServiceName

$status = Get-Service -Name $ServiceName
Write-Host "Status: $($status.Status)"
Write-Host "URL   : http://$($env:COMPUTERNAME).bloedgelaber.de:5240"
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