; ============================================================
; Mic mute toggle + indicator  (Ctrl+Shift+M ; mirrors hammerspoon/mic.lua)
; ============================================================
;
; Toggles the capture device's mute and shows a persistent "MIC IS ON" badge
; (top-left, red bar on dark bg) while the mic is LIVE — same affordance as the
; Hammerspoon canvas. Was Cmd+Shift+M on macOS; Ctrl+Shift+M here.
;
; NOTE: AHK has no "default capture device" selector, so set MicDevice to your
; recording device's name (Sound settings > Input). The on-screen badge always
; works even if the mute call can't find the device.

global MicDevice := "Microphone"
global micMuted  := false
global micGui    := MakeMicGui()

MakeMicGui() {
    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")  ; E0x20 = click-through
    g.BackColor := "141414"
    g.SetFont("s11 Bold cWhite", "Segoe UI")
    g.Add("Text", "x8 y8 w4 h24 BackgroundE62626")        ; red "live" bar
    g.Add("Text", "x20 y10 w92 h20", "MIC IS ON")
    return g
}

UpdateMicAlert() {
    global micGui, micMuted
    if micMuted
        micGui.Hide()
    else
        micGui.Show("x12 y12 w120 h40 NoActivate")
}

ToggleMic(*) {
    global micMuted, MicDevice
    try {
        SoundSetMute(-1, , MicDevice)          ; -1 = toggle
        micMuted := SoundGetMute(, MicDevice)
    } catch {
        micMuted := !micMuted                  ; best effort if the device name doesn't resolve
    }
    UpdateMicAlert()
}

; Initialize from the actual device state when the script loads.
try micMuted := SoundGetMute(, MicDevice)
UpdateMicAlert()

^+m:: ToggleMic()
