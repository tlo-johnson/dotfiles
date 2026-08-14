# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Last updated: 2026-08-13**

If today's date is more than one month after the last updated date above, prompt the user to run `/init` to refresh this file before proceeding.

## What this repo is

Personal macOS dotfiles for Tolu A. Flat layout — every config lives at the repo root (no `common/`/`mac/` split; this repo used to also support WSL/Windows via `wsl/`/`windows/` directories, but those were removed and macOS is now the only target):

`Brewfile`, `hammerspoon/`, `karabiner.json`, `ghostty/`, `wezterm/`, `nvim/`, `.zshrc`, `.zprofile`, `.gitconfig`, `.tmux.conf`, `.jjconfig.toml`, `jj.zsh`, `zsh-completions/`, `vimium-options.json`, `bin/` (put on PATH by `.zprofile`), and `setup`.

All config files are symlinked into place by `./setup` (Karabiner's is copied — see below). No build steps, tests, or CI — changes take effect immediately after the symlinks resolve.

## Setup

```sh
./setup
```

`setup` is a single self-contained script: it installs Homebrew packages (`Brewfile`) + configures jenv, defines `link()`/`copy()` helpers inline, symlinks every config at the repo root into place, and bootstraps `~/.gitconfig.specific` from `.gitconfig.specific.template`.

After setup, several manual steps are required (1Password SSH agent, Hammerspoon/Karabiner/Vimium, Mission Control, JDKs via jenv) — see README.md.

## Symlink map

| Config | Symlinked to |
|--------|-------------|
| `.zshrc`, `.zprofile` | `$HOME/` |
| `.gitconfig` | `$HOME/` |
| `.jjconfig.toml` | `$HOME/` |
| `.tmux.conf` | `$HOME/` |
| `nvim/` | `~/.config/nvim` |
| `zsh-completions/_j` | `~/bin/_j` |
| `ghostty/` | `~/.config/ghostty` |
| `wezterm/` | `~/.config/wezterm` |
| `hammerspoon/` | `~/.hammerspoon` |

`karabiner.json` is **not** symlinked — `setup` uses its `copy()` helper to copy it to `~/.config/karabiner/karabiner.json` instead. Karabiner-Elements replaces a symlinked config with a real file on save, which silently breaks the link, so setup pushes a fresh copy each run rather than symlinking. This means edits made live in Karabiner-Elements are not reflected back in the repo automatically — copy the file back manually (or re-apply the change to `karabiner.json` and rerun `./setup`).

## Key components

**Terminal** — mid-migration from Ghostty to WezTerm (`wezterm/wezterm.lua`, Catppuccin Mocha); both configs are still symlinked by `setup` and Ghostty's is retained, but WezTerm is the active default. This matters beyond styling: `hammerspoon/projects.lua`'s project switcher targets the WezTerm app/bundle ID specifically (finding/focusing/launching `com.github.wez.wezterm`) when switching tmux sessions, not a generic "current terminal" — so terminal-switching logic in Hammerspoon assumes WezTerm.

**Hammerspoon** (`hammerspoon/`) — Lua automation for macOS. `init.lua` loads all modules. Key modules:
- `windows.lua` — custom window tiling (move/resize focused window into halves/quadrants) — a hand-rolled tiler, not a Spoon/plugin like PaperWM
- `projects.lua` — project switcher; reads `~/.config/tlo/projects/dirs`, manages tmux sessions (via WezTerm) and space switching
- `tabs.lua` / `browser-tab-store.lua` — browser tab switcher; store is fed live by browser extensions, `tabs.lua` renders the chooser
- `switcher.lua` — Hyper+R opens the project switcher, Hyper+E opens the browser tab switcher
- `apps.lua` — app launcher (Hyper+Space), including a "capture note" action that shells out to `hammerspoon/scripts/capture`
- `bluetooth.lua` — Bluetooth device switcher (Hyper+N)
- `config.lua` — config reload layer (Hyper+Z)
- `keypad.lua` — modal numpad layer (Hyper+A)
- `utils.lua` — shared helper (not a mode itself): `createModal` wraps `hs.hotkey.modal` with a small on-screen alert (canvas-based), used by every modal module above so entering/exiting a mode is visually confirmed

**Neovim** (`nvim/`) — managed by lazy.nvim. Plugins in `lua/plugins/`:
- LSP: `nvim-lspconfig.lua`, `nvim-jdtls.lua` (Java), `nvim-java.lua`; gopls and lua-ls also configured
- Completion: `blink.cmp.lua`
- Formatting: `conform.nvim.lua`
- Fuzzy finding: `telescope.lua`
- Syntax/motions: `nvim-treesitter.lua` (main branch + `nvim-treesitter-textobjects`, custom function/class motions that skip over comments)
- File explorer: `oil.nvim.lua`
- Markdown rendering: `render-markdown.lua` (present but currently `enabled = false`)
- Colorscheme: catppuccin with transparent background
- Tmux pane navigation: `vim-tmux-navigator.lua` (Ctrl+H/N/T/S)

**Jujutsu** — config at `.jjconfig.toml`, symlinked to `$HOME/.jjconfig.toml` by `setup`. `jj.zsh` (sourced by `.zshrc`) defines a `j` wrapper around the `jj` CLI: `j m` (describe, with `--pair`/`--pair-alias` for co-author aliasing via `jj-pair`), `j pl` (`jj-pull`: fetch, and if `@` is empty, auto-advance to the updated bookmark), `j ps` (`jj-push`: create/update a bookmark at the right revision and push it), and passes everything else straight through to `jj`. `zsh-completions/_j` provides completion for `j`, including dynamic bookmark and pair-alias completion.

**Git** — SSH commit signing via 1Password agent. `~/.gitconfig-specific` is included for machine-specific overrides (not tracked here).

**Karabiner** (`karabiner.json`) — Caps Lock remapped as Hyper key (tap = Escape). Defines the Hyper layer and all modal sublayers (windows, apps, projects, config, keypad). Device-scoped rules (via `device_if` conditions) exist for specific keyboards:
- Ducky One2 Mini (`vendor_id 1046, product_id 291`): Escape↔Tilde swap, and Option↔Command swap to match Mac layout.
- Kinesis Advantage (`vendor_id 7504, product_id 24926`): Escape also triggers the Hyper layer (same as Caps Lock — hold = hyper_mode, tap = Escape), and Ctrl remaps to Command.

**Key mapping conventions** — for "what does key X do" questions, read the actual source rather than assuming (bindings change over time): `karabiner.json` (Hyper layer + device-specific rules) dispatches via F13–F19 into `hammerspoon/*.lua` modals (one file per mode: windows, apps, bluetooth, config, keypad, projects, tabs), each built with `utils.createModal`. The same Dvorak-based pane/arrow-navigation idiom is reused across the Hyper layer, `.tmux.conf` pane navigation, and nvim's vim-tmux-navigator bindings (`nvim/init.lua`) — check all three if changing one.

## Project switcher config format

`~/.config/tlo/projects/dirs` uses ini-style sections (this is the single source of truth for the format — README.md previously described an older separate `ignore`/`spaces`-files layout that no longer matches `hammerspoon/projects.lua`):

```
[directories]
$HOME/code          # scan for immediate subdirectories
=$HOME/dotfiles     # add this path directly
!node_modules       # ignore pattern
$HOME/work -> 2     # assign to macOS space 2
```

`~/.config/tlo/projects/recents` is auto-managed (most-recently-used list, capped at 50).
