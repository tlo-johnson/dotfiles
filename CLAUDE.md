# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Last updated: 2026-10-13**

If today's date is more than one month after the last updated date above, prompt the user to run `/init` to refresh this file before proceeding.

## What this repo is

Personal macOS dotfiles for Tolu A. Flat layout — every config lives at the repo root (no `common/`/`mac/` split; this repo used to also support WSL/Windows via `wsl/`/`windows/` directories, but those were removed and macOS is now the only target):

`Brewfile`, `hammerspoon/`, `karabiner.json`, `ghostty/`, `wezterm/`, `nvim/`, `.zshrc`, `.zprofile`, `.gitconfig`, `.tmux.conf`, `.jjconfig.toml`, `jj.zsh`, `zsh-completions/`, `completions/`, `herdr.config.toml`, `vimium-options.json`, `bin/` (put on PATH by `.zprofile`), and `setup`.

All config files are symlinked into place by `./setup` (Karabiner's is copied — see below). No build steps, tests, or CI — changes take effect immediately after the symlinks resolve (except Karabiner, which needs `./setup` rerun).

## Setup

```sh
./setup
```

`setup` is a single self-contained script: it installs Homebrew packages (`Brewfile`) + configures jenv, defines `link()`/`copy()` helpers inline, symlinks every config at the repo root into place, and bootstraps `~/.gitconfig.specific` from `.gitconfig.specific.template`.

`setup` also clones tpm and installs tmux plugins (its echo still says "tpm + catppuccin", but `.tmux.conf` now only declares tpm — the catppuccin tmux theme was dropped).

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
| `herdr.config.toml` | `~/.config/herdr/config.toml` |

`karabiner.json` is **not** symlinked — `setup` uses its `copy()` helper to copy it to `~/.config/karabiner/karabiner.json` instead. Karabiner-Elements replaces a symlinked config with a real file on save, which silently breaks the link, so setup pushes a fresh copy each run rather than symlinking. This means edits made live in Karabiner-Elements are not reflected back in the repo automatically — copy the file back manually (or re-apply the change to `karabiner.json` and rerun `./setup`).

**Zsh completions** — `_j` lives in `zsh-completions/`; `completions/_j` is a tracked absolute symlink to it (`/Users/tlo/dotfiles/zsh-completions/_j`). `.zshrc` adds `~/dotfiles/completions` to `fpath`, while `setup` separately links `zsh-completions/_j` to `~/bin/_j`. Edit the file in `zsh-completions/`.

**Machine-specific shell config** — `.zshrc` ends with `source ~/.zshrc-*`, so per-machine/work settings go in untracked `~/.zshrc-<name>` files, not in the repo.

## Key components

**Terminal** — mid-migration from Ghostty to WezTerm (`wezterm/wezterm.lua`, Catppuccin Mocha); both configs are still symlinked by `setup` and Ghostty's is retained, but WezTerm is the active default. This matters beyond styling: `hammerspoon/projects.lua`'s project switcher targets the WezTerm app/bundle ID specifically (finding/focusing/launching `com.github.wez.wezterm`) when switching tmux sessions, not a generic "current terminal" — so terminal-switching logic in Hammerspoon assumes WezTerm.

**Hammerspoon** (`hammerspoon/`) — Lua automation for macOS. `init.lua` loads all modules. Key modules:
- `windows.lua` — custom window tiling (move/resize focused window into halves/quadrants) — a hand-rolled tiler, not a Spoon/plugin like PaperWM
- `projects.lua` — project switcher; reads `~/.config/tlo/projects/dirs`, manages tmux sessions (via WezTerm) and space switching
- `tabs.lua` / `browser-tab-store.lua` — browser tab switcher; store is fed live by browser extensions, `tabs.lua` renders the chooser
- `switcher.lua` — Hyper+R opens the project switcher, Hyper+E opens the browser tab switcher
- `apps.lua` — app launcher (Hyper+F), including a "capture note" action that shells out to `hammerspoon/scripts/capture`
- `bluetooth.lua` — Bluetooth device switcher (Hyper+N)
- `config.lua` — config reload layer (Hyper+Z)
- `keypad.lua` — modal numpad layer (Hyper+A)
- `utils.lua` — shared helper (not a mode itself): `createModal` wraps `hs.hotkey.modal` with a small on-screen alert (canvas-based), used by every modal module above so entering/exiting a mode is visually confirmed

**Neovim** (`nvim/`) — managed by lazy.nvim. Plugins in `lua/plugins/`:
- LSP: `nvim-lspconfig.lua`, `nvim-java.lua` (Java/jdtls); gopls and lua-ls also configured
- Completion: `blink.cmp.lua`
- Formatting: `conform.nvim.lua`
- Fuzzy finding: `telescope.lua`
- Syntax/motions: `nvim-treesitter.lua` (main branch + `nvim-treesitter-textobjects`, custom function/class motions that skip over comments)
- File explorer: `oil.nvim.lua`
- Markdown rendering: `render-markdown.lua` (present but currently `enabled = false`)
- Colorscheme: catppuccin with transparent background
- Tmux pane navigation: `vim-tmux-navigator.lua` (Ctrl+H/N/T/S)

Non-plugin config lives in `nvim/lua/config/`: `lazy.lua` (lazy.nvim bootstrap) and `context_peek.lua` (on-demand floating window of enclosing treesitter scopes, set up from `init.lua`). `nvim/nvim-pack-lock.json` is a stale leftover from an older `vim.pack` setup — lazy.nvim is the active manager (its `lazy-lock.json` is gitignored).

**Jujutsu** — config at `.jjconfig.toml`, symlinked to `$HOME/.jjconfig.toml` by `setup`. `jj.zsh` (sourced by `.zshrc`) defines a `j` wrapper around the `jj` CLI: `j m` (describe, with `--pair`/`--pair-alias` for co-author aliasing via `jj-pair`), `j pl` (`jj-pull`: fetch, and if `@` is empty, auto-advance to the updated bookmark), `j ps` (`jj-push`: create/update a bookmark at the right revision and push it), and passes everything else straight through to `jj`. `zsh-completions/_j` provides completion for `j`, including dynamic bookmark and pair-alias completion.

**Git** — SSH commit signing via 1Password agent. `.gitconfig` includes `~/.gitconfig.specific` (email + signing key; bootstrapped from `.gitconfig.specific.template`, not tracked).

**herdr** — `herdr.config.toml` (prefix `ctrl+space`, pane focus on `ctrl+h/s/n/t`) follows the same Dvorak navigation idiom as tmux.

**Karabiner** (`karabiner.json`) — Caps Lock remapped as Hyper key (tap = Escape). Defines the Hyper layer and all modal sublayers (windows, apps, projects, config, keypad). Rules are evaluated in order, so an earlier device remap (e.g. Advantage Ctrl→Command) changes what later rules see. Device-scoped rules (via `device_if` conditions) exist for specific keyboards:
- MacBook built-in (`is_built_in_keyboard`): Left Control → grave, Right Option → `[`.
- Ducky One2 Mini (`vendor_id 1046, product_id 291`): Escape↔Tilde swap, and Option↔Command swap to match Mac layout.
- Kinesis Advantage Pro (`vendor_id 7504, product_id 24926`): Escape also triggers the Hyper layer (hold = hyper_mode, tap = Escape), Caps Lock → Control, Ctrl → Command, Command → Alt.
- `vendor_id 10730, product_id 866` (wired Advantage 360) also gets Caps Lock → Control.
- The `devices` section disables the built-in keyboard when `vendor_id 12951, product_id 50894` is connected.

Global (non-device) rules beyond the Hyper layer include Fn → Control, Ctrl+M → Ctrl+Fn+F2 (Fn is required; plain Ctrl+F2 was tested and does not work), both Shifts together toggling Caps Lock, and a tap on Left/Right Shift giving a one-shot sticky Control.

**Key mapping conventions** — for "what does key X do" questions, read the actual source rather than assuming (bindings change over time): `karabiner.json` (Hyper layer + device-specific rules) dispatches via F13–F19 into `hammerspoon/*.lua` modals (one file per mode: windows, apps, bluetooth, config, keypad, projects, tabs), each built with `utils.createModal`. The same Dvorak-based pane/arrow-navigation idiom is reused across the Hyper layer, `.tmux.conf` pane navigation, `herdr.config.toml`, and nvim's vim-tmux-navigator bindings (`nvim/init.lua`) — check all of them if changing one.

README.md's key-binding tables are partly stale (for example, it still lists Ghostty for Hyper+F T and a catppuccin tmux theme), so trust the source over the README.

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
