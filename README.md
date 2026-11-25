# win11-rice

Ultra-lightweight, reproducible Windows 11 desktop rice & multi-mode workspace switcher (Catppuccin Mocha / Shibumi Minimal aesthetic) built for laptops and creator workstations.

## Features

- **Shibumi Minimal YASB Top Bar**: Translucent floating 30px bar (`JetBrainsMono NFP`, borderless Catppuccin Mocha pills, GlazeWM workspaces, inline media controls, clock + calendar, mode pill, CPU/RAM/volume/Wi-Fi/battery).
- **4-Mode + Bar-Style Switcher (`Switch-Mode.ps1`)**: Instant Win32 P/Invoke taskbar & desktop icon toggling (`ShowWindow`, `SHAppBarMessage`, `WM_SETTINGCHANGE`) without killing `explorer.exe`.
- **GlazeWM Tiling + Conflict-Free Hotkeys**: `Alt+Shift+1..4` and `Alt+Shift+0` (zero collision with hardware `Ctrl+Alt+N` shortcuts), plus a hidden Win32 `HotkeyDaemon.ps1` fallback when GlazeWM is stopped.
- **Windhawk Floating Hover Dock**: `DockLike` taskbar styler + translucent Start Menu & Notification Center for `hybrid` and `studio` modes.
- **Rainmeter `StudioMinimal` Widgets**: Lightweight (~10 MB RAM) desktop aesthetic clock and compact `280x68` mini media player.

## Screenshots

> _Add screenshots of `linux` (YASB top bar) and `hybrid` (Windhawk hover dock + Rainmeter widgets) modes here._

## Hotkey Cheatsheet

| Hotkey | Action |
|---|---|
| `Alt + Shift + 1` | **Linux Mode** — GlazeWM tiling ON, Shibumi YASB top bar, bottom taskbar hidden, Rainmeter widgets ON |
| `Alt + Shift + 2` | **Hybrid Mode** — GlazeWM tiling ON, YASB OFF, Windhawk floating hover bottom dock, Rainmeter widgets ON |
| `Alt + Shift + 3` | **Studio Mode** — GlazeWM OFF (free-floating for DaVinci Resolve / Blender / games), hover bottom dock, full AC power |
| `Alt + Shift + 4` | **HyperSaver Mode** — GlazeWM + YASB, Rainmeter paused, Windows Power Saver + 70% DC CPU cap |
| `Alt + Shift + 0` | **Reset Default** — Stops ricing apps, restores registry backups & stock Windows taskbar/icons |
| `Alt + Space` | **Flow Launcher** (backed by Everything search) |
| `Alt + Enter` | Open Windows Terminal |
| `Alt + H/J/K/L` | Focus window left/down/up/right (GlazeWM) |
| `Alt + 1..9` | Switch workspace `1..9` (GlazeWM) |

## One-Command Install

Run in an **elevated PowerShell** terminal:

```powershell
irm https://raw.githubusercontent.com/<your-username>/win11-rice/main/install.ps1 | iex
```

Or locally from a cloned repo:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

## Uninstall / Revert

```powershell
powershell -ExecutionPolicy Bypass -File .\uninstall.ps1
```
