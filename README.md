# RBTray-CLI

RBTray clone implemented in AutoHotkey v2 - A utility to minimize windows to system tray

## Features

- **Win+Right-click**: Minimize windows to system tray
- **Tray Icons**: Display program icons of hidden windows in tray menu
- **CLI Control**: Control window hiding/restoration from command line
- **AHK Selector Support**: Specify windows using various AutoHotkey selectors

## Installation

1. AutoHotkey v2 required
2. File structure:
   - `RBTray.ahk2` - Main application
   - `RBTrayCmd.ahk2` - CLI command tool

## Usage

### Running the Main Application

```bash
# Run with AutoHotkey v2
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTray.ahk2

# Or run directly (if AutoHotkey v2 is associated)
RBTray.ahk2
```

### Hotkeys

| Hotkey | Function |
|--------|----------|
| `Win+Right-click` | Minimize window under mouse to tray |
| `Ctrl+Shift+T` | Minimize active window to tray |
| `Ctrl+Shift+R` | Restore all hidden windows |

### CLI Commands

```bash
# Hide windows
RBTrayCmd.ahk2 hide:notepad.exe
RBTrayCmd.ahk2 hide:ahk_exe chrome.exe
RBTrayCmd.ahk2 hide:ahk_class Notepad
RBTrayCmd.ahk2 hide:ahk_pid 12345
RBTrayCmd.ahk2 hide:ahk_id 0xABCDEF
RBTrayCmd.ahk2 "hide:Untitled - Notepad"

# Restore windows
RBTrayCmd.ahk2 restore:notepad.exe
RBTrayCmd.ahk2 restore:chrome.exe

# Restore all windows
RBTrayCmd.ahk2 restore_all

# List hidden windows
RBTrayCmd.ahk2 list
```

## AHK Selector Format

| Selector | Description | Example |
|----------|-------------|---------|
| `WindowTitle` | Search by window title | `"Untitled - Notepad"` |
| `ahk_exe` | Process name | `ahk_exe notepad.exe` |
| `ahk_class` | Window class | `ahk_class Notepad` |
| `ahk_pid` | Process ID | `ahk_pid 1234` |
| `ahk_id` | Window handle | `ahk_id 0x12345` |
| `ahk_group` | Window group | `ahk_group MyGroup` |

## Key Features

- Display original icons of each window in system tray
- Restore individual windows by clicking in tray menu
- External control via IPC (Inter-Process Communication)
- Automatic restoration of all hidden windows on program exit

## Requirements

- Windows OS
- AutoHotkey v2.0 or higher

## How It Works

1. `RBTray.ahk2` runs in background and resides in system tray
2. Windows are hidden via hotkeys or CLI commands
3. `RBTrayCmd.ahk2` communicates with main app using WM_COPYDATA messages
4. Hidden windows are managed in Map structure and dynamically added to tray menu

## License

MIT License

## Author

Developed as part of BSB Launcher project