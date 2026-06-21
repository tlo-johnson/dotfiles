#Requires AutoHotkey v2.0
#SingleInstance Force

; Win+Tab -> Alt+Tab (interactive switcher)
; Hold Win and keep pressing Tab to cycle windows; release Win to confirm.

global altHeld := false

#Tab::
{
    global altHeld
    if !altHeld {
        Send "{Alt down}"
        altHeld := true
    }
    Send "{Tab}"
}

LWin up::
RWin up::
{
    global altHeld
    if altHeld {
        Send "{Alt up}"
        altHeld := false
    }
}
