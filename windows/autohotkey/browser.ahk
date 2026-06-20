; ============================================================
; Browser bindings (Chrome, Firefox, Edge)
; ============================================================
;
; DVORAK NOTE: physical key -> Dvorak char:
;   X -> q    (close tab)

IsBrowser() {
    return WinActive("ahk_exe chrome.exe")
        || WinActive("ahk_exe firefox.exe")
        || WinActive("ahk_exe msedge.exe")
}

#HotIf IsBrowser()

*q:: Send "^w"                ; physical X -> Ctrl+W (close tab)

#HotIf
