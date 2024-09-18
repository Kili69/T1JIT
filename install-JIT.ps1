<#
Script Info

Author: Andreas Lucas [MSFT]
Download: https://github.com/Kili69/T1JIT

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
    Installation of just in time solution
.DESCRIPTION
    This script install the Just-IN-Time Solution. The purpose of this script is to copy scripts into
    program files folder,the modules into the modules and start the configuration script
Version 0.1.20240918
    Inital Version
#>

$JitProgramFolder = $env:ProgramFiles +"\Just-In-Time"

Write-Host "Welcome the the Just-In-Time administration programm installation"
$TargetDir = Read-Host "Installation Directory ($JitProgramFolder)"
if ($TargetDir -eq ""){
    $TargetDir = $JitProgramFolder
}
try {
    if (!(Test-Path -Path $TargetDir)) {
        New-Item -Path $TargetDir -ItemType Directory -ErrorAction Stop
    }
    #copy program files
    Copy-Item .\Config-JIT.ps1 $TargetDir -ErrorAction Stop
    Copy-Item .\Config-JITUI.ps1 $TargetDir -ErrorAction Stop
    Copy-Item .\DelegationConfig.ps1 $TargetDir -ErrorAction Stop
    Copy-Item .\ElevateUser.ps1 $TargetDir -ErrorAction Stop
    Copy-Item .\RequestAdminAccessUI.ps1 $TargetDir -ErrorAction Stop
    Copy-Item .\Tier1LocalAdminGroup.ps1 $TargetDir -ErrorAction Stop
    New-Item "$($env:ProgramFiles)\WindowsPowerShell\Modules\Just-In-Time" -ItemType Directory -ErrorAction Stop
    Copy-Item .\modules\* -Destination "$($env:ProgramFiles)\WindowsPowerShell\Modules\Just-In-time" -Recurse -ErrorAction Stop -Force
    Write-Host "Start configuratin with $TargetDir\config-JIT.ps1"
    
} 
catch [System.UnauthorizedAccessException] {
    Write-Host "A access denied error occured" -ForegroundColor Red
    Write-Host "Run the installation as administrator"
}
catch{
    Write-Host "A unexpected error is occured" -ForegroundColor Red
    $Error[0] 
}