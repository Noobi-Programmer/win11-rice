#requires -Version 5.1
<#
    install.ps1
    Reproducible installer for win11-rice.
    Backs up existing Windows settings, installs required tools via winget,
    deploys configs/skins/scripts, and activates linux mode.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptsDir = 'C:\Scripts'
$BackupDir = Join-Path $ScriptsDir 'Backup'

Write-Host '==> [1/5] Backing up existing Windows settings...' -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $ScriptsDir, $BackupDir | Out-Null

$regBackups = @{
    'Explorer_Advanced.reg'   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    'Taskbar_StuckRects3.reg' = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
    'Language_Profile.reg'    = 'HKCU\Software\Microsoft\CTF\LangBar'
}
foreach ($entry in $regBackups.GetEnumerator()) {
    $out = Join-Path $BackupDir $entry.Key
    if (-not (Test-Path -LiteralPath $out)) {
        & reg.exe export $entry.Value $out /y | Out-Null
    }
}

Write-Host '==> [2/5] Installing packages via winget...' -ForegroundColor Cyan
$packages = @(
    'glzr-io.glazewm',
    'AmN.yasb',
    'Flow-Launcher.Flow-Launcher',
    'voidtools.Everything',
    'RamenSoftware.Windhawk',
    'Rainmeter.Rainmeter',
    'DEVCOM.JetBrainsMonoNerdFont'
)
foreach ($id in $packages) {
    Write-Host "Installing $id..."
    & winget install -e --id $id --accept-source-agreements --accept-package-agreements --silent | Out-Null
}

Write-Host '==> [3/5] Deploying scripts & Start Menu shortcuts...' -ForegroundColor Cyan
Copy-Item -Path (Join-Path $RepoRoot 'scripts\*') -Destination $ScriptsDir -Force -Recurse

$startupDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
$modesDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Modes'
New-Item -ItemType Directory -Force -Path $startupDir, $modesDir | Out-Null

$wsh = New-Object -ComObject WScript.Shell
$daemonLnk = $wsh.CreateShortcut((Join-Path $startupDir 'RicingHotkeyDaemon.lnk'))
$daemonLnk.TargetPath = 'powershell.exe'
$daemonLnk.Arguments = '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Scripts\HotkeyDaemon.ps1'
$daemonLnk.WindowStyle = 7
$daemonLnk.Save()

foreach ($m in @(
    @{ Name = 'Mode - Linux';        Arg = 'linux' },
    @{ Name = 'Mode - Hybrid';       Arg = 'hybrid' },
    @{ Name = 'Mode - Studio';       Arg = 'studio' },
    @{ Name = 'Mode - HyperSaver';   Arg = 'saver' },
    @{ Name = 'Mode - Reset Default'; Arg = 'reset' }
)) {
    $lnk = $wsh.CreateShortcut((Join-Path $modesDir "$($m.Name).lnk"))
    $lnk.TargetPath = 'powershell.exe'
    $lnk.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Scripts\Switch-Mode.ps1 -Mode $($m.Arg)"
    $lnk.WindowStyle = 7
    $lnk.Save()
}

Write-Host '==> [4/5] Deploying YASB, GlazeWM, and Rainmeter configs...' -ForegroundColor Cyan
$yasbDir = Join-Path $env:USERPROFILE '.config\yasb'
$glazeDir = Join-Path $env:USERPROFILE '.glzr\glazewm'
$rmSkinsDir = Join-Path $env:USERPROFILE 'Documents\Rainmeter\Skins\StudioMinimal'
New-Item -ItemType Directory -Force -Path $yasbDir, $glazeDir, $rmSkinsDir | Out-Null

Copy-Item -Path (Join-Path $RepoRoot 'configs\yasb\*') -Destination $yasbDir -Force
Copy-Item -Path (Join-Path $RepoRoot 'configs\glazewm\config.yaml') -Destination (Join-Path $glazeDir 'config.yaml') -Force
Copy-Item -Path (Join-Path $RepoRoot 'configs\rainmeter\StudioMinimal\*') -Destination $rmSkinsDir -Force -Recurse

Write-Host '==> [5/5] Starting HotkeyDaemon and applying linux mode...' -ForegroundColor Cyan
Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass', '-File', 'C:\Scripts\HotkeyDaemon.ps1') -WindowStyle Hidden
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $ScriptsDir 'Switch-Mode.ps1') -Mode linux
Write-Host 'win11-rice installation complete!' -ForegroundColor Green
