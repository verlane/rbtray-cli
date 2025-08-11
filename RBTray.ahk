#Requires AutoHotkey v2.0
#SingleInstance Force

class RBTrayApp {
    static trayWindows := Map()
    static trayIcons := Map()
    static nextIconId := 1
    static debugMode := false  ; Set to true for debugging
    
    static __New() {
        ; Check for debug argument
        for arg in A_Args {
            if arg = "--debug" {
                this.debugMode := true
                break
            }
        }
        
        this.InitializeTray()
        this.InitializeMessageReceiver()
        this.InitializeHotkeys()
        
        if this.debugMode
            this.ShowDebugInfo()
    }
    
    static InitializeTray() {
        TraySetIcon("Shell32.dll", 16)
        A_IconTip := "RBTray - Win+Right-click to minimize to tray"
        
        A_TrayMenu.Delete()
        A_TrayMenu.Add("Show All Windows", (*) => this.RestoreAll())
        A_TrayMenu.Add()
        A_TrayMenu.Add("Exit RBTray", (*) => ExitApp())
    }
    
    static InitializeMessageReceiver() {
        ; Single GUI window for CLI communication
        this.msgWin := Gui("+ToolWindow -MaximizeBox -MinimizeBox", "RBTray_MessageWindow")
        this.msgWin.Add("Text", , "RBTray Message Receiver`nThis window receives CLI commands")
        
        ; Show or hide based on debug mode
        if this.debugMode {
            this.msgWin.Show("w350 h100")
        } else {
            ; Hide the message window - RBTrayCmd uses DetectHiddenWindows(true) to find it
            this.msgWin.Show("Hide")
        }
        
        OnMessage(0x004A, ObjBindMethod(this, "ReceiveCommand"))
    }
    
    static InitializeHotkeys() {
        ; Exit handler - restore all windows when program exits
        OnExit((*) => this.RestoreAll())
    }
    
    static ShowDebugInfo() {
        ToolTip("RBTray started - HWND: " . this.msgWin.Hwnd . "`nClass: " . WinGetClass(this.msgWin.Hwnd))
        SetTimer(() => ToolTip(), -3000)
    }
    
    
    static IsValidWindow(hwnd) {
        ; Simple validation - if we can't get basic info, skip it
        if !hwnd
            return false
            
        ; Get window style and process info in one go
        try {
            style := WinGetStyle(hwnd)
            processName := WinGetProcessName(hwnd)
            className := WinGetClass(hwnd)
        } catch {
            return false
        }
        
        ; Basic checks
        if !style || !((style & 0x10000000) && (style & 0x00C00000))  ; WS_VISIBLE && WS_CAPTION
            return false
            
        ; Skip problematic window types
        if processName = "ApplicationFrameHost.exe" {
            this.LogCommand("Skipping ApplicationFrameHost window: " . hwnd)
            return false
        }
        
        if className = "Shell_TrayWnd" || className = "Shell_SecondaryTrayWnd" {
            this.LogCommand("Skipping system tray window: " . hwnd)
            return false
        }
        
        return true
    }
    
    static MinimizeToTray(hwnd := "") {
        if !hwnd
            hwnd := WinExist("A")
        
        this.LogCommand("MinimizeToTray called with HWND: " . hwnd)
        
        if !hwnd {
            this.LogCommand("No window handle provided")
            return false
        }
        
        if this.trayWindows.Has(hwnd) {
            this.LogCommand("Window already in tray: " . hwnd)
            return true
        }
        
        ; Collect window data
        windowData := this.CollectWindowData(hwnd)
        if !windowData {
            this.LogCommand("Failed to collect window data for: " . hwnd)
            return false
        }
        
        ; Create tray entry
        iconId := "RBTray_" . this.nextIconId++
        this.trayWindows[hwnd] := windowData
        this.trayWindows[hwnd].iconId := iconId
        
        ; Add to tray menu
        this.CreateTrayIcon(hwnd, iconId, windowData.title, windowData.processPath)
        
        ; Hide the window
        try {
            WinHide(hwnd)
        } catch {
            this.LogCommand("Failed to hide window: " . hwnd)
            this.CleanupFailedTrayEntry(hwnd, iconId)
            return false
        }
        
        this.LogCommand("Window hidden successfully: " . hwnd)
        return true
    }
    
