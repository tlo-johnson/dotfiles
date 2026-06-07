; ============================================================
; Keypad sub-mode  (Hyper+A ; mirrors hammerspoon/keypad.lua)
; ============================================================
;
; Entered via EnterMode("keypad", ...) in hyper.ahk. Numpad-style grid over the
; right hand, same keys as keypad.lua. Stays active for multi-digit entry;
; Escape exits.
;
;   g=7  c=8  r=9
;   h=4  t=5  n=6
;   m=1  w=2  v=3
;        space=0

#HotIf (mode = "keypad")

Escape:: ExitMode()

g:: Send "7"
c:: Send "8"
r:: Send "9"
h:: Send "4"
t:: Send "5"
n:: Send "6"
m:: Send "1"
w:: Send "2"
v:: Send "3"
Space:: Send "0"

#HotIf  ; end keypad mode
