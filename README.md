# RBTray-CLI

RBTray clone implemented in AutoHotkey v2 - A utility to minimize windows to system tray

## Features

- **Win+Right-click**: Minimize windows to system tray
- **Tray Icons**: Display program icons of hidden windows in tray menu
- **CLI Control**: Control window hiding/restoration from command line
- **AHK Selector Support**: Specify windows using various AutoHotkey selectors
- **Debug Mode**: Optional logging for troubleshooting
- **Comprehensive Testing**: Automated test suite included

## Installation

1. AutoHotkey v2 required
2. File structure:
   - `RBTray.ahk2` - Main application
   - `RBTrayCmd.ahk2` - CLI command tool
   - `RBTrayCmd_Test.ahk2` - Test suite
   - `Example.ahk2` - Quick start example
   - `logs/` - Log files directory (created automatically)

## Quick Start

Run the example to see RBTray in action:

```bash
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" Example.ahk2
```

This will:
1. Start RBTray in the background
2. Open Notepad (if not already open)
3. Hide Notepad to system tray using class selector

## Usage

### Running the Main Application

```bash
# Normal mode (no logging)
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTray.ahk2

# Debug mode (with logging)
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTray.ahk2 --debug

# Or run directly (if AutoHotkey v2 is associated)
RBTray.ahk2
RBTray.ahk2 --debug
```

### Hotkeys

| Hotkey | Function |
|--------|----------|
| `Win+Right-click` | Minimize window under mouse to tray |

### CLI Commands

RBTrayCmd automatically starts RBTray.ahk2 if not already running.

```bash
# Hide windows
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 hide:notepad.exe
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 hide:ahk_exe chrome.exe
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 hide:ahk_class Notepad
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 hide:ahk_pid 12345
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 hide:ahk_id 0xABCDEF
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 "hide:Untitled - Notepad"

# Restore windows
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 restore:notepad.exe
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 restore:ahk_class Notepad

# Restore all windows
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 restore_all

# List hidden windows (shows dialog box)
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 list

# Debug mode (works with any command)
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 "hide:Windows PowerShell" --debug
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd.ahk2 restore_all --debug
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

## Debug Mode & Logging

When using `--debug` flag, log files are created in `logs/` directory:
- `RBTray_Commands.log` - Main application operations
- `RBTrayCmd_Debug.log` - CLI command operations  
- `RBTrayTest_Results.log` - Test results
- `RBTrayTest_Debug.log` - Test execution details

## Testing

Run the comprehensive test suite:

```bash
"C:\Program Files\AutoHotkey\v2\AutoHotkey.exe" RBTrayCmd_Test.ahk2
```

The test suite covers:
- Hide/restore by exe name, class, PID, window title
- Error handling with invalid selectors
- Window state verification
- CLI communication

## Key Features

- Display original icons of each window in system tray
- Restore individual windows by clicking in tray menu
- External control via IPC (Inter-Process Communication)
- Automatic restoration of all hidden windows on program exit
- Clean error handling and logging
- Alt+Tab integration (message window is hidden from Alt+Tab)

## Requirements

- Windows OS
- AutoHotkey v2.0 or higher

## How It Works

1. **Main Application**: `RBTray.ahk2` runs in background and creates a system tray icon
2. **Message Window**: Creates a hidden `ToolWindow` to receive CLI commands (invisible in Alt+Tab)
3. **Window Hiding**: Windows are hidden via hotkeys (Win+Right-click) or CLI commands
4. **IPC Communication**: `RBTrayCmd.ahk2` communicates with main app using WM_COPYDATA messages
5. **Window Management**: Hidden windows are stored in Map structure with metadata (title, class, PID, etc.)
6. **Tray Menu**: Dynamic tray menu shows each hidden window with original program icon
7. **Restoration**: Click tray menu items to restore individual windows, or use CLI commands

## Technical Details

- **GUI Options**: `+ToolWindow` hides message window from Alt+Tab and taskbar
- **Hidden Window Detection**: Uses `DetectHiddenWindows(true)` for reliable CLI communication
- **Error Handling**: Safe file operations with retry mechanism prevent crashes
- **Window Validation**: Skips problematic windows (ApplicationFrameHost.exe, system tray)
- **Encoding**: UTF-16 encoding for international text support in IPC messages
- **Logging**: Centralized logging in `logs/` directory with debug mode control
- **Cleanup**: Automatic restoration of all hidden windows on program exit

## Troubleshooting

- **Commands not working**: RBTrayCmd automatically starts RBTray.ahk2 if needed
- **Windows not hiding**: Check if window is valid (not system window)
- **Logs not appearing**: Use `--debug` flag with RBTrayCmd commands
- **Test failures**: Some tests may fail intermittently due to window timing
- **Cross-directory execution**: RBTrayCmd automatically locates RBTray.ahk2 in same directory

## License

MIT License

## Author

Developed as part of BSB Launcher project