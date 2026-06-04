# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Last updated: 2026-06-04**

If today's date is more than one month after the last updated date above, prompt the user to run `/init` to refresh this file before proceeding.

## What this repo is

Personal macOS dotfiles for Tolu A. All config files are symlinked into place by `./setup`. There are no build steps, tests, or CI — changes take effect immediately after the symlinks resolve.

## Setup

```sh
./setup          # installs Homebrew packages (Brewfile) and creates all symlinks
```

After setup, several manual steps are required (1Password SSH agent, Hammerspoon permissions, Karabiner, Vimium import, `op signin`, Mission Control settings, project dirs config) — see README.md.

## Symlink map

| Config | Symlinked to |
|--------|-------------|
| `.zshrc`, `.zprofile` | `$HOME/` |
| `.gitconfig` | `$HOME/` |
| `.tmux.conf` | `$HOME/` |
| `nvim/` | `~/.config/nvim` |
| `ghostty/` | `~/.config/ghostty` |
| `hammerspoon/` | `~/.hammerspoon` |
| `karabiner.json` | `~/.config/karabiner/karabiner.json` |

## Key components

**Hammerspoon** (`hammerspoon/`) — Lua automation for macOS. `init.lua` loads all modules. Key modules:
- `windows.lua` — PaperWM tiling (wraps `~/development/PaperWM.spoon`, symlinked into `hammerspoon/Spoons/`)
- `projects.lua` — project switcher (Hyper+R); reads `~/.config/tlo/projects/dirs`, manages tmux sessions and space switching
- `apps.lua` — app launcher (Hyper+Space)
- `bluetooth.lua` — Bluetooth device switcher (Hyper+N)
- `mic.lua` — mic mute toggle
- `config.lua` — config reload layer (Hyper+Z)
- `keypad.lua` — modal numpad layer (Hyper+A)

**Neovim** (`nvim/`) — managed by lazy.nvim. Plugins in `lua/plugins/`:
- LSP: `nvim-lspconfig.lua`, `nvim-jdtls.lua` (Java), `nvim-java.lua`; gopls and lua-ls also configured
- Completion: `blink.cmp.lua`
- Formatting: `conform.nvim.lua`
- Fuzzy finding: `telescope.lua`
- Colorscheme: catppuccin with transparent background
- Tmux pane navigation: `vim-tmux-navigator.lua` (Ctrl+H/N/T/S)

**Jujutsu** (`jj/config.toml`) — used alongside git. Common aliases: `j l` (log last 10), `j s` (status), `j d` (diff), `j m "msg"` (describe), `j n` (new change), `j sq` (squash into parent), `j ps` / `j pl` (push/fetch).

**Git** — SSH commit signing via 1Password agent. `~/.gitconfig-specific` is included for machine-specific overrides (not tracked here).

**Karabiner** (`karabiner.json`) — Caps Lock remapped as Hyper key (tap = Escape). Defines the Hyper layer and all modal sublayers (windows, apps, projects, config, keypad).

## Project switcher config format

`~/.config/tlo/projects/dirs` uses ini-style sections:

```
[directories]
$HOME/code          # scan for immediate subdirectories
=$HOME/dotfiles     # add this path directly
!node_modules       # ignore pattern
$HOME/work -> 2     # assign to macOS space 2
```
