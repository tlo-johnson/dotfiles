; ============================================================
; Project switcher  (Hyper+R ; mirrors hammerspoon/projects.lua + hs.chooser)
; ============================================================
;
; Renders a global search-box + filtered list GUI, just like the macOS
; hs.chooser. Choices come from the WSL side (`tlo-projects --list`); selecting
; one calls `tlo-projects --switch <path>` in WSL to switch/create its tmux
; session, then focuses the terminal.
;
; Physical R is Dvorak "p". Adjust TERM_EXE if you don't use Windows Terminal.

global TERM_EXE    := "WindowsTerminal.exe"
global projGui     := ""
global projLV      := ""
global projEdit    := ""
global projChoices := []

#HotIf hyperMode
*p:: {
    global hyperMode, hyperUsed
    hyperUsed := true
    hyperMode := false
    ShowProjectChooser()
}
#HotIf

; ---- Data: ask WSL for the project list ------------------------------------
LoadProjects() {
    arr := []
    out := ""
    try {
        shell := ComObject("WScript.Shell")
        exec  := shell.Exec('wsl.exe -e zsh -lc "~/.local/bin/tlo-projects --list"')
        out   := exec.StdOut.ReadAll()
    } catch {
        return arr
    }
    for line in StrSplit(out, "`n", "`r") {
        if (line = "")
            continue
        parts := StrSplit(line, "`t")
        if (parts.Length >= 2)
            arr.Push({name: parts[1], path: parts[2]})
    }
    return arr
}

; ---- GUI -------------------------------------------------------------------
ShowProjectChooser() {
    global projGui, projLV, projEdit, projChoices
    CloseChooser()
    projChoices := LoadProjects()

    projGui := Gui("+AlwaysOnTop -MinimizeBox +OwnDialogs", "TLO Projects")
    projGui.SetFont("s11", "Segoe UI")
    projGui.MarginX := 10, projGui.MarginY := 10
    projEdit := projGui.Add("Edit", "w560")
    projEdit.OnEvent("Change", FilterProjects)
    projLV := projGui.Add("ListView", "w560 r14 -Multi -Hdr", ["Project", "Path"])
    projLV.OnEvent("DoubleClick", (*) => AcceptProject())
    projGui.OnEvent("Escape", (*) => CloseChooser())
    projGui.OnEvent("Close",  (*) => CloseChooser())

    FilterProjects()
    projGui.Show("AutoSize")
    projEdit.Focus()
}

CloseChooser() {
    global projGui, projLV, projEdit
    if IsObject(projGui) {
        try projGui.Destroy()
    }
    projGui := "", projLV := "", projEdit := ""
}

; Case-insensitive subsequence match (cheap fuzzy, like fzf ordering on name).
Subseq(needle, hay) {
    n := StrLen(needle)
    if (n = 0)
        return true
    i := 1
    Loop Parse hay {
        if (A_LoopField = SubStr(needle, i, 1)) {
            if (++i > n)
                return true
        }
    }
    return false
}

FilterProjects(*) {
    global projLV, projEdit, projChoices
    q := StrLower(projEdit.Value)
    projLV.Opt("-Redraw")
    projLV.Delete()
    for c in projChoices {
        if (q = "" || Subseq(q, StrLower(c.name)) || InStr(StrLower(c.path), q))
            projLV.Add(, c.name, c.path)
    }
    projLV.ModifyCol(1, 170)
    projLV.ModifyCol(2, 380)
    projLV.Opt("+Redraw")
    if (projLV.GetCount())
        projLV.Modify(1, "Select Focus Vis")
}

; Move the highlighted row while focus stays in the search box.
MoveSel(delta) {
    global projLV
    cnt := projLV.GetCount()
    if (!cnt)
        return
    cur := projLV.GetNext(0, "F")
    if (!cur)
        cur := 1
    nxt := cur + delta
    nxt := nxt < 1 ? 1 : (nxt > cnt ? cnt : nxt)
    projLV.Modify(0, "-Select -Focus")
    projLV.Modify(nxt, "Select Focus Vis")
}

AcceptProject() {
    global projLV
    if !IsObject(projLV)
        return
    row := projLV.GetNext(0, "F")
    if (!row)
        row := 1
    path := projLV.GetText(row, 2)
    CloseChooser()
    if (path = "")
        return
    q  := Chr(34), sq := Chr(39)
    Run('wsl.exe -e zsh -lc ' q '~/.local/bin/tlo-projects --switch ' sq path sq q, , "Hide")
    if WinExist("ahk_exe " TERM_EXE)
        WinActivate
}

; ---- Navigation while the chooser is focused -------------------------------
#HotIf WinActive("TLO Projects ahk_class AutoHotkeyGUI")
Up::    MoveSel(-1)
Down::  MoveSel(1)
Enter:: AcceptProject()
#HotIf
