# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Last updated: 2026-07-25**

If today's date is more than one month after the last updated date above, prompt the user to run `/init` to refresh this file before proceeding.

## What this repo is

Personal cross-platform dotfiles for Tolu A. — runs on **macOS**, **Linux / WSL**, and **native Windows**, with each OS implementation kept fully separate. Top-level layout:

- `common/` — configs shared by all OSes (`nvim/`, `.zshrc`, `.zprofile`, `.gitconfig`, `.tmux.conf`, `.jjconfig.toml`, `jj.zsh`, `zsh-completions/`, `vimium-options.json`) plus `link.sh`, a shared zsh symlink helper sourced by `mac/setup` and `wsl/setup`.
- `mac/` — macOS only: `Brewfile`, `hammerspoon/`, `karabiner.json`, `ghostty/`, `wezterm/`, `.zprofile.mac`, `bin/` (put on PATH by `.zprofile.mac`), and `mac/setup`.
- `wsl/` — WSL/Windows only: `autohotkey/` (the AutoHotkey port), `sync-ahk`, and `wsl/setup`.
- `windows/` — native Windows (no WSL) only: `setup.ps1`, `profile.ps1` (PowerShell profile), `windows-terminal.ps1`. Reuses `wsl/autohotkey/*.ahk` directly (AutoHotkey already runs on Windows either way) and `common/` configs; it does **not** source `common/link.sh` (that's zsh, unusable from PowerShell) — `windows/setup.ps1` reimplements the same symlink logic natively. The WSL-only project switcher (needs WSL + tmux) does not work under this path.

All config files are symlinked into place by the per-OS setup. No build steps, tests, or CI — changes take effect immediately after the symlinks resolve.

## Setup

```sh
./mac/setup          # on macOS
./wsl/setup          # on WSL
./windows/setup.ps1  # on native Windows (PowerShell 7)
```

There is no root dispatcher — each OS has its own self-contained setup. `mac/setup` and `wsl/setup` both `source common/link.sh` (which defines the `link()` helper, symlinks the shared `common/` configs, and bootstraps `~/.gitconfig.specific` from the template), then do their own: `mac/setup` installs Homebrew packages (Brewfile) + jenv and links the GUI configs (Hammerspoon, Karabiner, Ghostty, WezTerm, `.zprofile.mac`); `wsl/setup` installs core tools via apt and runs `wsl/sync-ahk` to push the AutoHotkey scripts to the Windows host. `windows/setup.ps1` is independent of `common/link.sh`: it installs packages via winget, symlinks `common/` configs + its own PowerShell profile/Windows Terminal scheme, and copies (not symlinks) the AutoHotkey scripts straight from `wsl/autohotkey/` to the Windows Documents folder.

`common/.zshrc` / `common/.zprofile` source their OS variant via a `case "$OSTYPE"` branch (`$HOME/.zshrc.mac`/`.zprofile.mac` vs `.zshrc.wsl`/`.zprofile.wsl`). Present today: `mac/.zprofile.mac` and `wsl/.zshrc.wsl` (the latter puts `wsl/` scripts like `sync-ahk` on PATH). Native Windows doesn't participate in this branch at all — `windows/profile.ps1` is a separate, parallel reimplementation of the same shell setup (prompt, `$EDITOR`, vi-mode readline, history search, aliases) in PowerShell, not a consumer of `common/.zshrc`.

After setup, several manual steps are required (differ by OS — e.g. 1Password SSH agent, Hammerspoon/Karabiner/Vimium, Mission Control on macOS; jj/node/bun + SSH agent + Windows-host AutoHotkey on WSL; VirtualDesktopAccessor.dll + Windows Terminal default profile on native Windows) — see README.md.

## Symlink map

`common/link.sh` (sourced by `mac/setup` and `wsl/setup`):

| Config | Symlinked to |
|--------|-------------|
| `common/.zshrc`, `common/.zprofile` | `$HOME/` |
| `common/.gitconfig` | `$HOME/` |
| `common/.jjconfig.toml` | `$HOME/` |
| `common/.tmux.conf` | `$HOME/` |
| `common/nvim/` | `~/.config/nvim` |
| `common/zsh-completions/_j` | `~/bin/_j` |

`mac/setup` (macOS only, in addition to the above):

| Config | Symlinked to |
|--------|-------------|
| `mac/.zprofile.mac` | `$HOME/.zprofile.mac` |
| `mac/ghostty/` | `~/.config/ghostty` |
| `mac/wezterm/` | `~/.config/wezterm` |
| `mac/hammerspoon/` | `~/.hammerspoon` |
| `mac/karabiner.json` | `~/.config/karabiner/karabiner.json` |

`windows/setup.ps1` (native Windows only — reimplements symlinking itself, doesn't call `common/link.sh`):

| Config | Symlinked to |
|--------|-------------|
| `common/.gitconfig`, `common/.jjconfig.toml` | `$HOME\` |
| `common/nvim/` | `$HOME\AppData\Local\nvim` |
| `windows/profile.ps1` | `$PROFILE` |

`wsl/autohotkey/` is **not** symlinked on either Windows path — `wsl/sync-ahk` (from WSL) and `windows/setup.ps1` (native Windows) both just *copy* `*.ahk` to the Windows Documents folder.

## Key components

**Terminal** — mid-migration from Ghostty to WezTerm (`mac/wezterm/wezterm.lua`, Catppuccin Mocha); both configs are still symlinked by `mac/setup` and Ghostty's is retained, but WezTerm is the active default. This matters beyond styling: `mac/hammerspoon/projects.lua`'s project switcher targets the WezTerm app/bundle ID specifically (finding/focusing/launching `com.github.wez.wezterm`) when switching tmux sessions, not a generic "current terminal" — so terminal-switching logic in Hammerspoon assumes WezTerm.

**Hammerspoon** (`mac/hammerspoon/`) — Lua automation for macOS. `init.lua` loads all modules. Key modules:
- `windows.lua` — custom window tiling (move/resize focused window into halves/quadrants) — a hand-rolled tiler, not a Spoon/plugin like PaperWM
- `projects.lua` — project switcher; reads `~/.config/tlo/projects/dirs`, manages tmux sessions (via WezTerm) and space switching
- `tabs.lua` / `browser-tab-store.lua` — browser tab switcher; store is fed live by browser extensions, `tabs.lua` renders the chooser
- `switcher.lua` — Hyper+R opens the project switcher, Hyper+E opens the browser tab switcher
- `apps.lua` — app launcher (Hyper+Space), including a "capture note" action that shells out to `mac/hammerspoon/scripts/capture`
- `bluetooth.lua` — Bluetooth device switcher (Hyper+N)
- `config.lua` — config reload layer (Hyper+Z)
- `keypad.lua` — modal numpad layer (Hyper+A)
- `utils.lua` — shared helper (not a mode itself): `createModal` wraps `hs.hotkey.modal` with a small on-screen alert (canvas-based), used by every modal module above so entering/exiting a mode is visually confirmed

**Neovim** (`common/nvim/`) — managed by lazy.nvim. Plugins in `lua/plugins/`:
- LSP: `nvim-lspconfig.lua`, `nvim-jdtls.lua` (Java), `nvim-java.lua`; gopls and lua-ls also configured
- Completion: `blink.cmp.lua`
- Formatting: `conform.nvim.lua`
- Fuzzy finding: `telescope.lua`
- Syntax/motions: `nvim-treesitter.lua` (main branch + `nvim-treesitter-textobjects`, custom function/class motions that skip over comments)
- File explorer: `oil.nvim.lua`
- Markdown rendering: `render-markdown.lua` (present but currently `enabled = false`)
- Colorscheme: catppuccin with transparent background
- Tmux pane navigation: `vim-tmux-navigator.lua` (Ctrl+H/N/T/S)

**Jujutsu** — config at `common/.jjconfig.toml`, symlinked to `$HOME/.jjconfig.toml` by `common/link.sh`/`windows/setup.ps1`. `common/jj.zsh` (sourced by `.zshrc`) defines a `j` wrapper around the `jj` CLI: `j m` (describe, with `--pair`/`--pair-alias` for co-author aliasing via `jj-pair`), `j pl` (`jj-pull`: fetch, and if `@` is empty, auto-advance to the updated bookmark), `j ps` (`jj-push`: create/update a bookmark at the right revision and push it), and passes everything else straight through to `jj`. `common/zsh-completions/_j` provides completion for `j`, including dynamic bookmark and pair-alias completion.

**Git** — SSH commit signing via 1Password agent. `~/.gitconfig-specific` is included for machine-specific overrides (not tracked here).

**Karabiner** (`mac/karabiner.json`) — Caps Lock remapped as Hyper key (tap = Escape). Defines the Hyper layer and all modal sublayers (windows, apps, projects, config, keypad).

**AutoHotkey** (`wsl/autohotkey/`) — Windows-host equivalent of Karabiner + Hammerspoon, used by *two* separate setups: as the WSL guest's Windows-side companion (Hyper layer runs on the OS level, so its WSL analog must run on the Windows host, not inside WSL), and, unchanged, as the entire keyboard-automation layer for a native Windows machine via `windows/setup.ps1` (no WSL bridge needed there — AHK already runs on Windows). AutoHotkey v2, loaded via `main.ahk`, which `#Include`s per-feature modules paralleling the Hammerspoon ones:
- `hyper.ahk` — Caps=Hyper layer + Alt→Ctrl + shift-toggle-caps (≈ `karabiner.json`)
- `windows.ahk` + `vda.ahk` — window tiling (halves/quarters/maximize) + virtual-desktop "spaces" via VirtualDesktopAccessor.dll (≈ `windows.lua`)
- `apps.ahk` — app launcher (≈ `apps.lua`); `keypad.ahk` — numpad (≈ `keypad.lua`)
- `projects.ahk` — Hyper+R chooser GUI (≈ `projects.lua`/`hs.chooser`). Windows-native: reads `projects.txt` (Windows-side; template `projects.txt.example`) and scans the listed folders using Windows file APIs — over `\\wsl$\<distro>\…` on the WSL path, or local paths on the native-Windows path. Selecting fires one `wsl.exe … tmux` call, so **this action only works from the WSL setup** — on native Windows (`windows/setup.ps1`) there is no WSL/tmux to switch to, and `windows/setup.ps1`'s own manual-steps output says as much.

Sub-modes are sticky AHK globals (`mode`) instead of Karabiner's F13–F18 → Hammerspoon modal indirection. Layout is Dvorak: triggers bind the Dvorak char on the intended physical key (table in `hyper.ahk`). Not symlinked — copied to the Windows host, either by `wsl/sync-ahk` (from a WSL guest) or directly by `windows/setup.ps1` (native Windows); `wsl/setup` runs `sync-ahk` automatically.

**Key mapping conventions** — for "what does key X do" questions, read the actual source rather than assuming (bindings change over time):
- macOS: `mac/karabiner.json` (Hyper layer + device-specific rules) dispatches via F13–F19 into `mac/hammerspoon/*.lua` modals (one file per mode: windows, apps, bluetooth, config, keypad, projects, tabs), each built with `utils.createModal`.
- Windows (both WSL and native): `wsl/autohotkey/*.ahk` mirrors the Hammerspoon breakdown file-for-file (see above), using a sticky `mode` global instead of F-key dispatch. The same files serve both the WSL-host-bridge setup and the native-Windows setup — there's no separate `windows/`-specific key-mapping code.
- The two sides (macOS vs. AHK) are kept intentionally parallel — a mapping change on one side usually wants the matching change on the other.
- The same Dvorak-based pane/arrow-navigation idiom is reused across the Hyper layer, `common/.tmux.conf` pane navigation, and nvim's vim-tmux-navigator bindings (`common/nvim/init.lua`) — check all three if changing one.

## Project switcher config format

`~/.config/tlo/projects/dirs` uses ini-style sections (this is the single source of truth for the format — README.md describes an older separate `ignore`/`spaces`-files layout that no longer matches `mac/hammerspoon/projects.lua`):

```
[directories]
$HOME/code          # scan for immediate subdirectories
=$HOME/dotfiles     # add this path directly
!node_modules       # ignore pattern
$HOME/work -> 2     # assign to macOS space 2
```

`~/.config/tlo/projects/recents` is auto-managed (most-recently-used list, capped at 50).
