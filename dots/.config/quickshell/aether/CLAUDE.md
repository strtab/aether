# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Aether is a desktop shell built with Quickshell, a QML-based framework for Wayland/Hyprland overlays. The entire UI is written in QML with JavaScript utilities. It uses Material Design 3 (M3) theming and Hyprland protocol (wlr-layer-shell) for window positioning.

## Architecture

### Entry Points

- `shell.qml` -- main Quickshell shell, renders all panels inside a `ShellRoot` via `PanelLoader` wrappers
- `settings.qml` -- standalone settings application (`ApplicationWindow`)
- `ReloadPopup.qml`, `killDialog.qml` -- standalone panels (reload indicator, session kill dialog)

### Module Organization (`modules/`)

Modules are mapped to the `qs.modules.*` import namespace by Quickshell's module resolution. Each top-level module directory corresponds to a UI component:

| Module | Purpose |
|--------|---------|
| `bar` | Top panel (active window, workspaces, tray, clock, battery) |
| `dock` | Magnifying dock with app slots, file slots, trash |
| `background` | Desktop background widgets (clock, weather) |
| `search` | Application/search launcher popup |
| `notificationCenter` | Notification center panel |
| `notificationPopup` | Individual notification popups |
| `mediaControls` | MPRIS media controls widget |
| `sidebarRight` | Right-side quick settings panel (toggles, wifi, volume mixer, calendar) |
| `onScreenDisplay` | OSD for brightness/volume |
| `onScreenKeyboard` | On-screen keyboard |
| `regionSelector` | Screenshot region selector |
| `polkit` | Polkit authentication dialogs |
| `sessionScreen` | Session screen (lock, logout, etc.) |
| `lock` | Lock screen with PAM integration |
| `cheatsheet` | Keybind cheatsheet |
| `wallpaperSelector` | Wallpaper picker |
| `screenCorners` | Screen corner masks for Hyprland |

Each module uses `Scope`, `PanelLoader`, or `Variants` to manage visibility. Visibility is controlled through `GlobalStates`.

### Shared Infrastructure (`modules/common/`)

- `Config.qml` -- singleton managing config.json reads/writes with debounce, file watching, and JSON adapter
- `Appearance.qml` -- singleton defining all M3 colors, typography, animation curves, sizes, rounding, layers. Uses wallpaper color quantization for dynamic theming
- `Directories.qml` -- singleton providing filesystem paths (XDG dirs, cache, scripts)
- `Persistent.qml` -- persistent key-value storage
- `models/` -- shared data models (`IndexModel`, `NestableObject`, `QuickToggleModel`, `HyprlandConfigOption`, etc.)
- `functions/` -- utility QML objects (`DateUtils`, `Fuzzy`, `ColorUtils`, `StringUtils`, `Session`, `NotificationUtils`, etc.) with embedded `.js` files for fuzzy sorting and Levenshtein distance
- `widgets/` -- reusable UI components (`StyledFlickable`, `StyledListView`, `StyledSlider`, `StyledTextInput`, `PopupMenu`, `CalendarView`, `WaveVisualizer`, `AddressBreadcrumb`, etc.)
- `utils/` -- process wrappers (`MultiTurnProcess`, `ScreenshotAction`, `TempScreenshotProcess`, `ImageDownloaderProcess`)

### Services (`services/`)

Singletons that interface with system services via IPC, D-Bus, or shell commands:

| Service | Purpose |
|---------|---------|
| `HyprlandData` | Hyprland client/workspace state (IPC) |
| `HyprlandKeybinds` | Keybind management |
| `HyprlandConfig` | Hyprland config reading/writing |
| `Audio` | PulseAudio/PipeWire audio control |
| `Notifications` | D-Bus notification handling |
| `Network` / `BluetoothStatus` | Network/bluetooth state |
| `Battery` / `Brightness` | Hardware sensors |
| `MprisController` | MPRIS DBus interface for media |
| `PolkitService` | Polkit authentication |
| `LauncherApps` / `AppSearch` / `LauncherSearch` / `ActionSearch` | Application launching and search |
| `Weather` / `Updates` / `SystemInfo` / `ResourceUsage` | System info services |
| `EasyEffects` / `Hyprsunset` / `Idle` | Audio effects, color temperature, idle management |
| `Todo` / `TimerService` / `Booru` / `TrayService` | Domain-specific services |

### Global State (`GlobalStates.qml`)

Singleton tracking UI visibility state: bar open/closed, sidebar, search popup, lock screen, etc. Monitors Hyprland and exposes properties consumed by modules for conditional rendering.

## Key Patterns

1. **PanelLoader** -- wrapper in `shell.qml` that loads a component only when its condition is met. Condition can be based on config flags or always-on (`PanelLoader { component: Lock {} }`).
2. **Scope + Variants** -- modules typically use `Scope` for conditional rendering and `Variants { model: Quickshell.screens }` to create per-monitor instances (bar, dock).
3. **Config binding** -- all user-facing properties are read through `Config.options.*`. Writes go through the debounced JSON adapter. The `Appearance` singleton reads from config for colors/typography.
4. **Animation system** -- `Appearance.animation` provides pre-configured `NumberAnimation`/`ColorAnimation` components with M3-style easing curves. Use `Appearance.animation.elementMoveFast.numberAnimation.createObject(this)` to create instances.
5. **Material design tokens** -- colors are accessed as `Appearance.colors.col*`, primary as `Appearance.m3colors.*`. Wallpaper-derived vibrancy auto-adjusts transparency.

## Styling

- Uses 2-space indentation (see `.qmlformat.ini`)
- Quickshell shell path resolution: `Quickshell.shellPath("modules/bar")` returns the directory containing this repo
- Module imports use the `qs.modules.*` convention mapped to module directories

## Configuration

User settings are stored in `~/.config/aether/config.json`, managed by `Config.qml`. The settings app (`settings.qml`) provides a UI for editing these. Config is watched live and auto-reloaded. Changes debounce writes by 50ms.
