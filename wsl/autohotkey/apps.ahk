; ============================================================
; App launcher sub-mode  (Hyper+Space ; mirrors hammerspoon/apps.lua)
; ============================================================
;
; Entered via EnterMode("app", ...) in hyper.ahk. Keys are the same letters as
; the macOS launcher (apps.lua), each focuses the app if running else launches
; it. ActivateOrRun (main.ahk) clears the mode afterward.
;
; Adjust exe / command names to match your installs.

#HotIf (mode = "app")

Escape:: ExitMode()

t:: ActivateOrRun("WindowsTerminal.exe", "wt.exe")          ; terminal  (was Ghostty)
b:: ActivateOrRun("chrome.exe",          "chrome.exe")      ; browser
s:: ActivateOrRun("slack.exe",           "slack.exe")       ; Slack
w:: ActivateOrRun("WhatsApp.exe",        "WhatsApp.exe")    ; WhatsApp
f:: ActivateOrRun("explorer.exe",        "explorer.exe")    ; File Explorer (was Finder)
c:: ActivateOrRun("ChatGPT.exe",         "ChatGPT.exe")     ; ChatGPT (if installed)

#HotIf  ; end app mode
