; ============================================================
; Window manager sub-mode  (Hyper+, ; mirrors hammerspoon/windows.lua)
; ============================================================
;
; Entered via EnterMode("window", ...) in hyper.ahk. Active while mode="window";
; each action snaps/moves the active window then exits the mode (Escape cancels).
; Snapping uses fractional units of the work area, like Hammerspoon moveToUnit.

global prevFrames := Map()   ; hwnd -> {x,y,w,h} saved before maximize (windows.lua prevFrames)

; Work area (excludes taskbar) of the monitor under the given window.
WorkAreaFor(hwnd, &L, &T, &W, &H) {
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    cx := wx + ww // 2, cy := wy + wh // 2
    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &ml, &mt, &mr, &mb)
        if (cx >= ml && cx < mr && cy >= mt && cy < mb) {
            L := ml, T := mt, W := mr - ml, H := mb - mt
            return
        }
    }
    MonitorGetWorkArea(MonitorGetPrimary(), &ml, &mt, &mr, &mb)
    L := ml, T := mt, W := mr - ml, H := mb - mt
}

; Move the active window to a fractional rectangle of its work area.
Snap(fx, fy, fw, fh) {
    hwnd := WinExist("A")
    if !hwnd {
        ExitMode()
        return
    }
    WorkAreaFor(hwnd, &L, &T, &W, &H)
    WinMove(L + Round(fx * W), T + Round(fy * H), Round(fw * W), Round(fh * H), hwnd)
    ExitMode()
}

#HotIf (mode = "window")

Escape:: ExitMode()

; Halves
Left::  Snap(0,   0,   0.5, 1)
Right:: Snap(0.5, 0,   0.5, 1)
Up::    Snap(0,   0,   1,   0.5)
Down::  Snap(0,   0.5, 1,   0.5)

; Quarters  (physical J ; L K -> Dvorak h s n t, matching windows.lua)
h:: Snap(0,   0,   0.5, 0.5)
s:: Snap(0.5, 0,   0.5, 0.5)
n:: Snap(0,   0.5, 0.5, 0.5)
t:: Snap(0.5, 0.5, 0.5, 0.5)

; Centered (windows.lua "c")
c:: Snap(0.1, 0.075, 0.8, 0.85)

; Maximize toggle (windows.lua "f")
f:: {
    global prevFrames
    hwnd := WinExist("A")
    if !hwnd {
        ExitMode()
        return
    }
    WorkAreaFor(hwnd, &L, &T, &W, &H)
    WinGetPos(&x, &y, &w, &h, hwnd)
    isMax := (x = L && y = T && w = W && h = H)
    if (isMax && prevFrames.Has(hwnd)) {
        f := prevFrames[hwnd]
        WinMove(f.x, f.y, f.w, f.h, hwnd)
        prevFrames.Delete(hwnd)
    } else {
        prevFrames[hwnd] := {x: x, y: y, w: w, h: h}
        WinMove(L, T, W, H, hwnd)
    }
    ExitMode()
}

; Side-by-side: active window left, next visible window right (windows.lua "v")
v:: {
    hwnd := WinExist("A")
    if !hwnd {
        ExitMode()
        return
    }
    other := 0
    for h in WinGetList() {
        if (h != hwnd && WinGetMinMax(h) != -1 && DllCall("IsWindowVisible", "Ptr", h)
            && WinGetTitle(h) != "") {
            other := h
            break
        }
    }
    WorkAreaFor(hwnd, &L, &T, &W, &H)
    WinMove(L, T, W // 2, H, hwnd)
    if other
        WinMove(L + W // 2, T, W // 2, H, other)
    ExitMode()
}

; Virtual desktops ("spaces"). 1-9 switch; Shift+1-9 move active window there.
; (Written as static hotkeys so the #HotIf mode guard applies — the Hotkey()
;  function would ignore the directive and bind the digits globally.)
1:: GoToDesktop(1)
2:: GoToDesktop(2)
3:: GoToDesktop(3)
4:: GoToDesktop(4)
5:: GoToDesktop(5)
6:: GoToDesktop(6)
7:: GoToDesktop(7)
8:: GoToDesktop(8)
9:: GoToDesktop(9)
+1:: MoveActiveToDesktop(1)
+2:: MoveActiveToDesktop(2)
+3:: MoveActiveToDesktop(3)
+4:: MoveActiveToDesktop(4)
+5:: MoveActiveToDesktop(5)
+6:: MoveActiveToDesktop(6)
+7:: MoveActiveToDesktop(7)
+8:: MoveActiveToDesktop(8)
+9:: MoveActiveToDesktop(9)

; Move window to the next / previous monitor (windows.lua "]" / "[")
]:: MoveToAdjacentMonitor(1)
[:: MoveToAdjacentMonitor(-1)

#HotIf  ; end window mode

GoToDesktop(n) {
    VDA.GoTo(n - 1)
    ExitMode()
}

MoveActiveToDesktop(n) {
    VDA.MoveWindow(WinExist("A"), n - 1)
    ExitMode()
}

MoveToAdjacentMonitor(dir) {
    hwnd := WinExist("A")
    count := MonitorGetCount()
    if (!hwnd || count < 2) {
        ExitMode()
        return
    }
    ; Find current monitor index from window center.
    WinGetPos(&wx, &wy, &ww, &wh, hwnd)
    cx := wx + ww // 2, cy := wy + wh // 2
    cur := MonitorGetPrimary()
    Loop count {
        MonitorGetWorkArea(A_Index, &ml, &mt, &mr, &mb)
        if (cx >= ml && cx < mr && cy >= mt && cy < mb) {
            cur := A_Index
            break
        }
    }
    target := Mod(cur - 1 + dir + count, count) + 1
    MonitorGetWorkArea(target, &ml, &mt, &mr, &mb)
    WinMove(ml + (mr - ml - ww) // 2, mt + (mb - mt - wh) // 2, , , hwnd)
    ExitMode()
}
