#requires -Version 5.1
<#
    DesktopHelpers.ps1
    Native Win32 P/Invoke helpers for instant taskbar, desktop icon, and shell control
    without restarting explorer.exe.
#>

if (-not ('Win32DesktopHelpers' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class Win32DesktopHelpers
{
    public const int SW_HIDE = 0;
    public const int SW_SHOW = 5;

    public const uint ABM_GETSTATE = 0x00000004;
    public const uint ABM_SETSTATE = 0x0000000A;
    public const int ABS_AUTOHIDE = 0x0000001;
    public const int ABS_ALWAYSONTOP = 0x0000002;

    public static readonly IntPtr HWND_BROADCAST = new IntPtr(0xffff);
    public const uint WM_SETTINGCHANGE = 0x001A;
    public const uint SMTO_ABORTIFHUNG = 0x0002;

    public const uint SHCNE_ASSOCCHANGED = 0x08000000;
    public const uint SHCNF_IDLIST = 0x0000;

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT
    {
        public int left;
        public int top;
        public int right;
        public int bottom;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct APPBARDATA
    {
        public uint cbSize;
        public IntPtr hWnd;
        public uint uCallbackMessage;
        public uint uEdge;
        public RECT rc;
        public IntPtr lParam;
    }

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr FindWindowEx(IntPtr parentHandle, IntPtr childAfter, string lclassName, string windowTitle);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint Msg,
        UIntPtr wParam,
        string lParam,
        uint fuFlags,
        uint uTimeout,
        out UIntPtr lpdwResult);

    [DllImport("shell32.dll", SetLastError = true)]
    public static extern UIntPtr SHAppBarMessage(uint dwMessage, ref APPBARDATA pData);

    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
'@
}

function Set-NativeTaskbarAutoHide {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    $hwnd = [Win32DesktopHelpers]::FindWindow('Shell_TrayWnd', $null)
    $abd = New-Object Win32DesktopHelpers+APPBARDATA
    $abd.cbSize = [uint32][System.Runtime.InteropServices.Marshal]::SizeOf([type][Win32DesktopHelpers+APPBARDATA])
    $abd.hWnd = $hwnd
    $abd.lParam = [IntPtr]$(if ($Enabled) { [Win32DesktopHelpers]::ABS_AUTOHIDE } else { [Win32DesktopHelpers]::ABS_ALWAYSONTOP })

    [void][Win32DesktopHelpers]::SHAppBarMessage([Win32DesktopHelpers]::ABM_SETSTATE, [ref]$abd)
}

function Set-NativeTaskbarVisible {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Visible
    )

    $cmd = if ($Visible) { [Win32DesktopHelpers]::SW_SHOW } else { [Win32DesktopHelpers]::SW_HIDE }

    $primary = [Win32DesktopHelpers]::FindWindow('Shell_TrayWnd', $null)
    if ($primary -ne [IntPtr]::Zero) {
        [void][Win32DesktopHelpers]::ShowWindow($primary, $cmd)
    }

    $secondary = [IntPtr]::Zero
    while ($true) {
        $secondary = [Win32DesktopHelpers]::FindWindowEx([IntPtr]::Zero, $secondary, 'Shell_SecondaryTrayWnd', $null)
        if ($secondary -eq [IntPtr]::Zero) { break }
        [void][Win32DesktopHelpers]::ShowWindow($secondary, $cmd)
    }
}

function Set-DesktopIconsVisible {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Visible
    )

    $advPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $hideVal = if ($Visible) { 0 } else { 1 }
    Set-ItemProperty -Path $advPath -Name 'HideIcons' -Value $hideVal -Type DWord

    $result = [UIntPtr]::Zero
    [void][Win32DesktopHelpers]::SendMessageTimeout(
        [Win32DesktopHelpers]::HWND_BROADCAST,
        [Win32DesktopHelpers]::WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        'ShellState',
        [Win32DesktopHelpers]::SMTO_ABORTIFHUNG,
        1000,
        [ref]$result
    )
    [void][Win32DesktopHelpers]::SendMessageTimeout(
        [Win32DesktopHelpers]::HWND_BROADCAST,
        [Win32DesktopHelpers]::WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        'Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced',
        [Win32DesktopHelpers]::SMTO_ABORTIFHUNG,
        1000,
        [ref]$result
    )
    [Win32DesktopHelpers]::SHChangeNotify(
        [Win32DesktopHelpers]::SHCNE_ASSOCCHANGED,
        [Win32DesktopHelpers]::SHCNF_IDLIST,
        [IntPtr]::Zero,
        [IntPtr]::Zero
    )
}

function Set-CleanTaskbarElements {
    [CmdletBinding()]
    param()

    $advPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $searchPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
    $langPath = 'HKCU:\Software\Microsoft\CTF\LangBar'

    if (-not (Test-Path -LiteralPath $searchPath)) {
        New-Item -Path $searchPath -Force | Out-Null
    }
    Set-ItemProperty -Path $searchPath -Name 'SearchboxTaskbarMode' -Value 0 -Type DWord -ErrorAction SilentlyContinue

    foreach ($prop in @('ShowTaskViewButton', 'TaskbarDa', 'ShowCopilotButton')) {
        try {
            Set-ItemProperty -Path $advPath -Name $prop -Value 0 -Type DWord -ErrorAction Stop
        }
        catch {
            # TaskbarDa may be protected on some builds; ignore if already 0 or restricted
        }
    }

    try {
        $cmd = Get-Command Set-WinLanguageBarOption -ErrorAction SilentlyContinue
        if ($cmd) {
            if ($cmd.Parameters.ContainsKey('HideLanguageBar')) {
                Set-WinLanguageBarOption -UseLegacyLanguageBar -HideLanguageBar -ErrorAction SilentlyContinue
            }
            else {
                Set-WinLanguageBarOption -UseLegacyLanguageBar -ErrorAction SilentlyContinue
            }
        }
    }
    catch {}

    if (-not (Test-Path -LiteralPath $langPath)) {
        New-Item -Path $langPath -Force | Out-Null
    }
    Set-ItemProperty -Path $langPath -Name 'ShowStatus' -Value 3 -Type DWord -ErrorAction SilentlyContinue
}

function Set-CleanSystemUI {
    [CmdletBinding()]
    param()
    Set-CleanTaskbarElements
}

function Optimize-ActiveWindowFullscreen {
    [CmdletBinding()]
    param()

    if (-not ('Win32WindowFocus' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class Win32WindowFocus
{
    public const int SW_MAXIMIZE = 3;

    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsZoomed(IntPtr hWnd);
}
'@
    }

    $fg = [Win32WindowFocus]::GetForegroundWindow()
    if ($fg -ne [IntPtr]::Zero -and -not [Win32WindowFocus]::IsZoomed($fg)) {
        [void][Win32WindowFocus]::ShowWindow($fg, [Win32WindowFocus]::SW_MAXIMIZE)
    }
}
