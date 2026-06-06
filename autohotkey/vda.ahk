; ============================================================
; VirtualDesktopAccessor.dll wrapper  (Windows "spaces")
; ============================================================
;
; Windows virtual desktops are the equivalent of macOS Spaces (hs.spaces in
; windows.lua). AHK has no native API for them, so we lean on the community
; DLL: https://github.com/Ciantic/VirtualDesktopAccessor
;
; Download a build that matches your Windows version and drop it next to this
; script (or edit VDA.DllPath below). All indices are 0-BASED in the DLL; the
; windows.ahk callers pass 1-based numbers and subtract 1.
;
; Everything is guarded: if the DLL is missing or an export can't be found,
; VDA.Ok stays false and desktop switching is silently disabled — the rest of
; the script keeps working.

class VDA {
    static DllPath := A_ScriptDir "\VirtualDesktopAccessor.dll"
    static hModule := 0
    static Ok := false

    static __New() {
        if !FileExist(this.DllPath)
            return
        this.hModule := DllCall("LoadLibrary", "Str", this.DllPath, "Ptr")
        this.Ok := this.hModule != 0
    }

    ; Resolve an exported function pointer by name (cached implicitly by Windows).
    static Proc(name) {
        if !this.Ok
            return 0
        return DllCall("GetProcAddress", "Ptr", this.hModule, "AStr", name, "Ptr")
    }

    static Count() {
        p := this.Proc("GetDesktopCount")
        return p ? DllCall(p, "Int") : 0
    }

    static Current() {
        p := this.Proc("GetCurrentDesktopNumber")
        return p ? DllCall(p, "Int") : 0
    }

    ; Switch to desktop n (0-based). Creates missing desktops up to n if possible.
    static GoTo(n) {
        if !this.Ok
            return false
        this.EnsureExists(n)
        p := this.Proc("GoToDesktopNumber")
        if !p
            return false
        DllCall(p, "Int", n)
        return true
    }

    ; Move a window to desktop n (0-based).
    static MoveWindow(hwnd, n) {
        if !this.Ok
            return false
        this.EnsureExists(n)
        p := this.Proc("MoveWindowToDesktopNumber")
        if !p
            return false
        DllCall(p, "Ptr", hwnd, "Int", n)
        return true
    }

    ; Create desktops until index n is valid (best effort).
    static EnsureExists(n) {
        create := this.Proc("CreateDesktop")
        if !create
            return
        while (this.Count() <= n)
            DllCall(create, "Int")
    }
}
