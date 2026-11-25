#requires -Version 5.1
<#
    install.ps1 - Reproducible installer for win11-rice.
    Backs up existing Windows settings, installs core tools via winget,
    installs JetBrainsMono Nerd Font, deploys configs/scripts/skins,
    and activates hybrid mode.
#>
[CmdletBinding()]
param(
    [ValidateSet('linux', 'hybrid', 'studio', 'saver')]
    [string]$InitialMode = 'hybrid',
    [switch]$SkipWinget
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptsDir = 'C:\Scripts'
$BackupDir = Join-Path $ScriptsDir 'Backup'
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host '=== win11-rice installer ===' -ForegroundColor Cyan

# 1. Create C:\Scripts and back up existing Windows registry settings
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
        if (Test-Path -LiteralPath $dest) {
            Write-Host "Backed up $file" -ForegroundColor Green
        }
    }
}

# 2. Install core packages via winget
if (-not $SkipWinget) {
    $packages = @(
        'glzr-io.glazewm',
        'AmN.yasb',
        'Flow-Launcher.Flow-Launcher',
        'voidtools.Everything',
        'RamenSoftware.Windhawk',
        'Rainmeter.Rainmeter'
    )
    foreach ($pkg in $packages) {
        Write-Host "Ensuring $pkg is installed..."
        & winget install -e --id $pkg --accept-source-agreements --accept-package-agreements --silent | Out-Null
    }
}

# 3. Ensure JetBrainsMono Nerd Font is installed system-wide
$fontInstalled = (Get-ChildItem 'C:\Windows\Fonts' -Filter 'JetBrainsMono*NerdFont*.ttf' -ErrorAction SilentlyContinue).Count -gt 0
if (-not $fontInstalled) {
    $zipPath = Join-Path $env:TEMP 'JetBrainsMono.zip'
    $extractPath = Join-Path $env:TEMP 'JetBrainsMonoNF'
    Write-Host 'Downloading JetBrainsMono Nerd Font...'
    Invoke-WebRequest -Uri 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip' -OutFile $zipPath -UseBasicParsing
    if (Test-Path -LiteralPath $extractPath) { Remove-Item $extractPath -Recurse -Force }
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    $ttfFiles = Get-ChildItem -Path $extractPath -Filter '*.ttf' -Recurse
    if ($IsAdmin) {
        $regFonts = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        foreach ($ttf in $ttfFiles) {
            Copy-Item -LiteralPath $ttf.FullName -Destination (Join-Path 'C:\Windows\Fonts' $ttf.Name) -Force
            $fontName = ($ttf.BaseName -replace '-', ' ') + ' (TrueType)'
            Set-ItemProperty -Path $regFonts -Name $fontName -Value $ttf.Name -Type String
        }
        Write-Host "Registered $($ttfFiles.Count) font files system-wide." -ForegroundColor Green
    }
    else {
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.Namespace(0x14)
        foreach ($ttf in $ttfFiles) {
            $fontsFolder.CopyHere($ttf.FullName, 0x14)
        }
        Write-Warning 'Installed fonts via Shell; run as Administrator to ensure HKLM system-wide registration for Qt/YASB.'
    }
}

# 4. Deploy scripts to C:\Scripts
Get-ChildItem -Path (Join-Path $RepoRoot 'scripts') -Filter '*.ps1' | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $ScriptsDir $_.Name) -Force
}
Write-Host 'Deployed scripts to C:\Scripts.' -ForegroundColor Green

# 5. Deploy GlazeWM, YASB, and Rainmeter configs
$glazeDir = Join-Path $env:USERPROFILE '.glzr\glazewm'
$yasbDir = Join-Path $env:USERPROFILE '.config\yasb'
$rmDir = Join-Path $env:USERPROFILE 'Documents\Rainmeter\Skins\StudioMinimal'

New-Item -ItemType Directory -Path $glazeDir, $yasbDir, $rmDir -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $RepoRoot 'configs\glazewm\config.yaml') -Destination (Join-Path $glazeDir 'config.yaml') -Force
Copy-Item -LiteralPath (Join-Path $RepoRoot 'configs\yasb\config.yaml') -Destination (Join-Path $yasbDir 'config.yaml') -Force
Copy-Item -LiteralPath (Join-Path $RepoRoot 'configs\yasb\styles.css') -Destination (Join-Path $yasbDir 'styles.css') -Force
Copy-Item -Path (Join-Path $RepoRoot 'configs\rainmeter\StudioMinimal\*') -Destination $rmDir -Recurse -Force
Write-Host 'Deployed GlazeWM, YASB, and Rainmeter configurations.' -ForegroundColor Green

# 6. Apply Windhawk settings if elevated
if ($IsAdmin) {
    try {
        & (Join-Path $ScriptsDir 'Apply-Windhawk.ps1')
    }
    catch {
        Write-Warning "Windhawk config skipped: $($_.Exception.Message)"
    }
}
else {
    Write-Warning 'Not running as Administrator; run C:\Scripts\Apply-Windhawk.ps1 elevated after installing Windhawk mods.'
}

# 7. Register Alt+Shift+0..4 hotkey daemon shortcut in Startup and launch it
$startupDir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Startup'
$lnkPath = Join-Path $startupDir 'RicingHotkeyDaemon.lnk'
$wsh = New-Object -ComObject WScript.Shell
$sc = $wsh.CreateShortcut($lnkPath)
$sc.TargetPath = 'powershell.exe'
$sc.Arguments = '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Scripts\HotkeyDaemon.ps1'
$sc.WorkingDirectory = $ScriptsDir
$sc.WindowStyle = 7
$sc.Save()

Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $ScriptsDir 'HotkeyDaemon.ps1') -WindowStyle Hidden

# 8. Activate initial mode
& (Join-Path $ScriptsDir 'Switch-Mode.ps1') -Mode $InitialMode
Write-Host "win11-rice installed and switched to $InitialMode mode." -ForegroundColor Cyan
