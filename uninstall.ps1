#requires -Version 5.1
<#
    uninstall.ps1
    Stops ricing processes, removes startup hotkey daemon, and restores pre-rice backups.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -like '*HotkeyDaemon.ps1*' -and $_.ProcessId -ne $PID } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

$startupLnk = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\RicingHotkeyDaemon.lnk'
if (Test-Path -LiteralPath $startupLnk) { Remove-Item -LiteralPath $startupLnk -Force }

$modesDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Modes'
if (Test-Path -LiteralPath $modesDir) { Remove-Item -LiteralPath $modesDir -Recurse -Force }

if (Test-Path -LiteralPath 'C:\Scripts\Reset-Default.ps1') {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'C:\Scripts\Reset-Default.ps1'
}

Write-Host 'win11-rice uninstalled and pre-rice defaults restored.' -ForegroundColor Green
