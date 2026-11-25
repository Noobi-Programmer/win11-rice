#requires -Version 5.1
<#
    uninstall.ps1 - Cleanly reverts win11-rice and restores backed-up Windows settings.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ScriptsDir = 'C:\Scripts'
$ResetScript = Join-Path $ScriptsDir 'Reset-Default.ps1'

Write-Host '=== win11-rice uninstaller ===' -ForegroundColor Cyan

Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'HotkeyDaemon\.ps1' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

$lnkPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup\RicingHotkeyDaemon.lnk'
if (Test-Path -LiteralPath $lnkPath) {
    Remove-Item -LiteralPath $lnkPath -Force
}

if (Test-Path -LiteralPath $ResetScript) {
    & $ResetScript
}
else {
    Write-Warning "Reset script not found at $ResetScript."
}

Write-Host 'win11-rice uninstalled and Windows defaults restored.' -ForegroundColor Green
