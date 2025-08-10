#Requires AutoHotkey v2.0
#SingleInstance Force

if (!WinExist('ahk_exe notepad.exe')) {
  RunWait('notepad.exe')
}
Run(A_AhkPath . ' ' . A_ScriptDir . '\RBTrayCmd.ahk "hide:ahk_class Notepad"')