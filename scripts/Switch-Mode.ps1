#requires -Version 5.1
<#
    Switch-Mode.ps1 - Unified 4-mode & visual-style switcher.
    Modes: linux | hybrid | studio | saver | reset
    BarStyles: yasb | dock | both
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('linux', 'hybrid', 'studio', 'saver', 'reset')]
    [string]$Mode,

    [Parameter(Mandatory = $false)]
    [ValidateSet('yasb', 'dock', 'both')]
    [string]$BarStyle
)

$ErrorActionPreference = 'Stop'
$Scripts = 'C:\Scripts'
$Log = Join-Path $Scripts 'switch-mode.log'
$ModeFile = Join-Path $Scripts 'current_mode.txt'
$Balanced = '381b4222-f694-41f0-9685-ff5bb260df2e'
$PowerSaver = 'a1841308-3541-4fab-bc81-f71556f20b4a'

. (Join-Path $Scripts 'DesktopHelpers.ps1')

$PreferredApps = @{
    'glazewm'   = 'C:\Program Files\glzr.io\GlazeWM\glazewm.exe'
    'yasb'      = 'C:\Program Files\YASB\yasb.exe'
    'Rainmeter' = 'C:\Users\abini\Apps\Rainmeter\Rainmeter.exe'
}

function Write-Log {
    param([string]$Message)
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Mode, $Message
    Write-Host $line
    Add-Content -Path $Log -Value $line -Encoding UTF8
}

function Find-AppPath {
    param([Parameter(Mandatory = $true)][string[]]$Names)
    foreach ($name in $Names) {
        if ($PreferredApps.ContainsKey($name) -and (Test-Path -LiteralPath $PreferredApps[$name])) {
            return $PreferredApps[$name]
        }
        $cmd = Get-Command -Name $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd -and $cmd.Source) { return $cmd.Source }
    }
    return $null
}

function Start-ManagedApp {
    param([Parameter(Mandatory = $true)][string[]]$Names)
    $exe = Find-AppPath -Names $Names
    $base = [IO.Path]::GetFileNameWithoutExtension($Names[0])
    if (-not $exe) {
        Write-Log "WARNING: could not locate $($Names[0]); skipping start."
        return
    }
    if (Get-Process -Name $base -ErrorAction SilentlyContinue) {
        Write-Log "$base already running."
        return
    }
    try {
        if ($base -eq 'glazewm') {
            Start-Process -FilePath $exe -ArgumentList 'start' -WindowStyle Hidden -ErrorAction Stop
        }
        else {
            Start-Process -FilePath $exe -WindowStyle Hidden -ErrorAction Stop
        }
        Write-Log "Started $base ($exe)."
    }
    catch {
        Write-Log "WARNING: failed to start $base : $($_.Exception.Message)"
    }
}

function Stop-ManagedApp {
    param([Parameter(Mandatory = $true)][string]$ProcessName)
    $procs = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Log "Stopped $ProcessName."
    }
}

function Stop-GlazeWM {
    $procs = Get-Process -Name glazewm -ErrorAction SilentlyContinue
    if (-not $procs) {
        Write-Log 'GlazeWM already stopped.'
        return
    }
    $exe = Find-AppPath -Names @('glazewm')
    if ($exe) {
        & $exe command wm-exit 2>$null | Out-Null
        Start-Sleep -Milliseconds 500
    }
    $procs = Get-Process -Name glazewm -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Log 'GlazeWM stopped (force).'
    }
    else {
        Write-Log 'GlazeWM stopped cleanly.'
    }
}

function Set-BarStyle {
    param([Parameter(Mandatory = $true)][string]$Style)
    Set-CleanTaskbarElements
    switch ($Style) {
        'yasb' {
            Start-ManagedApp -Names @('yasb')
            Set-NativeTaskbarAutoHide -Enabled $false
            Set-NativeTaskbarVisible -Visible $false
            Write-Log 'BarStyle=yasb (YASB top bar ON, native bottom taskbar hidden).'
        }
        'dock' {
            Stop-ManagedApp -ProcessName 'yasb'
            Set-NativeTaskbarVisible -Visible $true
            Set-NativeTaskbarAutoHide -Enabled $true
            Write-Log 'BarStyle=dock (YASB OFF, native hover bottom dock ON).'
        }
        'both' {
            Start-ManagedApp -Names @('yasb')
            Set-NativeTaskbarVisible -Visible $true
            Set-NativeTaskbarAutoHide -Enabled $true
            Write-Log 'BarStyle=both (YASB top bar ON + native hover bottom dock ON).'
        }
    }
}

