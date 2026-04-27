#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Deinstalliert den KjitWeb Windows-Dienst.
#>

$ServiceName = "KjitWeb"

$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $existing) {
    Write-Host "Dienst '$ServiceName' ist nicht installiert."
    exit 0
}

Write-Host "Stoppe und entferne Dienst '$ServiceName'..."
Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
sc.exe delete $ServiceName
Write-Host "Deinstallation abgeschlossen."
