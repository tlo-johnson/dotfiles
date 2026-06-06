; ============================================================
; Hyper layer  (Karabiner "Caps = Hyper / Esc if alone" + nav/symbol layer)
; ============================================================
;
; DVORAK NOTE: AHK sees the active layout (Dvorak). Each hotkey below is the
; Dvorak character that sits on the intended physical (QWERTY-position) key.
; Physical -> Dvorak char map used here:
;   J K L ;  -> h t n s   (arrows: Left Down Up Right)
;   U P      -> g l        ( ( ) )
;   M /      -> m z        ( [ ] )
;   H '      -> d -        ( { } )
;   F        -> u          (Enter)
;   V        -> k          (Backspace)
;   C        -> j          (Ctrl+Backspace / delete word)
;   ,        -> w          (window mode)
;   R        -> p          (project switcher, see projects.ahk)
;   Z        -> ;          (reload config)

; ---- CapsLock = Hyper (Esc if tapped alone) --------------------------------
*CapsLock:: {
    global hyperMode, hyperUsed, mode
    hyperMode := true
    hyperUsed := false
    mode := ""
}

*CapsLock up:: {
    global hyperMode, hyperUsed
    hyperMode := false
    if (!hyperUsed)
        Send "{Escape}"
}

; Mark hyper as used and pass through any held modifiers (Shift/Ctrl/Alt).
HyperSend(key) {
    global hyperUsed
    hyperUsed := true
    mods := ""
    if GetKeyState("Shift", "P")
        mods .= "+"
    if GetKeyState("Ctrl", "P")
        mods .= "^"
    if GetKeyState("Alt", "P")
        mods .= "!"
    Send mods . key
}

#HotIf hyperMode

; ---- Brackets & symbols  (physical U P M / H ') ----------------------------
*g:: HyperSend("(")        ; physical U
*l:: HyperSend(")")        ; physical P
*m:: HyperSend("[")        ; physical M
*z:: HyperSend("]")        ; physical /
*d:: HyperSend("{{}")      ; physical H
*-:: HyperSend("{}}")      ; physical '

; ---- Edit keys -------------------------------------------------------------
*u:: HyperSend("{Enter}")      ; physical F -> Enter
*k:: HyperSend("{Backspace}")  ; physical V -> Backspace
*j:: {                         ; physical C -> Ctrl+Backspace (delete word)
    global hyperUsed
    hyperUsed := true
    Send "^{Backspace}"
}

; ---- Arrow keys  (physical J K L ;) ----------------------------------------
*h:: HyperSend("{Left}")
*t:: HyperSend("{Down}")
*n:: HyperSend("{Up}")
*s:: HyperSend("{Right}")

; ---- Sub-mode entry  (mirrors Karabiner's F13-F18 modal triggers) ----------
*Space:: EnterMode("app",    "APP")        ; Hyper+Space  -> app launcher (apps.ahk)
*w::     EnterMode("window", "WINDOW")     ; Hyper+,      -> window manager (windows.ahk)
*a::     EnterMode("keypad", "KEYPAD")     ; Hyper+A      -> numpad (keypad.ahk)
*;:: {                                     ; Hyper+Z      -> reload config (config.lua)
    global hyperMode
    hyperMode := false
    Reload
}
; Hyper+R (project switcher) lives in projects.ahk.

#HotIf  ; end hyper layer

; ============================================================
; Toggle CapsLock with Left Shift + Right Shift
; ============================================================
~LShift & RShift:: SetCapsLockState(!GetKeyState("CapsLock", "T"))
~RShift & LShift:: SetCapsLockState(!GetKeyState("CapsLock", "T"))

; ============================================================
; Replace Alt with Ctrl (matches the Mac muscle memory)
; ============================================================
!a:: ^a
!c:: ^c
!v:: ^v
!l:: ^l
!z:: ^z
!s:: ^s
!t:: ^t
!w:: ^w
!q:: Send "!{F4}"