function Set-RainmeterState {
    param([Parameter(Mandatory = $true)][bool]$Active)
    $rmExe = Find-AppPath -Names @('Rainmeter')
    if (-not $rmExe) {
        Write-Log 'Rainmeter not installed; skipping desktop widgets.'
        return
    }
    if ($Active) {
        Start-ManagedApp -Names @('Rainmeter')
        Start-Sleep -Milliseconds 600
        & $rmExe !ActivateConfig "StudioMinimal\AestheticClock" "Clock.ini" 2>$null | Out-Null
        & $rmExe !ActivateConfig "StudioMinimal\MiniPlayer" "Player.ini" 2>$null | Out-Null
        Write-Log 'Rainmeter StudioMinimal widgets activated.'
    }
    else {
        if (Get-Process -Name 'Rainmeter' -ErrorAction SilentlyContinue) {
            & $rmExe !DeactivateConfigGroup "StudioMinimal" 2>$null | Out-Null
            Write-Log 'Rainmeter StudioMinimal widgets paused.'
        }
    }
}

function Invoke-PowerCfg {
    param([string[]]$Arguments)
    & powercfg.exe @Arguments 2>&1 | Out-Null
    return $LASTEXITCODE
}

function Set-BalancedPower {
    param([switch]$HighPerformanceAC)
    if ((Invoke-PowerCfg @('/setactive', $Balanced)) -ne 0) {
        throw 'Failed to activate Balanced power scheme.'
    }
    [void](Invoke-PowerCfg @('/setacvalueindex', 'SCHEME_CURRENT', 'SUB_PROCESSOR', 'PROCTHROTTLEMAX', '100'))
    [void](Invoke-PowerCfg @('/setdcvalueindex', 'SCHEME_CURRENT', 'SUB_PROCESSOR', 'PROCTHROTTLEMAX', '100'))
    & powercfg.exe /setactive SCHEME_CURRENT 2>&1 | Out-Null
    Write-Log ("Balanced power active (100% CPU AC/DC{0})." -f $(if ($HighPerformanceAC) { ', studio AC' } else { '' }))
}

function Set-SaverPower {
    $code = Invoke-PowerCfg @('/setactive', $PowerSaver)
    if ($code -ne 0) {
        $dup = & powercfg.exe /duplicatescheme $PowerSaver 2>&1
        if ($LASTEXITCODE -eq 0 -and $dup -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
            [void](Invoke-PowerCfg @('/setactive', $Matches[1]))
        }
    }
    [void](Invoke-PowerCfg @('/setdcvalueindex', 'SCHEME_CURRENT', 'SUB_PROCESSOR', 'PROCTHROTTLEMAX', '70'))
    & powercfg.exe /setactive SCHEME_CURRENT 2>&1 | Out-Null
    Write-Log 'Power Saver active (DC CPU capped at 70%).'
}

if (-not $PSBoundParameters.ContainsKey('BarStyle') -or -not $BarStyle) {
    $BarStyle = switch ($Mode) {
        'linux'  { 'yasb' }
        'hybrid' { 'dock' }
        'studio' { 'dock' }
        'saver'  { 'yasb' }
        default  { 'dock' }
    }
}

Write-Log "===== mode=$Mode bar=$BarStyle ====="

switch ($Mode) {
    'reset' {
        & (Join-Path $Scripts 'Reset-Default.ps1')
        Set-Content -Path $ModeFile -Value 'reset' -Encoding ASCII -NoNewline
    }
    'linux' {
        Start-ManagedApp -Names @('glazewm')
        Set-BarStyle -Style $BarStyle
        Set-DesktopIconsVisible -Visible $false
        Set-RainmeterState -Active $true
        Set-BalancedPower
        Set-Content -Path $ModeFile -Value 'linux' -Encoding ASCII -NoNewline
    }
    'hybrid' {
        Start-ManagedApp -Names @('glazewm')
        Set-BarStyle -Style $BarStyle
        Set-DesktopIconsVisible -Visible $false
        Set-RainmeterState -Active $true
        Set-BalancedPower
        Set-Content -Path $ModeFile -Value 'hybrid' -Encoding ASCII -NoNewline
    }
    'studio' {
        Stop-GlazeWM
        Set-BarStyle -Style $BarStyle
        Set-DesktopIconsVisible -Visible $false
        Set-BalancedPower -HighPerformanceAC
        Set-Content -Path $ModeFile -Value 'studio' -Encoding ASCII -NoNewline
    }
    'saver' {
        Start-ManagedApp -Names @('glazewm')
        Set-BarStyle -Style $BarStyle
        Set-DesktopIconsVisible -Visible $false
        Set-RainmeterState -Active $false
        Set-SaverPower
        Set-Content -Path $ModeFile -Value 'saver' -Encoding ASCII -NoNewline
    }
}

Write-Log "===== mode $Mode complete ====="
