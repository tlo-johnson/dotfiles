#Requires AutoHotkey v2.0
#SingleInstance Force

; Karabiner-Elements config converted to AutoHotkey
; CapsLock acts as a "Hyper" layer key, Escape when tapped alone

; Track hyper mode state and whether another key was pressed
global hyperMode := false
global hyperUsed := false

; ============================================================
; CapsLock = Hyper Layer (Esc if tapped alone)
; ============================================================
*CapsLock:: {
    global hyperMode, hyperUsed
    hyperMode := true
    hyperUsed := false
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
; Hyper-layer: Brackets & Symbols
; ============================================================
; Hyper + U → (
#HotIf hyperMode
*u:: HyperSend("{(}")
; Hyper + P → )
*p:: HyperSend("{)}")
; Hyper + M → -
*m:: HyperSend("{-}")
; Hyper + / → =
*/:: HyperSend("{=}")
; Hyper + H → _ (underscore)
*h:: HyperSend("{_}")
; Hyper + ' → + (plus)
*':: HyperSend("{+}")

; ============================================================
; Hyper-layer: Enter (Hyper + F)
; ============================================================
*f:: HyperSend("{Enter}")

; ============================================================
; Hyper-layer: Backspace
; ============================================================
; Hyper + V → Backspace
*v:: HyperSend("{Backspace}")
; Hyper + C → Ctrl+Backspace (delete word - Windows equivalent of Option+Backspace)
*c:: {
    global hyperUsed
    hyperUsed := true
    Send "^{Backspace}"
}

; ============================================================
; Hyper-layer: Arrow Keys (JKIL layout - left/down/up/right)
; ============================================================
; Hyper + J → Left
*j:: HyperSend("{Left}")
; Hyper + K → Down
*k:: HyperSend("{Down}")
; Hyper + L → Up
*l:: HyperSend("{Up}")
; Hyper + ; → Right
*`;:: HyperSend("{Right}")

#HotIf  ; End hyper mode context

; ============================================================
; Disable Enter and Backspace (only accessible via Hyper layer)
; ============================================================
*Enter:: return
*Backspace:: return

; ============================================================
; Toggle CapsLock with Left Shift + Right Shift
; ============================================================
~LShift & RShift:: SetCapsLockState(!GetKeyState("CapsLock", "T"))
~RShift & LShift:: SetCapsLockState(!GetKeyState("CapsLock", "T"))
