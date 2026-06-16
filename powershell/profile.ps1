# PowerShell profile — equivalent of common/.zshrc + mac/.zprofile.mac
# Symlinked to $PROFILE by powershell/setup.ps1

# ─── Prompt ───────────────────────────────────────────────────────────────────

function prompt {
    $path = $ExecutionContext.SessionState.Path.CurrentLocation.Path
    $path = $path -replace [regex]::Escape($HOME), "~"
    "$path -> "
}

# ─── Environment ─────────────────────────────────────────────────────────────

$env:EDITOR = "nvim"
# Lets nvim (and other XDG-aware tools) find configs in ~/.config even on Windows
$env:XDG_CONFIG_HOME = "$HOME/.config"

$env:PATH = "$HOME\.local\bin;$HOME\bin;" + $env:PATH

# 1Password SSH agent — enable in 1Password: Settings -> Developer -> SSH Agent
# $env:SSH_AUTH_SOCK = "\\.\pipe\openssh-ssh-agent"

# ─── Aliases ─────────────────────────────────────────────────────────────────

Set-Alias g git
Set-Alias j jj

# ─── PSReadLine ──────────────────────────────────────────────────────────────

Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -HistorySearchCursorMovesToEnd

# History substring search on up/down (matches zsh config)
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# ─── Completions ─────────────────────────────────────────────────────────────

if (Get-Command jj -ErrorAction SilentlyContinue) {
    jj util completion powershell | Invoke-Expression
}
