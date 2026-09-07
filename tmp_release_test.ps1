<#
Script Info

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
#>

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
