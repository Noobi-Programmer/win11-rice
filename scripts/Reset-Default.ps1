#requires -Version 5.1
<#
    Reset-Default.ps1
    Stops custom bars/scripts, restores WiFi/Bluetooth radios, restores taskbar
    visibility and desktop icons, re-imports C:\Scripts\Backup\*.reg, and
    restores Balanced power (100% CPU).
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Scripts = 'C:\Scripts'
$Backup = Join-Path $Scripts 'Backup'
$Log = Join-Path $Scripts 'reset-default.log'

. (Join-Path $Scripts 'DesktopHelpers.ps1')

function Write-Log {
    param([string]$Message)
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Host $line
    Add-Content -Path $Log -Value $line -Encoding UTF8
}

Write-Log 'Beginning restore of pre-rice defaults.'

# 1. Stop custom bars/rice processes (never explorer.exe).
foreach ($name in @('glazewm', 'yasb', 'zebar', 'Rainmeter', 'Lively')) {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Log "Stopped $name ($($procs.Count) process(es))."
    }
}

# 2. Restore WiFi & Bluetooth radios.
$restoreRadios = Join-Path $Scripts 'RestoreRadios.ps1'
if (Test-Path -LiteralPath $restoreRadios) {
    & $restoreRadios
    Write-Log 'Executed RestoreRadios.ps1.'
}

# 3. Restore taskbar visibility, disable auto-hide, and show desktop icons via Win32.
Set-NativeTaskbarAutoHide -Enabled $false
Set-NativeTaskbarVisible -Visible $true
Set-DesktopIconsVisible -Visible $true
Write-Log 'Restored native taskbar visibility, disabled auto-hide, and showed desktop icons.'

# 4. Restore exported registry keys.
$regFiles = Get-ChildItem -LiteralPath $Backup -Filter '*.reg' -File -ErrorAction SilentlyContinue | Sort-Object Name
if (-not $regFiles -or $regFiles.Count -eq 0) {
    throw "No .reg backup files found in $Backup"
}
foreach ($item in $regFiles) {
    & reg.exe import $item.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to import $($item.FullName) (exit code $LASTEXITCODE)."
    }
    Write-Log ("Imported {0}." -f $item.Name)
}

# 5. Restore Balanced power scheme and 100% max CPU state on AC and DC.
& powercfg.exe /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
if ($LASTEXITCODE -ne 0) { throw "Failed to activate Balanced power scheme (exit code $LASTEXITCODE)." }
& powercfg.exe /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100 | Out-Null
& powercfg.exe /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 100
if ($LASTEXITCODE -ne 0) { throw "Failed to set DC PROCTHROTTLEMAX to 100 (exit code $LASTEXITCODE)." }
& powercfg.exe /setactive SCHEME_CURRENT | Out-Null
Write-Log 'Restored Balanced scheme and AC/DC CPU cap of 100%.'

# 6. Re-apply Win32 visibility & icon broadcast cleanly.
Set-NativeTaskbarVisible -Visible $true
Set-DesktopIconsVisible -Visible $true
Write-Log 'Reset complete.'
