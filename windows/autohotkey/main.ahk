#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; AutoHotkey bindings for Windows (PowerShell + browsers).
; Load this file with AutoHotkey v2 on the Windows host.
;
; DVORAK NOTE: physical key -> Dvorak char:
;   C -> j    (delete word — PowerShell)
; ============================================================

; ---- Shared state ----------------------------------------------------------
global hyperMode := false
global hyperUsed := false

; ---- CapsLock = Hyper (Esc if tapped alone) --------------------------------
*CapsLock:: {
    global hyperMode, hyperUsed
    hyperMode := true
    hyperUsed := false
}

*CapsLock up:: {
    global hyperMode, hyperUsed
    hyperMode := false
    if (!hyperUsed)
        Send "{Escape}"
}

#HotIf hyperMode

*j:: {                        ; physical C -> Ctrl+Backspace (delete word)
    global hyperUsed
    hyperUsed := true
    Send "^{Backspace}"
}

#HotIf

; ---- Modules ---------------------------------------------------------------
#Include %A_ScriptDir%\browser.ahk
