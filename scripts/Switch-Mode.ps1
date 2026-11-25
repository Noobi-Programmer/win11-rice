#requires -Version 5.1
<#
    Switch-Mode.ps1 - Unified 4-mode switcher for Windows 11 Virtual Desktops.
    Modes: linux | hybrid | studio | saver | reset
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('linux', 'hybrid', 'studio', 'saver', 'reset')]
    [string]$Mode
)

$ErrorActionPreference = 'Stop'
$Scripts = 'C:\Scripts'
$Log = Join-Path $Scripts 'switch-mode.log'
$ModeFile = Join-Path $Scripts 'current_mode.txt'
$Balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'

. (Join-Path $Scripts 'DesktopHelpers.ps1')

function Write-Log {
    param([string]$Message)
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Mode, $Message
    Write-Host $line
    Add-Content -Path $Log -Value $line -Encoding UTF8
}

function Find-App {
    param([string[]]$Candidates)
    foreach ($c in $Candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    return $null
}

function Ensure-AppRunning {
    param(
        [Parameter(Mandatory = $true)][string]$ProcessName,
        [Parameter(Mandatory = $true)][string[]]$Candidates
    )
    if (Get-Process -Name $ProcessName -ErrorAction SilentlyContinue) {
        return
    }
    $exe = Find-App -Candidates $Candidates
    if ($exe) {
        Start-Process -FilePath $exe -WindowStyle Hidden | Out-Null
        Write-Log "Started $ProcessName ($exe)."
    }
    else {
        Write-Log "WARNING: $ProcessName not found."
    }
}

function Set-LivelyPaused {
    param([bool]$Paused)
    $livelyCu = Find-App -Candidates @(
        "$env:LOCALAPPDATA\Programs\Lively Wallpaper\livelycu.exe",
        'C:\Program Files\Lively Wallpaper\livelycu.exe'
    )
    if ($livelyCu) {
        $val = if ($Paused) { 'true' } else { 'false' }
        & $livelyCu setprops --pause $val 2>&1 | Out-Null
        Write-Log "Lively Wallpaper paused=$val."
    }
}

function Set-RainmeterActive {
    $rmExe = Find-App -Candidates @(
        'C:\Users\abini\Apps\Rainmeter\Rainmeter.exe',
        'C:\Program Files\Rainmeter\Rainmeter.exe'
    )
    if (-not $rmExe) { return }
    Ensure-AppRunning -ProcessName 'Rainmeter' -Candidates @($rmExe)
    Start-Sleep -Milliseconds 400
    & $rmExe !ActivateConfig "StudioMinimal\AestheticClock" "Clock.ini" 2>$null | Out-Null
    & $rmExe !ActivateConfig "StudioMinimal\MiniPlayer" "Player.ini" 2>$null | Out-Null
    Write-Log 'Rainmeter StudioMinimal widgets activated.'
}

function Set-Balanced100 {
    & powercfg.exe /setactive $Balanced 2>&1 | Out-Null
    & powercfg.exe /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 2>&1 | Out-Null
    & powercfg.exe /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 2>&1 | Out-Null
    & powercfg.exe /setactive SCHEME_CURRENT 2>&1 | Out-Null
    Write-Log 'Balanced power active (100% CPU AC/DC).'
}

function Start-CoreStack {
    Ensure-AppRunning -ProcessName 'Everything' -Candidates @('C:\Program Files\Everything\Everything.exe')
    Ensure-AppRunning -ProcessName 'Flow.Launcher' -Candidates @("$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe")
    Set-RainmeterActive
}

Write-Log "===== Switching to mode: $Mode ====="
Set-CleanSystemUI

switch ($Mode) {
    'linux' {
        & (Join-Path $Scripts 'RestoreRadios.ps1')
        Start-CoreStack
        Ensure-AppRunning -ProcessName 'Lively' -Candidates @(
            "$env:LOCALAPPDATA\Programs\Lively Wallpaper\Lively.exe",
            'C:\Program Files\Lively Wallpaper\Lively.exe'
        )
        Set-LivelyPaused -Paused $false
        Set-NativeTaskbarAutoHide -Enabled $false
        Set-NativeTaskbarVisible -Visible $false
        Set-DesktopIconsVisible -Visible $false
        Set-Balanced100
        Set-Content -Path $ModeFile -Value 'linux' -Encoding ASCII -NoNewline
    }
    'hybrid' {
        & (Join-Path $Scripts 'RestoreRadios.ps1')
        Start-CoreStack
        Set-NativeTaskbarVisible -Visible $true
        Set-NativeTaskbarAutoHide -Enabled $true
        Set-DesktopIconsVisible -Visible $false
        Set-Balanced100
        Set-Content -Path $ModeFile -Value 'hybrid' -Encoding ASCII -NoNewline
    }
    'studio' {
        & (Join-Path $Scripts 'RestoreRadios.ps1')
        Set-LivelyPaused -Paused $true
        Set-NativeTaskbarVisible -Visible $true
        Set-NativeTaskbarAutoHide -Enabled $true
        Set-DesktopIconsVisible -Visible $false
        Set-Balanced100
        Set-Content -Path $ModeFile -Value 'studio' -Encoding ASCII -NoNewline
    }
    'saver' {
        & (Join-Path $Scripts 'UltraSaver.ps1')
    }
    'reset' {
        & (Join-Path $Scripts 'Reset-Default.ps1')
        Set-Content -Path $ModeFile -Value 'reset' -Encoding ASCII -NoNewline
    }
}

Write-Log "===== Mode $Mode active ====="
