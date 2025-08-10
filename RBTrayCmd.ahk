#Requires AutoHotkey v2.0
#SingleInstance Off

; Enable detection of hidden windows
DetectHiddenWindows(true)

class RBTrayCmd {
    static COPYDATA_MSG := 0x004A
    static debugMode := false  ; Set to true for debugging with dialogs
    
    static Main() {
        ; Parse arguments
        if A_Args.Length == 0 {
            this.ShowUsage()
            return
        }
        
        ; Check for debug mode in any argument position
        this.debugMode := false
        for arg in A_Args {
            if arg = "--debug" {
                this.debugMode := true
                break
            }
        }
        
        command := A_Args[1]
        
        ; Validate and execute
        if !this.IsValidCommand(command)
            this.ExitWithError("Invalid command: " . command)
        
        rbtrayHwnd := this.FindRBTrayWindow()
        if !rbtrayHwnd {
            this.LogDebug("RBTray not found, starting RBTray.ahk...")
            this.StartRBTray()
            Sleep(1500)  ; Wait for RBTray to initialize
            rbtrayHwnd := this.FindRBTrayWindow()
            if !rbtrayHwnd
                this.ExitWithError("Failed to start RBTray. Please check RBTray.ahk manually.")
        }
        
        if !this.SendCommand(rbtrayHwnd, command)
            this.ExitWithError("Failed to send command to RBTray.")
    }
    
    static IsValidCommand(command) {
        ; Simple pattern matching
        return (command = "restore_all" 
            || command = "list" 
            || InStr(command, "hide:") = 1 
            || InStr(command, "restore:") = 1)
    }
    
    static FindRBTrayWindow() {
        ; Try common window searches in order of likelihood
        hwnd := WinExist("RBTray_MessageWindow")
            || WinExist("RBTray ahk_class AutoHotkeyGUI")
        
        if hwnd
            this.LogDebug("Found RBTray window: " . hwnd)
        else
            this.LogDebug("RBTray window not found")
            
        return hwnd
    }
    
    static StartRBTray() {
        ; Use the directory where RBTrayCmd.ahk is located, not A_ScriptDir
        cmdDir := StrReplace(A_ScriptFullPath, A_ScriptName, "")
        rbtrayPath := cmdDir . "RBTray.ahk"
        this.LogDebug("Starting RBTray from: " . rbtrayPath)

        try {
            if this.debugMode {
                Run(A_AhkPath . ' "' . rbtrayPath . '" --debug')
            } else {
                Run(A_AhkPath . ' "' . rbtrayPath . '"')
            }
            this.LogDebug("RBTray started successfully")
        } catch as e {
            this.LogDebug("Failed to start RBTray: " . e.message)
        }
    }
    
    static SendCommand(targetHwnd, command) {
        this.LogDebug("Sending command: " . command . " to HWND: " . targetHwnd)
        
        ; Create command buffer (UTF-16)
        commandBuffer := Buffer(StrPut(command, "UTF-16") * 2)
        StrPut(command, commandBuffer, "UTF-16")
        
        ; Create COPYDATASTRUCT
        cds := Buffer(3 * A_PtrSize)
        NumPut("UPtr", 0, cds, 0)  ; dwData
        NumPut("UInt", commandBuffer.Size, cds, A_PtrSize)  ; cbData
        NumPut("Ptr", commandBuffer.Ptr, cds, 2 * A_PtrSize)  ; lpData
        
        ; Send message
        try {
            result := SendMessage(this.COPYDATA_MSG, 0, cds.Ptr, targetHwnd)
        } catch {
            result := 0
        }
        this.LogDebug("Message sent, result: " . result)
        
        return result != 0
    }
    
    static ExitWithError(message) {
        this.ReportError(message)
        if this.debugMode
            this.ShowUsage()
        ExitApp(1)
    }
    
    static ShowUsage() {
        usage := "RBTrayCmd - Command line interface for RBTray`n`n"
        usage .= "Usage: RBTrayCmd.ahk <command>`n`n"
        usage .= "Commands:`n"
        usage .= "  hide:<window_selector>    Hide window to tray`n"
        usage .= "  restore:<window_selector>  Restore window from tray`n"
        usage .= "  restore_all               Restore all hidden windows`n"
        usage .= "  list                      List all hidden windows`n`n"
        usage .= "Window selectors:`n"
        usage .= "  notepad.exe               By executable name`n"
        usage .= "  ahk_exe notepad.exe       By executable (explicit)`n"
        usage .= "  ahk_class Notepad         By window class`n"
        usage .= "  ahk_pid 1234              By process ID`n"
        usage .= "  ahk_id 5678               By window ID`n"
        usage .= "  Window Title              By window title`n`n"
        usage .= "Examples:`n"
        usage .= "  RBTrayCmd.ahk hide:notepad.exe`n"
        usage .= "  RBTrayCmd.ahk restore:ahk_class Notepad`n"
        usage .= "  RBTrayCmd.ahk restore_all`n"
        
        MsgBox(usage, "RBTrayCmd Usage", "Icon!")
    }
    
    static ShowError(message) {
        MsgBox("Error: " . message, "RBTrayCmd Error", "IconX")
    }
    
    static LogDebug(message) {
        ; Log only in debug mode
        if this.debugMode {
            logDir := A_ScriptDir . "\logs"
            if !DirExist(logDir)
                DirCreate(logDir)
            
            ; Safe file append with retry mechanism
            try {
                FileAppend(A_Now . ": " . message . "`n", logDir . "\RBTrayCmd_Debug.log")
            } catch {
                ; Retry once after brief delay
                Sleep(50)
                try {
                    FileAppend(A_Now . ": " . message . "`n", logDir . "\RBTrayCmd_Debug.log")
                } catch {
                    ; Silent fail - don't crash the CLI tool
                }
            }
        }
    }
    
    static ReportError(message) {
        this.LogDebug("ERROR: " . message)
        if this.debugMode
            this.ShowError(message)
    }
}

; Run the application
RBTrayCmd.Main()