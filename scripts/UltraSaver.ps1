#requires -Version 5.1
<#
    UltraSaver.ps1
    Offline cinema battery-saver mode:
    - Turns OFF WiFi and Bluetooth radios via WinRT
    - Stops non-essential background/rice/AI/sync/launcher processes
    - Hides native taskbar & desktop icons (without killing explorer.exe)
    - Activates Power Saver + caps DC CPU state to 50%
    - Triggers Lenovo Legion Toolkit HyperSaver quickAction if available
    - Launches PotPlayerMini64.exe for local playback
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Scripts = 'C:\Scripts'
$Log = Join-Path $Scripts 'ultrasaver.log'
$ModeFile = Join-Path $Scripts 'current_mode.txt'
$PowerSaver = 'a1841308-3541-4fab-bc81-f71556f20b4a'

. (Join-Path $Scripts 'DesktopHelpers.ps1')

function Write-Log {
    param([string]$Message)
    $line = '{0} [UltraSaver] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Host $line
    Add-Content -Path $Log -Value $line -Encoding UTF8
}

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null = [Windows.Devices.Radios.Radio, Windows.System.Devices, ContentType = WindowsRuntime]

function Invoke-WinRtAsync {
    param(
        [Parameter(Mandatory = $true)]$AsyncOp,
        [Parameter(Mandatory = $true)][Type]$ResultType
    )
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and
        $_.IsGenericMethod -and
        $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
    })[0]
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($AsyncOp))
    $netTask.Wait(-1) | Out-Null
    return $netTask.Result
}

Write-Log 'Activating UltraSaver offline cinema mode...'

# 1. Turn OFF WiFi and Bluetooth radios via WinRT.
try {
    $access = Invoke-WinRtAsync -AsyncOp ([Windows.Devices.Radios.Radio]::RequestAccessAsync()) -ResultType ([Windows.Devices.Radios.RadioAccessStatus])
    if ($access -eq [Windows.Devices.Radios.RadioAccessStatus]::Allowed) {
        $radios = Invoke-WinRtAsync -AsyncOp ([Windows.Devices.Radios.Radio]::GetRadiosAsync()) -ResultType ([System.Collections.Generic.IReadOnlyList[Windows.Devices.Radios.Radio]])
        foreach ($radio in $radios) {
            if ($radio.Kind -in @([Windows.Devices.Radios.RadioKind]::WiFi, [Windows.Devices.Radios.RadioKind]::Bluetooth)) {
                if ($radio.State -ne [Windows.Devices.Radios.RadioState]::Off) {
                    $null = Invoke-WinRtAsync -AsyncOp ($radio.SetStateAsync([Windows.Devices.Radios.RadioState]::Off)) -ResultType ([Windows.Devices.Radios.RadioAccessStatus])
                    Write-Log "Radio $($radio.Kind) ($($radio.Name)) -> Off"
                }
            }
        }
    }
}
catch {
    Write-Log "WARNING: WinRT radio toggle failed: $($_.Exception.Message)"
}

# 2. Terminate non-essential background/rice/AI/sync/launcher processes (never explorer.exe, LenovoLegionToolkit.exe, or audio).
$killList = @(
    'glazewm', 'yasb', 'zebar', 'Rainmeter', 'Lively', 'Sucrose',
    'Flow.Launcher', 'Everything', 'Discord', 'Steam', 'steamwebhelper',
    'Docker Desktop', 'com.docker.backend', 'ollama', 'ollama app',
    'OneDrive', 'msedge', 'Widgets', 'WidgetService', 'PhoneExperienceHost'
)
foreach ($procName in $killList) {
    $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Log "Stopped $procName ($($procs.Count))."
    }
}

# 3. Hide native taskbar and desktop icons cleanly.
Set-NativeTaskbarAutoHide -Enabled $false
Set-NativeTaskbarVisible -Visible $false
Set-DesktopIconsVisible -Visible $false
Write-Log 'Taskbar and desktop icons hidden.'

# 4. Activate Windows Power Saver and cap battery PROCTHROTTLEMAX DC = 50.
& powercfg.exe /setactive $PowerSaver 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    $dup = & powercfg.exe /duplicatescheme $PowerSaver 2>&1
    if ($LASTEXITCODE -eq 0 -and $dup -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
        & powercfg.exe /setactive $Matches[1] 2>&1 | Out-Null
    }
}
& powercfg.exe /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 50 2>&1 | Out-Null
& powercfg.exe /setactive SCHEME_CURRENT 2>&1 | Out-Null
Write-Log 'Power Saver active (DC PROCTHROTTLEMAX = 50%).'

# 5. Trigger Lenovo Legion Toolkit HyperSaver quickAction if llt.exe is available.
$llt = Get-Command 'llt.exe' -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
if (-not $llt -and (Test-Path 'C:\Program Files\Lenovo Legion Toolkit\llt.exe')) {
    $llt = 'C:\Program Files\Lenovo Legion Toolkit\llt.exe'
}
if ($llt) {
    & $llt quickAction "HyperSaver" 2>&1 | Out-Null
    Write-Log 'Triggered llt.exe quickAction "HyperSaver".'
}

# 6. Launch PotPlayerMini64.exe if not already running.
$potPlayer = 'C:\Program Files\DAUM\PotPlayer\PotPlayerMini64.exe'
if (Test-Path -LiteralPath $potPlayer) {
    if (-not (Get-Process -Name 'PotPlayerMini64' -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath $potPlayer | Out-Null
        Write-Log 'Launched PotPlayerMini64.exe.'
    }
}

Set-Content -Path $ModeFile -Value 'saver' -Encoding ASCII -NoNewline
Write-Log 'UltraSaver mode active.'
