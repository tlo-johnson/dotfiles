#Requires AutoHotkey v2.0
#SingleInstance Force

; Karabiner-Elements config converted to AutoHotkey (DVORAK)
; IMPORTANT: AHK hotkeys use the *active layout* (Dvorak), while Karabiner rules are typically
; specified by physical (QWERTY-position) keys. This script maps your intended QWERTY-position
; triggers to the corresponding Dvorak characters.
;
; CapsLock acts as a "Hyper" layer key, Escape when tapped alone.

; Track hyper mode state and whether another key was pressed
global hyperMode := false
global hyperUsed := false
global windowMode := false

; ============================================================
; CapsLock = Hyper Layer (Esc if tapped alone)
; ============================================================
*CapsLock:: {
    global hyperMode, hyperUsed, windowMode
    hyperMode := true
    hyperUsed := false
    windowMode := false
}

*CapsLock up:: {
    global hyperMode, hyperUsed
    hyperMode := false
    if (!hyperUsed) {
        Send "{Escape}"
    }
}

; Helper to mark hyper as used and passthrough modifiers
HyperSend(key) {
    global hyperUsed
    hyperUsed := true
    ; Passthrough current modifiers (Shift, Ctrl, Alt)
    mods := ""
    if GetKeyState("Shift", "P")
        mods .= "+"
    if GetKeyState("Ctrl", "P")
        mods .= "^"
    if GetKeyState("Alt", "P")
        mods .= "!"
    Send mods . key
}

; ============================================================
; Hyper-layer (DVORAK triggers for QWERTY-position intent)
; ============================================================
#HotIf hyperMode

; ------------------------------------------------------------
; Brackets & Symbols
; Intended (physical/QWERTY): U P M / H '  ->  ( ) - = _ +
; Dvorak chars on those physical keys: g l m z d - respectively
; ------------------------------------------------------------

; Hyper + (physical U) -> "("
*g:: HyperSend("(")

; Hyper + (physical P) -> ")"
*l:: HyperSend(")")

; Hyper + (physical M) -> "-"
*m:: HyperSend("[")

; Hyper + (physical /) -> "="
*z:: HyperSend("]")

; Hyper + (physical H) -> "_"
*d:: HyperSend("{{}")

; Hyper + (physical ') -> "+"
*-:: HyperSend("{}}")

; ------------------------------------------------------------
; Enter (intended physical F -> Enter)
; Dvorak char on physical F is "u"
; ------------------------------------------------------------
*u:: HyperSend("{Enter}")

; ------------------------------------------------------------
; Backspace (intended physical V -> Backspace)
; Dvorak char on physical V is "k"
; ------------------------------------------------------------
*k:: HyperSend("{Backspace}")

; Hyper + (physical C) -> Ctrl+Backspace (delete word)
; Dvorak char on physical C is "j"
*j:: {
    global hyperUsed
    hyperUsed := true
    Send "^{Backspace}"
}

; ------------------------------------------------------------
; Arrow Keys (intended physical JK L ; -> Left/Down/Up/Right)
; Physical QWERTY: J K L ;  -> Dvorak: h t n s
; ------------------------------------------------------------
*h:: HyperSend("{Left}")   ; physical J
*t:: HyperSend("{Down}")   ; physical K
*n:: HyperSend("{Up}")     ; physical L
*s:: HyperSend("{Right}")  ; physical ;

*Space:: {
    global windowMode, hyperUsed
    windowMode := true
    hyperUsed := true

    ToolTip "WINDOW MODE"
    SetTimer () => ToolTip(), -800
}

#HotIf  ; End hyper mode context

ActivateOrRun(exe, cmd)
{
    global windowMode

    if WinExist("ahk_exe " exe)
        WinActivate
    else
        Run cmd

    windowMode := false
}

#HotIf windowMode

*t:: ActivateOrRun("WindowsTerminal.exe","wt.exe")
*b:: ActivateOrRun("chrome.exe","chrome.exe")

#HotIf ; End window mode context
; ============================================================
; Toggle CapsLock with Left Shift + Right Shift
; ============================================================
~LShift & RShift:: SetCapsLockState(!GetKeyState("CapsLock", "T"))
~RShift & LShift:: SetCapsLockState(!GetKeyState("CapsLock", "T"))


; =====================
; Replace Alt with Ctrl
; =====================

!a:: ^a
!c:: ^c
!v:: ^v
!l:: ^l
!z:: ^z
!s:: ^s
!t:: ^t
!w:: ^w
!q:: Send "!{F4}"
