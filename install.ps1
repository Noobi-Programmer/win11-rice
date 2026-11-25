#requires -Version 5.1
<#
    install.ps1 - Reproducible installer for win11-rice.
    Backs up existing Windows settings, installs open-source stack,
    pins UI apps to iGPU, configures Precision Touchpad gestures,
    deploys scripts/skins/configs, and activates linux mode.
#>
[CmdletBinding()]
param(
    [ValidateSet('linux', 'hybrid', 'studio', 'saver')]
    [string]$InitialMode = 'linux',
    [switch]$SkipWinget
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptsDir = 'C:\Scripts'
$BackupDir = Join-Path $ScriptsDir 'Backup'
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host '=== win11-rice installer ===' -ForegroundColor Cyan

# 1. Back up existing Windows registry & power settings
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$regBackups = @{
    'Explorer_Advanced.reg' = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    'Taskbar_StuckRects3.reg' = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
    'Language_Profile.reg' = 'HKCU\Control Panel\International\User Profile'
}
foreach ($file in $regBackups.Keys) {
    $dest = Join-Path $BackupDir $file
    if (-not (Test-Path -LiteralPath $dest)) {
        & reg.exe export $regBackups[$file] $dest /y 2>$null | Out-Null
    }
}
$powerFile = Join-Path $BackupDir 'Active_PowerScheme.txt'
if (-not (Test-Path -LiteralPath $powerFile)) {
    & powercfg.exe /getactivescheme | Out-File -FilePath $powerFile -Encoding UTF8
}

# 2. Install lightweight open-source stack via winget
if (-not $SkipWinget) {
    $packages = @(
        'Flow-Launcher.Flow-Launcher',
        'voidtools.Everything',
        'rocksdanister.LivelyWallpaper',
        'Rainmeter.Rainmeter',
        'RamenSoftware.Windhawk',
        'DEVCOM.JetBrainsMonoNerdFont'
    )
    foreach ($pkg in $packages) {
        Write-Host "Ensuring $pkg is installed..."
        & winget install -e --id $pkg --accept-source-agreements --accept-package-agreements --silent | Out-Null
    }
}

# 3. Configure Precision Touchpad 3-finger & 4-finger gestures
$tpPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\PrecisionTouchPad'
if (-not (Test-Path -LiteralPath $tpPath)) { New-Item -Path $tpPath -Force | Out-Null }
Set-ItemProperty -Path $tpPath -Name 'ThreeFingerSlideEnabled' -Value 1 -Type DWord
Set-ItemProperty -Path $tpPath -Name 'FourFingerSlideEnabled' -Value 1 -Type DWord

# 4. Pin UI apps to iGPU (GpuPreference=1;) to avoid dGPU wake-ups
$gpuPath = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'
if (-not (Test-Path -LiteralPath $gpuPath)) { New-Item -Path $gpuPath -Force | Out-Null }
foreach ($exe in @(
    'C:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe',
    "$env:LOCALAPPDATA\Programs\Lively Wallpaper\Lively.exe",
    'C:\Program Files\Lively Wallpaper\Lively.exe',
    "$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe",
    'C:\Users\abini\Apps\Rainmeter\Rainmeter.exe',
    'C:\Program Files\Rainmeter\Rainmeter.exe'
)) {
    if (Test-Path -LiteralPath $exe) {
        Set-ItemProperty -Path $gpuPath -Name $exe -Value 'GpuPreference=1;' -Type String
    }
}

# 5. Deploy scripts & Rainmeter skins
Get-ChildItem -Path (Join-Path $RepoRoot 'scripts') -Filter '*.ps1' | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $ScriptsDir $_.Name) -Force
}
$rmDir = Join-Path $env:USERPROFILE 'Documents\Rainmeter\Skins\StudioMinimal'
New-Item -ItemType Directory -Path $rmDir -Force | Out-Null
Copy-Item -Path (Join-Path $RepoRoot 'configs\rainmeter\StudioMinimal\*') -Destination $rmDir -Recurse -Force

# 6. Apply Windhawk settings if elevated
if ($IsAdmin -and (Test-Path (Join-Path $ScriptsDir 'Apply-Windhawk.ps1'))) {
    try { & (Join-Path $ScriptsDir 'Apply-Windhawk.ps1') } catch { Write-Warning $_.Exception.Message }
}

# 7. Create Start Menu Mode shortcuts & Startup HotkeyDaemon
$wsh = New-Object -ComObject WScript.Shell
$modesDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Modes'
New-Item -ItemType Directory -Path $modesDir -Force | Out-Null
foreach ($m in @(
    @{ Name = 'Mode - Linux'; Mode = 'linux' },
    @{ Name = 'Mode - Hybrid'; Mode = 'hybrid' },
    @{ Name = 'Mode - Studio'; Mode = 'studio' },
    @{ Name = 'Mode - Saver'; Mode = 'saver' },
    @{ Name = 'Mode - Reset'; Mode = 'reset' }
)) {
    $sc = $wsh.CreateShortcut((Join-Path $modesDir "$($m.Name).lnk"))
    $sc.TargetPath = 'powershell.exe'
    $sc.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Scripts\Switch-Mode.ps1 -Mode $($m.Mode)"
    $sc.WorkingDirectory = $ScriptsDir
    $sc.WindowStyle = 7
    $sc.Save()
}

$startupDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
$lnkPath = Join-Path $startupDir 'RicingHotkeyDaemon.lnk'
$sc2 = $wsh.CreateShortcut($lnkPath)
$sc2.TargetPath = 'powershell.exe'
$sc2.Arguments = '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Scripts\HotkeyDaemon.ps1'
$sc2.WorkingDirectory = $ScriptsDir
$sc2.WindowStyle = 7
$sc2.Save()

Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $ScriptsDir 'HotkeyDaemon.ps1') -WindowStyle Hidden

# 8. Activate initial mode
& (Join-Path $ScriptsDir 'Switch-Mode.ps1') -Mode $InitialMode
Write-Host "win11-rice installed and switched to $InitialMode mode." -ForegroundColor Cyan