    static CleanupFailedTrayEntry(hwnd, iconId) {
        ; Clean up failed tray entry
        this.trayWindows.Delete(hwnd)
        if this.trayIcons.Has(iconId) {
            menuItem := this.trayIcons[iconId].menuItem
            try {
                A_TrayMenu.Delete(menuItem)
            } catch {
            }
            this.trayIcons.Delete(iconId)
        }
    }
    
    static CollectWindowData(hwnd) {
        ; Get all window data at once - if any fails, return null
        try {
            title := WinGetTitle(hwnd)
            processName := WinGetProcessName(hwnd)
            processPath := WinGetProcessPath(hwnd)
            className := WinGetClass(hwnd)
            pid := WinGetPID(hwnd)
        } catch {
            return false
        }
        
        if !processName  ; Most important field
            return false
            
        this.LogCommand("Window details - Title: " . title . ", Process: " . processName . ", Class: " . className . ", PID: " . pid)
        
        return {
            title: title,
            process: processName,
            processPath: processPath,
            className: className,
            pid: pid
        }
    }
    
    static CreateTrayIcon(hwnd, iconId, title, iconPath) {
        trayTip := title ? title : "Window"
        if StrLen(trayTip) > 64
            trayTip := SubStr(trayTip, 1, 61) . "..."
        
        A_TrayMenu.Insert("1&", trayTip, (*) => this.RestoreWindow(hwnd))
        
        try {
            A_TrayMenu.SetIcon(trayTip, iconPath)
        } catch {
            A_TrayMenu.SetIcon(trayTip, "Shell32.dll", 3)
        }
        
        this.trayIcons[iconId] := {
            hwnd: hwnd,
            menuItem: trayTip
        }
    }
    
    static RestoreWindow(hwnd) {
        if !this.trayWindows.Has(hwnd)
            return false
        
        windowInfo := this.trayWindows[hwnd]
        
        ; Remove from tray menu
        if this.trayIcons.Has(windowInfo.iconId) {
            menuItem := this.trayIcons[windowInfo.iconId].menuItem
            try {
                A_TrayMenu.Delete(menuItem)
            } catch {

            }
            this.trayIcons.Delete(windowInfo.iconId)
        }
        
        ; Show and activate window
        try {
            WinShow(hwnd)
            showResult := true
            WinActivate(hwnd)
            activateResult := true
        } catch {
            showResult := false
            activateResult := false
        }
        
        this.LogCommand("Window restore: Show=" . showResult . ", Activate=" . activateResult . " for HWND: " . hwnd)
        
        ; Always remove from our tracking
        this.trayWindows.Delete(hwnd)
        return showResult
    }
    
    static RestoreAll() {
        for hwnd, windowInfo in this.trayWindows.Clone() {
            this.RestoreWindow(hwnd)
        }
    }
    
    static ReceiveCommand(wParam, lParam, msg, hwnd) {
        this.LogCommand("ReceiveCommand called - wParam: " . wParam . ", lParam: " . lParam . ", msg: " . msg . ", hwnd: " . hwnd)
        
        command := this.ParseWMCopyData(lParam)
        if !command {
            this.LogCommand("Failed to parse command")
            return false
        }
        
        this.LogCommand("Received command: " . command)
        
        ; Route command to appropriate handler
        if InStr(command, "hide:") = 1
            this.ProcessHideCommand(SubStr(command, 6))
        else if command = "restore_all"
            this.RestoreAll()
        else if InStr(command, "restore:") = 1
            this.ProcessRestoreCommand(SubStr(command, 9))
        else if command = "list"
            this.ProcessListCommand()
        else
            this.LogCommand("Unknown command: " . command)
        
        return true
    }
    
