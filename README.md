# win11-rice

An ultra-lightweight, reproducible Windows 11 desktop rice and 4-mode workspace switcher built for **GlazeWM**, **YASB**, **Windhawk**, **Rainmeter**, **Flow Launcher**, and **Everything** — styled in **Catppuccin Mocha ("Shibumi Minimal")**.

![Desktop Rice Preview](docs/screenshot-placeholder.png)

> *Replace `docs/screenshot-placeholder.png` with your own desktop screenshot.*

## Features

- **4 Instant Modes + Clean Reset** via `Alt + Shift + 0..4` (works even when GlazeWM is stopped via a lightweight Win32 `RegisterHotKey` daemon):
  - **Linux (`Alt + Shift + 1`)**: GlazeWM tiling (`6px` gaps) + Shibumi YASB floating top bar + Rainmeter desktop widgets + native taskbar hidden + desktop icons hidden + Balanced power (100% CPU).
  - **Hybrid (`Alt + Shift + 2`)**: GlazeWM tiling + **no YASB** + Windhawk-styled floating hover bottom dock + Rainmeter clock & mini media player + Balanced power.
  - **Studio (`Alt + Shift + 3`)**: GlazeWM stopped for unrestricted floating windows (DaVinci Resolve, Blender, games) + Windhawk floating hover dock + full AC performance (100% CPU).
  - **Saver (`Alt + Shift + 4`)**: Lightweight GlazeWM tiling + YASB top bar + Rainmeter paused + Windows Power Saver with DC CPU capped at `70%`.
  - **Reset (`Alt + Shift + 0`)**: Stops `glazewm` & `yasb`, restores native taskbar & desktop icons, re-imports registry backups, and restores Balanced power (100% CPU).
- **Zero `□` Font Boxes**: System-wide `JetBrainsMono NFP` installation in `C:\Windows\Fonts` + `HKLM` font registration.
- **No `explorer.exe` Restarts**: Instant Win32 `SHAppBarMessage`, `ShowWindow`, and `WM_SETTINGCHANGE` toggles in `DesktopHelpers.ps1`.
- **Backup-First Install & Clean Uninstall**: Automatically exports your registry keys before making changes and restores them on uninstall.

## Hotkey Cheatsheet

| Hotkey | Action |
| :--- | :--- |
| `Alt + Shift + 1` | Switch to **Linux** mode (YASB top bar + GlazeWM) |
| `Alt + Shift + 2` | Switch to **Hybrid** mode (Windhawk hover dock + GlazeWM) |
| `Alt + Shift + 3` | Switch to **Studio** mode (Floating windows + hover dock) |
| `Alt + Shift + 4` | Switch to **Saver** mode (Power Saver + 70% DC CPU cap) |
| `Alt + Shift + 0` | **Reset** to stock Windows 11 defaults |
| `Alt + H / J / K / L` | Focus window left / down / up / right |
| `Alt + Shift + H / L` | Move window left / right |
| `Alt + 1..9` | Switch to workspace `1..9` |
| `Alt + Shift + Space` | Toggle floating (centered) |
| `Alt + F` | Toggle fullscreen |
| `Alt + Enter` | Launch Windows Terminal |
| `Alt + Shift + Q` | Close focused window |

## One-Command Install

Run in **PowerShell** (run as Administrator if you want system-wide font registration and Windhawk HKLM settings applied automatically):

```powershell
git clone https://github.com/Noobi-Programmer/win11-rice.git "$env:USERPROFILE\win11-rice" ; & "$env:USERPROFILE\win11-rice\install.ps1"
```

Or install from a local clone:

```powershell
.\install.ps1
```

To revert all changes and restore your backed-up Windows settings:

```powershell
.\uninstall.ps1
```

## Repository Layout

```text
win11-rice/
├── install.ps1
├── uninstall.ps1
├── README.md
├── configs/
│   ├── glazewm/config.yaml
│   ├── yasb/
│   │   ├── config.yaml
│   │   └── styles.css
│   ├── windhawk/taskbar-dock.json
│   └── rainmeter/StudioMinimal/
│       ├── AestheticClock/Clock.ini
│       └── MiniPlayer/Player.ini
└── scripts/
    ├── Switch-Mode.ps1
    ├── Cycle-Mode.ps1
    ├── DesktopHelpers.ps1
    ├── Reset-Default.ps1
    ├── HotkeyDaemon.ps1
    ├── Get-Mode.ps1
    └── Apply-Windhawk.ps1
```
