#requires -Version 5.1
<#
    Apply-Windhawk.ps1
    Applies DockLike floating taskbar styler, translucent start menu, and
    translucent notification center settings in Windhawk's registry store.
    Must be run from an elevated (Administrator) PowerShell prompt.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run Apply-Windhawk.ps1 as Administrator so HKLM:\SOFTWARE\Windhawk\Engine\Mods can be updated.'
}

$modsRoot = 'HKLM:\SOFTWARE\Windhawk\Engine\Mods'

# 1. Windows 11 Taskbar Styler (DockLike floating dock)
$tbSettings = Join-Path $modsRoot 'windows-11-taskbar-styler\Settings'
if (Test-Path -LiteralPath (Join-Path $modsRoot 'windows-11-taskbar-styler')) {
    Set-ItemProperty -Path (Join-Path $modsRoot 'windows-11-taskbar-styler') -Name 'Disabled' -Value 0 -Type DWord
    if (-not (Test-Path -LiteralPath $tbSettings)) { New-Item -Path $tbSettings -Force | Out-Null }
    Set-ItemProperty -Path $tbSettings -Name 'theme' -Value 'DockLike' -Type String
    Set-ItemProperty -Path $tbSettings -Name 'controlStyles[0].target' -Value 'Taskbar.TaskbarFrame#TaskbarFrame' -Type String
    Set-ItemProperty -Path $tbSettings -Name 'controlStyles[0].styles[0]' -Value 'CornerRadius=12' -Type String
    Set-ItemProperty -Path $tbSettings -Name 'controlStyles[0].styles[1]' -Value 'Margin=0,0,0,6' -Type String
    Set-ItemProperty -Path $tbSettings -Name 'controlStyles[0].styles[2]' -Value 'Background:=#CC11111B' -Type String
    Set-ItemProperty -Path $tbSettings -Name 'controlStyles[0].styles[3]' -Value 'BorderBrush:=#22FFFFFF' -Type String
    Set-ItemProperty -Path $tbSettings -Name 'controlStyles[0].styles[4]' -Value 'BorderThickness=1' -Type String
    Write-Host 'Configured windows-11-taskbar-styler (DockLike).'
}
else {
    Write-Warning 'Install "Windows 11 Taskbar Styler" in Windhawk UI first, then re-run this script.'
}

# 2. Windows 11 Start Menu Styler
$smSettings = Join-Path $modsRoot 'windows-11-start-menu-styler\Settings'
if (Test-Path -LiteralPath (Join-Path $modsRoot 'windows-11-start-menu-styler')) {
    Set-ItemProperty -Path (Join-Path $modsRoot 'windows-11-start-menu-styler') -Name 'Disabled' -Value 0 -Type DWord
    if (-not (Test-Path -LiteralPath $smSettings)) { New-Item -Path $smSettings -Force | Out-Null }
    Set-ItemProperty -Path $smSettings -Name 'theme' -Value 'TranslucentStartMenu' -Type String
    Write-Host 'Configured windows-11-start-menu-styler (TranslucentStartMenu).'
}

# 3. Windows 11 Notification Center Styler
$ncSettings = Join-Path $modsRoot 'windows-11-notification-center-styler\Settings'
if (Test-Path -LiteralPath (Join-Path $modsRoot 'windows-11-notification-center-styler')) {
    Set-ItemProperty -Path (Join-Path $modsRoot 'windows-11-notification-center-styler') -Name 'Disabled' -Value 0 -Type DWord
    if (-not (Test-Path -LiteralPath $ncSettings)) { New-Item -Path $ncSettings -Force | Out-Null }
    Set-ItemProperty -Path $ncSettings -Name 'theme' -Value 'Translucent' -Type String
    Write-Host 'Configured windows-11-notification-center-styler (Translucent).'
}
else {
    Write-Warning 'Install "Windows 11 Notification Center Styler" in Windhawk UI first, then re-run this script.'
}
