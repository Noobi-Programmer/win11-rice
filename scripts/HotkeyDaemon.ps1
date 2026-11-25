#requires -Version 5.1
<#
    HotkeyDaemon.ps1 - Hidden background listener for Alt+Shift+0..4 mode hotkeys.
    Ensures mode switching works even when GlazeWM is stopped (e.g., studio mode)
    without colliding with Lenovo Ctrl+Alt+[num] brightness shortcuts.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Scripts = 'C:\Scripts'
$Log = Join-Path $Scripts 'hotkey-daemon.log'

function Write-Log {
    param([string]$Message)
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -Path $Log -Value $line -Encoding UTF8
}

$mutex = New-Object System.Threading.Mutex($true, 'Local\RicingHotkeyDaemonV2')
if (-not $mutex.WaitOne(0, $false)) {
    Write-Log 'Another Alt+Shift hotkey daemon is already running; exiting.'
    exit 0
}

if (-not ('RicingHotkeyNative' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class RicingHotkeyNative
{
    [StructLayout(LayoutKind.Sequential)]
    public struct MSG
    {
        public IntPtr hwnd;
        public uint message;
        public IntPtr wParam;
        public IntPtr lParam;
        public uint time;
        public int pt_x;
        public int pt_y;
    }

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool UnregisterHotKey(IntPtr hWnd, int id);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern int GetMessageW(out MSG lpMsg, IntPtr hWnd, uint wMsgFilterMin, uint wMsgFilterMax);

    [DllImport("user32.dll")]
    public static extern bool TranslateMessage(ref MSG lpMsg);

    [DllImport("user32.dll")]
    public static extern IntPtr DispatchMessage(ref MSG lpMsg);
}
'@
}

$MOD_ALT = 0x0001
$MOD_SHIFT = 0x0004
$MOD_NOREPEAT = 0x4000
$WM_HOTKEY = 0x0312

$bindings = @(
    @{ Id = 1; Key = 0x31; Mode = 'linux' },   # Alt+Shift+1
    @{ Id = 2; Key = 0x32; Mode = 'hybrid' },  # Alt+Shift+2
    @{ Id = 3; Key = 0x33; Mode = 'studio' },  # Alt+Shift+3
    @{ Id = 4; Key = 0x34; Mode = 'saver' },   # Alt+Shift+4
    @{ Id = 5; Key = 0x30; Mode = 'reset' }    # Alt+Shift+0
)

$registered = @()
foreach ($b in $bindings) {
    $ok = [RicingHotkeyNative]::RegisterHotKey(
        [IntPtr]::Zero,
        $b.Id,
        [uint32]($MOD_ALT -bor $MOD_SHIFT -bor $MOD_NOREPEAT),
        [uint32]$b.Key
    )
    if ($ok) {
        $registered += $b.Id
        Write-Log ("Registered Alt+Shift+{0} -> {1}" -f ($b.Key - 0x30), $b.Mode)
    }
    else {
        Write-Log ("FAILED to register Alt+Shift+{0} (Win32 error {1})" -f ($b.Key - 0x30), [Runtime.InteropServices.Marshal]::GetLastWin32Error())
    }
}

if ($registered.Count -eq 0) {
    Write-Log 'No hotkeys registered; daemon exiting.'
    $mutex.ReleaseMutex() | Out-Null
    exit 1
}

Write-Log 'Alt+Shift Hotkey daemon listening.'
try {
    while ($true) {
        $msg = New-Object RicingHotkeyNative+MSG
        $result = [RicingHotkeyNative]::GetMessageW([ref]$msg, [IntPtr]::Zero, 0, 0)
        if ($result -le 0) { break }
        if ($msg.message -eq $WM_HOTKEY) {
            $choice = $bindings | Where-Object { $_.Id -eq $msg.wParam.ToInt32() } | Select-Object -First 1
            if ($choice) {
                Write-Log ("Hotkey fired: {0}" -f $choice.Mode)
                Start-Process -FilePath 'powershell.exe' -ArgumentList @(
                    '-NoProfile', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass',
                    '-File', (Join-Path $Scripts 'Switch-Mode.ps1'), '-Mode', $choice.Mode
                ) -WindowStyle Hidden | Out-Null
            }
        }
        [void][RicingHotkeyNative]::TranslateMessage([ref]$msg)
        [void][RicingHotkeyNative]::DispatchMessage([ref]$msg)
    }
}
finally {
    foreach ($id in $registered) {
        [void][RicingHotkeyNative]::UnregisterHotKey([IntPtr]::Zero, $id)
    }
    Write-Log 'Hotkey daemon stopped.'
    $mutex.ReleaseMutex() | Out-Null
}
