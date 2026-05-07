$ErrorActionPreference = 'Continue'
Import-Module .\src\Powershell\modules\Just-In-time.psd1 -Force

# Test 1: Default config (no parameter)
try {
    $cfg1 = Get-JITconfig
    "[SUCCESS] Test 1 (default): returned type $($cfg1.GetType().FullName)"
    "  EventLog: $($cfg1.EventLog), EventSource: $($cfg1.EventSource), ElevateEventID: $($cfg1.ElevateEventID)"
}
catch {
    "[ERROR] Test 1 (default): $($_.Exception.Message)"
}

# Test 2: Explicit JSON file
$testConfigPath = ".\release\kjibweb\publish-service\app_data\JIT.test.config"
if (Test-Path $testConfigPath) {
    try {
        $cfg2 = Get-JITconfig -configurationFile $testConfigPath
        "[SUCCESS] Test 2 (JSON file): returned type $($cfg2.GetType().FullName)"
        "  EventLog: $($cfg2.EventLog), EventSource: $($cfg2.EventSource), ElevateEventID: $($cfg2.ElevateEventID)"
    }
    catch {
        "[ERROR] Test 2 (JSON file): $($_.Exception.Message)"
    }
}
else {
    "[SKIPPED] Test 2 (JSON file not found at $testConfigPath)"
}

"-- Loaded KjitCore assembly --"
[AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GetName().Name -eq 'KjitCore' } |
    ForEach-Object {
        "$($_.GetName().Name) | $($_.GetName().Version) | $($_.Location)"
    }
