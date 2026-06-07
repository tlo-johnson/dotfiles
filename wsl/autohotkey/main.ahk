#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; Windows-host equivalent of the macOS Karabiner + Hammerspoon
; setup, for use with WSL. Load THIS file with AutoHotkey v2 on
; the Windows host (point AHK at \\wsl$\...\dotfiles\autohotkey\main.ahk
; or copy the autohotkey/ folder to the Windows side).
;
; Layout: the Windows keyboard layout is Dvorak, so AHK sees Dvorak
; characters. Triggers are bound to the Dvorak char that sits on the
; intended physical (QWERTY-position) key. See hyper.ahk for the table.
;
; Architecture mirror:
;   Karabiner Caps=Hyper + F13-F18 modal triggers  -> hyper.ahk
;   Hammerspoon apps.lua    (F13 / Hyper+Space)     -> apps.ahk
;   Hammerspoon windows.lua (F14 / Hyper+,)         -> windows.ahk + vda.ahk
;   Hammerspoon keypad.lua  (F17 / Hyper+A)         -> keypad.ahk
;   Hammerspoon projects.lua(F18 / Hyper+R)         -> projects.ahk (-> WSL tlo-projects)
;   Hammerspoon config.lua  (F16 / Hyper+Z)         -> Reload (in hyper.ahk)
;   Hammerspoon mic.lua     (Cmd+Shift+M)           -> mic.ahk (Ctrl+Shift+M)
; ============================================================

; ---- Shared state ----------------------------------------------------------
; Karabiner used a `hyper_mode` variable; Hammerspoon used sticky modals
; entered via function keys. Here both collapse into plain globals.
global hyperMode := false   ; CapsLock currently held
global hyperUsed := false   ; another key was pressed while Caps was held
global mode      := ""      ; sticky sub-mode: "" | "window" | "app" | "keypad"

; ---- Helpers ---------------------------------------------------------------

; Show a transient mode indicator, mirroring utils.showAlert / createModal.
ShowMode(label) {
    ToolTip label
    SetTimer () => ToolTip(), -1500
}

; Enter a sticky sub-mode (cleared by an action key or Escape).
EnterMode(name, label) {
    global mode, hyperUsed
    hyperUsed := true
    mode := name
    ShowMode(label)
}

; Leave the current sub-mode and clear the indicator.
ExitMode() {
    global mode
    mode := ""
    ToolTip()
}

; Activate the app's window if it exists, otherwise launch it.
; Mirrors apps.lua launchOrFocus and projects.lua window focus.
ActivateOrRun(exe, cmd) {
    if WinExist("ahk_exe " exe)
        WinActivate
    else
        Run cmd
    ExitMode()
}

; ---- Modules ---------------------------------------------------------------
#Include %A_ScriptDir%\hyper.ahk
#Include %A_ScriptDir%\vda.ahk
#Include %A_ScriptDir%\windows.ahk
#Include %A_ScriptDir%\apps.ahk
#Include %A_ScriptDir%\keypad.ahk
#Include %A_ScriptDir%\projects.ahk
#Include %A_ScriptDir%\mic.ahk

; ---- Loaded -----------------------------------------------------------------
; Notify once all modules are registered (mirrors Hammerspoon's init.lua notify).
TrayTip "AutoHotkey loaded"
