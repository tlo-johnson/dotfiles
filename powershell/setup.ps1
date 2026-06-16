#Requires -Version 7
# setup.ps1 — bootstrap a native Windows machine.
# Run from the repo root or the powershell/ directory.

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path $PSScriptRoot -Parent

# ─── Guards ───────────────────────────────────────────────────────────────────

# Symlinks on Windows require Developer Mode or admin rights.
function Test-SymlinkCapable {
    $testFile = [System.IO.Path]::GetTempFileName()
    $testLink = $testFile + ".link"
    try {
        New-Item -ItemType SymbolicLink -Path $testLink -Target $testFile -ErrorAction Stop | Out-Null
        Remove-Item $testLink, $testFile -ErrorAction SilentlyContinue
        return $true
    } catch {
        Remove-Item $testFile -ErrorAction SilentlyContinue
        return $false
    }
}

if (-not (Test-SymlinkCapable)) {
    Write-Error @"
Cannot create symbolic links.
Enable Developer Mode (Settings -> System -> For developers -> Developer Mode)
or re-run this script as Administrator.
"@
    exit 1
}

# ─── Packages ─────────────────────────────────────────────────────────────────

$packages = @(
    "Git.Git",
    "Neovim.Neovim",
    "BurntSushi.ripgrep.MSVC",
    "junegunn.fzf",
    "jqlang.jq",
    "OpenJS.NodeJS.LTS",
    "martinvonz.jj",
    "AutoHotkey.AutoHotkey",
    "Microsoft.WindowsTerminal"
)

Write-Host "Installing packages via winget..."
foreach ($pkg in $packages) {
    $listed = winget list --id $pkg --accept-source-agreements 2>$null | Select-String $pkg
    if ($listed) {
        Write-Host "  [ok] $pkg"
    } else {
        Write-Host "  Installing $pkg ..."
        winget install --id $pkg --accept-package-agreements --accept-source-agreements
    }
}

# ─── Symlink helper ───────────────────────────────────────────────────────────

function Link-Config {
    param([string]$Source, [string]$Target)
    $parent = Split-Path $Target -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    if (Test-Path $Target -PathType Any) {
        $item = Get-Item $Target -Force
        if ($item.LinkType -eq "SymbolicLink") {
            Remove-Item $Target -Force
        } else {
            Write-Error "  Cannot link — target exists and is not a symlink: $Target"
            return
        }
    }
    New-Item -ItemType SymbolicLink -Path $Target -Target $Source | Out-Null
    Write-Host "  Linked: $Source"
    Write-Host "       -> $Target"
}

# ─── Common config symlinks ───────────────────────────────────────────────────

Write-Host ""
Write-Host "Linking configs..."

Link-Config "$RepoRoot\common\.gitconfig"    "$HOME\.gitconfig"
Link-Config "$RepoRoot\common\.jjconfig.toml" "$HOME\.jjconfig.toml"
Link-Config "$RepoRoot\common\nvim"           "$HOME\AppData\Local\nvim"

# ─── Windows-specific symlinks ────────────────────────────────────────────────

# PowerShell 7 profile
Link-Config "$RepoRoot\powershell\profile.ps1" $PROFILE

# Windows Terminal — upsert color scheme
Write-Host ""
Write-Host "Configuring Windows Terminal..."
& "$PSScriptRoot\windows-terminal.ps1"

# ─── Bootstrap ~/.gitconfig.specific ─────────────────────────────────────────

$specificConfig = "$HOME\.gitconfig.specific"
if (-not (Test-Path $specificConfig)) {
    Copy-Item "$RepoRoot\common\.gitconfig.specific.template" $specificConfig
    Write-Host ""
    Write-Host "Created ~/.gitconfig.specific from template."
    Write-Host "Fill in your email, SSH signing key, and 1Password SSH agent path."
}

# ─── AutoHotkey scripts ───────────────────────────────────────────────────────

Write-Host ""
Write-Host "Syncing AutoHotkey scripts..."

$ahkSrc  = "$RepoRoot\wsl\autohotkey"
$ahkDest = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "autohotkey"

New-Item -ItemType Directory -Path $ahkDest -Force | Out-Null
Copy-Item "$ahkSrc\*.ahk" "$ahkDest\" -Force
Copy-Item "$ahkSrc\projects.txt.example" "$ahkDest\" -Force -ErrorAction SilentlyContinue

if (-not (Test-Path "$ahkDest\projects.txt") -and (Test-Path "$ahkSrc\projects.txt.example")) {
    Copy-Item "$ahkSrc\projects.txt.example" "$ahkDest\projects.txt"
    Write-Host "  Created projects.txt from template — edit it to list your project directories."
}

Write-Host "  Synced wsl\autohotkey\*.ahk -> $ahkDest"

# ─── AutoHotkey startup shortcut ─────────────────────────────────────────────

$startupDir   = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$shortcutPath = "$startupDir\main.ahk.lnk"
$ahkMain      = "$ahkDest\main.ahk"

$shell    = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $ahkMain
$shortcut.Save()
Write-Host "  Added main.ahk to Windows startup folder"

# ─── Manual steps ─────────────────────────────────────────────────────────────

Write-Host @"

Setup complete. Remaining manual steps:

  1. SSH commit signing (1Password)
     Install 1Password, then: Settings -> Developer -> SSH Agent -> Enable
     Fill in ~/.gitconfig.specific with your key details.

  2. Virtual desktop switching (AHK)
     Download VirtualDesktopAccessor.dll from:
       https://github.com/Ciantic/VirtualDesktopAccessor/releases
     Drop it in: $ahkDest

  3. Projects switcher
     projects.ahk requires WSL + tmux and will not work on this machine.

  4. Windows Terminal
     Set PowerShell (pwsh.exe) as the default profile.

  5. Vimium
     Import settings from mac/vimium-options.json in the Vimium extension options.

  6. Start AutoHotkey
     Run $ahkMain now, or restart to load it automatically from the startup folder.
"@
