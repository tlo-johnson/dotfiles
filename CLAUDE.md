# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Last updated: 2026-06-07**

If today's date is more than one month after the last updated date above, prompt the user to run `/init` to refresh this file before proceeding.

## What this repo is

Personal cross-platform dotfiles for Tolu A. — runs on **macOS** and **Linux / WSL**, with the two implementations kept fully separate. Top-level layout:

- `common/` — configs shared by both OSes (`nvim/`, `.zshrc`, `.zprofile`, `.gitconfig`, `.tmux.conf`, `.jjconfig.toml`) plus `link.sh`, a shared symlink helper sourced by both setups.
- `mac/` — macOS only: `Brewfile`, `hammerspoon/`, `karabiner.json`, `ghostty/`, `vimium-options.json`, `.zprofile.mac`, and `mac/setup`.
- `wsl/` — WSL/Windows only: `autohotkey/` (the AutoHotkey port), `sync-ahk`, and `wsl/setup`.

All config files are symlinked into place by the per-OS setup. No build steps, tests, or CI — changes take effect immediately after the symlinks resolve.

## Setup

```sh
./mac/setup      # on macOS
./wsl/setup      # on WSL
```

There is no root dispatcher — each OS has its own self-contained setup. Both `source common/link.sh` (which defines the `link()` helper, symlinks the shared `common/` configs, and bootstraps `~/.gitconfig.specific` from the template), then do their own: `mac/setup` installs Homebrew packages (Brewfile) + jenv and links the GUI configs (Hammerspoon, Karabiner, Ghostty, `.zprofile.mac`); `wsl/setup` installs core tools via apt and runs `wsl/sync-ahk` to push the AutoHotkey scripts to the Windows host.

`common/.zshrc` / `common/.zprofile` source their OS variant via a `case "$OSTYPE"` branch (`$HOME/.zshrc.mac`/`.zprofile.mac` vs `.zshrc.wsl`/`.zprofile.wsl`). Present today: `mac/.zprofile.mac` and `wsl/.zshrc.wsl` (the latter puts `wsl/` scripts like `sync-ahk` on PATH).

After setup, several manual steps are required (differ by OS — e.g. 1Password SSH agent, Hammerspoon/Karabiner/Vimium, Mission Control on macOS; jj/node/bun + SSH agent + Windows-host AutoHotkey on WSL) — see README.md.

## Symlink map

`common/link.sh` (both OSes):

| Config | Symlinked to |
|--------|-------------|
| `common/.zshrc`, `common/.zprofile` | `$HOME/` |
| `common/.gitconfig` | `$HOME/` |
| `common/.jjconfig.toml` | `$HOME/` |
| `common/.tmux.conf` | `$HOME/` |
| `common/nvim/` | `~/.config/nvim` |

`mac/setup` (macOS only):

| Config | Symlinked to |
|--------|-------------|
| `mac/.zprofile.mac` | `$HOME/.zprofile.mac` |
| `mac/ghostty/` | `~/.config/ghostty` |
| `mac/hammerspoon/` | `~/.hammerspoon` |
| `mac/karabiner.json` | `~/.config/karabiner/karabiner.json` |

`wsl/autohotkey/` is **not** symlinked — `wsl/sync-ahk` copies it to the Windows host (`Documents\autohotkey\`).

## Key components

**Hammerspoon** (`mac/hammerspoon/`) — Lua automation for macOS. `init.lua` loads all modules. Key modules:
- `windows.lua` — PaperWM tiling (wraps `~/development/PaperWM.spoon`, symlinked into `mac/hammerspoon/Spoons/`)
- `projects.lua` — project switcher (Hyper+R); reads `~/.config/tlo/projects/dirs`, manages tmux sessions and space switching
- `apps.lua` — app launcher (Hyper+Space)
- `bluetooth.lua` — Bluetooth device switcher (Hyper+N)
- `mic.lua` — mic mute toggle
- `config.lua` — config reload layer (Hyper+Z)
- `keypad.lua` — modal numpad layer (Hyper+A)

**Neovim** (`common/nvim/`) — managed by lazy.nvim. Plugins in `lua/plugins/`:
- LSP: `nvim-lspconfig.lua`, `nvim-jdtls.lua` (Java), `nvim-java.lua`; gopls and lua-ls also configured
- Completion: `blink.cmp.lua`
- Formatting: `conform.nvim.lua`
- Fuzzy finding: `telescope.lua`
- Colorscheme: catppuccin with transparent background
- Tmux pane navigation: `vim-tmux-navigator.lua` (Ctrl+H/N/T/S)

**Jujutsu** (`jj/config.toml`) — used alongside git. Common aliases: `j l` (log last 10), `j s` (status), `j d` (diff), `j m "msg"` (describe), `j n` (new change), `j sq` (squash into parent), `j ps` / `j pl` (push/fetch).

**Git** — SSH commit signing via 1Password agent. `~/.gitconfig-specific` is included for machine-specific overrides (not tracked here).

**Karabiner** (`mac/karabiner.json`) — Caps Lock remapped as Hyper key (tap = Escape). Defines the Hyper layer and all modal sublayers (windows, apps, projects, config, keypad).

**AutoHotkey** (`wsl/autohotkey/`) — Windows-host equivalent of Karabiner + Hammerspoon for WSL (the macOS stack runs at OS level, so its WSL analog runs on Windows, not inside WSL). AutoHotkey v2, loaded via `main.ahk`, which `#Include`s per-feature modules paralleling the Hammerspoon ones:
- `hyper.ahk` — Caps=Hyper layer + Alt→Ctrl + shift-toggle-caps (≈ `karabiner.json`)
- `windows.ahk` + `vda.ahk` — window tiling (halves/quarters/maximize) + virtual-desktop "spaces" via VirtualDesktopAccessor.dll (≈ `windows.lua`)
- `apps.ahk` — app launcher (≈ `apps.lua`); `keypad.ahk` — numpad (≈ `keypad.lua`); `mic.ahk` — mic toggle + indicator (≈ `mic.lua`)
- `projects.ahk` — Hyper+R chooser GUI (≈ `projects.lua`/`hs.chooser`). Windows-native: reads `projects.txt` (Windows-side; template `projects.txt.example`) and scans the listed folders over `\\wsl$\<distro>\…` with Windows file APIs — no `wsl.exe` to list. Selecting fires one `wsl.exe … tmux` call to switch/create the session (the only WSL touch).

Sub-modes are sticky AHK globals (`mode`) instead of Karabiner's F13–F18 → Hammerspoon modal indirection. Layout is Dvorak: triggers bind the Dvorak char on the intended physical key (table in `hyper.ahk`). Not symlinked — copied to the Windows host via `wsl/sync-ahk` (finds the Windows Documents folder, copies `wsl/autohotkey/*.ahk` + bootstraps `projects.txt`); `wsl/setup` runs it automatically.

## Project switcher config format

`~/.config/tlo/projects/dirs` uses ini-style sections:

```
[directories]
$HOME/code          # scan for immediate subdirectories
=$HOME/dotfiles     # add this path directly
!node_modules       # ignore pattern
$HOME/work -> 2     # assign to macOS space 2
```
