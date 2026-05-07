$ErrorActionPreference = 'Continue'

# Test the module from release folder
$moduleSource = ".\release\modules\Just-In-time.psd1"
if (-not (Test-Path $moduleSource)) {
    "[ERROR] Module not found at $moduleSource"
    exit 1
}

Import-Module $moduleSource -Force

try {
    $cfg = Get-JITconfig
    "[SUCCESS] Get-JITconfig from RELEASE module returned: $($cfg.GetType().FullName)"
    "  EventLog: $($cfg.EventLog), EventSource: $($cfg.EventSource), ElevateEventID: $($cfg.ElevateEventID)"
}
catch {
    "[ERROR] Get-JITconfig failed: $($_.Exception.Message)"
}

# Check loaded DLL location
"-- Loaded KjitCore assembly --"
[AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GetName().Name -eq 'KjitCore' } |
    ForEach-Object {
        "Location: $($_.Location)"
    }
