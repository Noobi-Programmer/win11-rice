# win11-rice

An ultra-lightweight, hyper-efficient Windows 11 desktop rice, 4-mode power/UI switcher, and offline **UltraSaver** cinema mode built on native Windows Virtual Desktops, Precision Touchpad gestures, **Flow Launcher**, **Everything**, **Lively Wallpaper**, **Rainmeter**, and **Windhawk**.

## Architecture

```text
  ┌─────────────────────────────────────────────────────────────────────┐
  │                   Alt + Shift + 0..4 / Flow Launcher                │
  └──────────┬──────────────┬──────────────┬──────────────┬─────────────┘
             ▼              ▼              ▼              ▼
      [1] LINUX        [2] HYBRID     [3] STUDIO     [4] SAVER
   Pure Fullscreen   Hover Dock +     AC Creative/   Offline Cinema
   Workspaces        Workspaces       Gaming         (UltraSaver)
   • Taskbar: OFF    • Dock: Auto     • Dock: Auto   • WiFi/BT: OFF
   • Icons: OFF      • Icons: OFF     • Lively: Paused• Rainmeter/Lively: OFF
   • Lively: ON      • Rainmeter: ON  • dGPU: Auto   • CPU DC Cap: 50%
   • CPU: 100%       • CPU: 100%      • CPU: 100%    • PotPlayer + LLT HyperSaver
```

## Touchpad Gestures & Hotkeys

| Input | Action |
| :--- | :--- |
| **3-Finger Swipe Left / Right** | Switch Windows Virtual Desktops |
| **4-Finger Swipe Up / Down** | Multitasking / Task View overview |
| `Alt + Space` | Open **Flow Launcher** (with **Everything** file search) |
| `Alt + Shift + 1` | **Linux** mode (edge-to-edge fullscreen workspaces, no taskbar) |
| `Alt + Shift + 2` | **Hybrid** mode (workspaces + Windhawk floating hover dock) |
| `Alt + Shift + 3` | **Studio** mode (pauses Lively, frees GPU/VRAM for Resolve/Blender/gaming) |
| `Alt + Shift + 4` | **Saver** mode (offline UltraSaver cinema: WiFi/BT off, 50% DC CPU, PotPlayer) |
| `Alt + Shift + 0` | **Reset** to stock Windows 11 defaults (restores `.reg` backups & radios) |

## One-Line Install

Run in **PowerShell** (run as Administrator for system-wide `JetBrainsMono` Nerd Font registration and Windhawk `HKLM` settings):

```powershell
git clone https://github.com/Noobi-Programmer/win11-rice.git "$env:USERPROFILE\win11-rice" ; & "$env:USERPROFILE\win11-rice\install.ps1"
```

To revert all changes and restore your backed-up Windows settings:

```powershell
& "$env:USERPROFILE\win11-rice\uninstall.ps1"
```

## Repository Layout

```text
win11-rice/
├── install.ps1
├── uninstall.ps1
├── README.md
├── configs/
│   ├── rainmeter/StudioMinimal/
│   │   ├── AestheticClock/Clock.ini
│   │   └── MiniPlayer/Player.ini
│   └── windhawk/taskbar-dock.json
└── scripts/
    ├── Switch-Mode.ps1
    ├── UltraSaver.ps1
    ├── RestoreRadios.ps1
    ├── DesktopHelpers.ps1
    ├── Reset-Default.ps1
    ├── HotkeyDaemon.ps1
    └── Apply-Windhawk.ps1
```
