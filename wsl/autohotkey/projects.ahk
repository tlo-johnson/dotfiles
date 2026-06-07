; ============================================================
; Project switcher  (Hyper+R ; mirrors hammerspoon/projects.lua + hs.chooser)
; ============================================================
;
; A global search-box + filtered list, like the macOS hs.chooser — but built
; entirely on the Windows side:
;   * reads projects.txt (next to the scripts) for folders to scan/add
;   * enumerates subfolders over \\wsl$\<distro>\... with native Windows file
;     APIs — NO wsl.exe call to build the list
;   * on select, ONE wsl.exe call switches/creates the project's tmux session,
;     then focuses the terminal — the only unavoidable WSL touch.
;
; Physical R is Dvorak "p". Adjust TERM_EXE if you don't use Windows Terminal.
;
; projects.txt format (one entry per line):
;   \\wsl$\Ubuntu\home\you\code        scan immediate subdirectories
;   =\\wsl$\Ubuntu\home\you\dotfiles   add this path directly
;   !node_modules                      ignore dirs whose name matches
;   # comment

global PROJ_CONFIG  := A_ScriptDir "\projects.txt"
global PROJ_RECENTS := A_ScriptDir "\projects-recents.txt"
global TERM_EXE     := "WindowsTerminal.exe"

global projGui   := ""
global projLV    := ""
global projEdit  := ""
global projChoices := []      ; array of {name, unc, distro, linux}

#HotIf hyperMode
*p:: {
    global hyperUsed
    hyperUsed := true
    ; Leave hyperMode on: while Caps stays held the hyper layer keeps driving the
    ; chooser (Hyper+L/K = up/down, Hyper+F = accept). The chooser sends no keys,
    ; so there's nothing to clear it for.
    ShowProjectChooser()
}
#HotIf

; ---- Config + scanning (all Windows-side) ----------------------------------
LoadProjects() {
    scans := [], directs := [], ignores := []
    if FileExist(PROJ_CONFIG) {
        for line in StrSplit(FileRead(PROJ_CONFIG, "UTF-8"), "`n", "`r") {
            line := Trim(line)
            if (line = "" || SubStr(line, 1, 1) = "#" || SubStr(line, 1, 1) = ";")
                continue
            if (SubStr(line, 1, 1) = "!")
                ignores.Push(StrLower(SubStr(line, 2)))
            else if (SubStr(line, 1, 1) = "=")
                directs.Push(SubStr(line, 2))
            else
                scans.Push(line)
        }
    }

    seen := Map(), out := []
    isIgnored(name) {
        for pat in ignores
            if (StrLower(name) = pat)
                return true
        return false
    }
    add(unc) {
        unc := RTrim(unc, "\")
        if (unc = "" || seen.Has(unc))
            return
        name := RegExReplace(unc, ".*\\")
        if isIgnored(name)
            return
        info := UncToWsl(unc)
        if (info.distro = "")        ; not a \\wsl$ path; skip
            return
        seen[unc] := true
        out.Push({name: name, unc: unc, distro: info.distro, linux: info.linux})
    }

    ; recents first (only if still present), then direct, then scanned children
    for unc in ReadRecents()
        if InStr(FileExist(unc), "D")
            add(unc)
    for unc in directs
        if InStr(FileExist(unc), "D")
            add(unc)
    for base in scans
        Loop Files, RTrim(base, "\") "\*", "D"
            add(A_LoopFileFullPath)
    return out
}

; \\wsl$\Ubuntu\home\you\code  ->  {distro:"Ubuntu", linux:"/home/you/code"}
UncToWsl(unc) {
    body := ""
    if (SubStr(unc, 1, 7) = "\\wsl$\")
        body := SubStr(unc, 8)
    else if (SubStr(unc, 1, 16) = "\\wsl.localhost\")
        body := SubStr(unc, 17)
    else
        return {distro: "", linux: ""}
    parts := StrSplit(Trim(body, "\"), "\")
    if (parts.Length < 1 || parts[1] = "")
        return {distro: "", linux: ""}
    distro := parts.RemoveAt(1)
    linux := "/" Join(parts, "/")
    return {distro: distro, linux: linux}
}

ReadRecents() {
    arr := []
    if FileExist(PROJ_RECENTS)
        for line in StrSplit(FileRead(PROJ_RECENTS, "UTF-8"), "`n", "`r")
            if (Trim(line) != "")
                arr.Push(Trim(line))
    return arr
}

RecordRecent(unc) {
    keep := [unc]
    for line in ReadRecents()
        if (line != unc && keep.Length < 50)
            keep.Push(line)
    try FileDelete(PROJ_RECENTS)
    FileAppend(Join(keep, "`n") "`n", PROJ_RECENTS, "UTF-8")
}

Join(arr, sep) {
    s := ""
    for i, v in arr
        s .= (i > 1 ? sep : "") v
    return s
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
    if IsObject(projGui)
        try projGui.Destroy()
    projGui := "", projLV := "", projEdit := ""
}

; Case-insensitive subsequence match (cheap fuzzy).
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
    for c in projChoices
        if (q = "" || Subseq(q, StrLower(c.name)) || InStr(StrLower(c.linux), q))
            projLV.Add(, c.name, c.distro ": " c.linux)
    projLV.ModifyCol(1, 160)
    projLV.ModifyCol(2, 390)
    projLV.Opt("+Redraw")
    if (projLV.GetCount())
        projLV.Modify(1, "Select Focus Vis")
}

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

; Map the visible (filtered) row back to its choice by name+meta.
ChoiceForRow(row) {
    global projLV, projChoices
    name := projLV.GetText(row, 1)
    meta := projLV.GetText(row, 2)
    for c in projChoices
        if (c.name = name && (c.distro ": " c.linux) = meta)
            return c
    return ""
}

AcceptProject() {
    global projLV
    if !IsObject(projLV)
        return
    if (!projLV.GetCount())
        return
    row := projLV.GetNext(0, "F")
    if (!row)
        row := 1
    c := ChoiceForRow(row)
    CloseChooser()
    if IsObject(c)
        SwitchProject(c)
}

; ---- The one unavoidable WSL touch -----------------------------------------
SwitchProject(c) {
    global TERM_EXE
    RecordRecent(c.unc)
    sess := StrReplace(c.name, ".", "_")
    sh := "tmux has-session -t '=" sess "' 2>/dev/null"
        . " || tmux new-session -ds '" sess "' -c '" c.linux "';"
        . " tmux switch-client -t '" sess "'"
    q := Chr(34)
    Run("wsl.exe -d " c.distro " bash -lc " q sh q, , "Hide")
    if WinExist("ahk_exe " TERM_EXE)
        WinActivate
}

; ---- Navigation while the chooser is focused -------------------------------
#HotIf WinActive("TLO Projects ahk_class AutoHotkeyGUI")
Up::    MoveSel(-1)
Down::  MoveSel(1)
Enter:: AcceptProject()
#HotIf