    static ParseWMCopyData(lParam) {
        if !lParam
            return ""
        dataSize := NumGet(lParam, A_PtrSize, "UInt")
        dataPtr := NumGet(lParam, 2 * A_PtrSize, "Ptr")
        if !dataPtr || !dataSize
            return ""
        return StrGet(dataPtr, dataSize // 2, "UTF-16")
    }
    
    static ProcessHideCommand(target) {
        this.LogCommand("Processing hide command for: " . target)
        
        targetHwnd := this.FindTargetWindow(target)
        this.LogCommand("Found target window: " . targetHwnd)
        
        if targetHwnd {
            this.MinimizeToTray(targetHwnd)
            this.LogCommand("MinimizeToTray called for HWND: " . targetHwnd)
        } else {
            this.LogCommand("No window found for target: " . target)
        }
    }
    
    static ProcessRestoreCommand(target) {
        this.LogCommand("Processing restore command for: " . target)
        
        restoredCount := 0
        if InStr(target, "ahk_") {
            restoredCount := this.RestoreByAHKSelector(target)
        } else {
            restoredCount := this.RestoreByTitleOrProcess(target)
        }
        
        this.LogCommand("Restore command completed. Restored " . restoredCount . " windows.")
    }
    
    static ProcessListCommand() {
        list := ""
        for hwnd, windowInfo in this.trayWindows {
            list .= "HWND: " . hwnd . " | " . windowInfo.title . " | " . windowInfo.process . "`n"
        }
        
        if list {
            this.LogCommand("Hidden windows list:`n" . list)
        } else {
            this.LogCommand("No windows are currently hidden")
        }
    }
    
    static FindTargetWindow(target) {
        ; Check if target already has ahk_ prefix
        if InStr(target, "ahk_")
            return WinExist(target)
        
        ; Try common selectors, prioritize exe name
        targetHwnd := WinExist("ahk_exe " . target)
        if !targetHwnd
            targetHwnd := WinExist("ahk_class " . target)
        if !targetHwnd
            targetHwnd := WinExist(target)  ; Title matching
        
        return targetHwnd
    }
    
    static RestoreByAHKSelector(target) {
        this.LogCommand("Using AHK selector matching for: " . target)
        restoredCount := 0
        
        for hwnd, windowInfo in this.trayWindows.Clone() {
            if this.MatchesAHKSelector(target, hwnd, windowInfo) {
                this.LogCommand("Restoring window HWND: " . hwnd . " (" . windowInfo.title . ")")
                this.RestoreWindow(hwnd)
                restoredCount++
            }
        }
        
        return restoredCount
    }
    
    static RestoreByTitleOrProcess(target) {
        this.LogCommand("Using title/process matching for: " . target)
        restoredCount := 0
        
        for hwnd, windowInfo in this.trayWindows.Clone() {
            if InStr(windowInfo.title, target) || InStr(windowInfo.process, target) {
                this.LogCommand("Match found - Title: " . windowInfo.title . ", Process: " . windowInfo.process)
                this.RestoreWindow(hwnd)
                restoredCount++
            }
        }
        
        return restoredCount
    }
    
    static MatchesAHKSelector(target, hwnd, windowInfo) {
        if InStr(target, "ahk_exe ") {
            exeName := SubStr(target, 9)
            if InStr(windowInfo.process, exeName) {
                this.LogCommand("Match found by exe: " . exeName . " in " . windowInfo.process)
                return true
            }
        } else if InStr(target, "ahk_class ") {
            className := SubStr(target, 11)
            if windowInfo.className = className {
                this.LogCommand("Match found by stored class: " . className)
                return true
            }
        } else if InStr(target, "ahk_pid ") {
            targetPid := SubStr(target, 9)
            if windowInfo.pid = targetPid {
                this.LogCommand("Match found by stored PID: " . targetPid)
                return true
            }
        } else if InStr(target, "ahk_id ") {
            targetId := SubStr(target, 8)
            if hwnd = targetId {
                this.LogCommand("Match found by ID: " . targetId)
                return true
            }
        }
        return false
    }
    
    static LogCommand(message) {
        ; Log only in debug mode (when --debug argument is passed)
        if this.debugMode {
            ; Create logs directory if it doesn't exist
            logDir := A_ScriptDir . "\logs"
            if !DirExist(logDir)
                DirCreate(logDir)
            
            ; Safe file append with retry mechanism
            try {
                FileAppend(A_Now . ": " . message . "`n", logDir . "\RBTray_Commands.log")
            } catch {
                ; Retry once after brief delay
                Sleep(50)
                try {
                    FileAppend(A_Now . ": " . message . "`n", logDir . "\RBTray_Commands.log")
                } catch {
                    ; Silent fail - don't crash the main app
                }
            }
        }
    }
}

; Initialize RBTray
RBTrayApp()

; Win+Right-click hotkey
#RButton::
{
    MouseGetPos(, , &hwnd)
    if hwnd && RBTrayApp.IsValidWindow(hwnd) {
        RBTrayApp.MinimizeToTray(hwnd)
        return
    }
    Send("{RButton}")
}