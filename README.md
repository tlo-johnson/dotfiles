# Choices

Font: [Fantasque Sans Mono](https://github.com/belluzj/fantasque-sans)

# dotfiles

Personal macOS dotfiles. Flat layout — everything lives at the repo root, symlinked (or copied,
for Karabiner) into place by `./setup`.

## Setup

```sh
git clone https://github.com/tlo-johnson/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup
```

This installs Homebrew packages, creates all symlinks, and bootstraps `~/.gitconfig.specific`
from the template. Then follow the manual steps printed at the end.

## Manual steps

After running `./setup`:

1. **Git identity & signing** — Edit `~/.gitconfig.specific` (created from `.gitconfig.specific.template`) with your email and commit-signing key.
2. **1Password SSH agent** — Open 1Password > Settings > Developer > enable "Use the SSH agent". Git commit signing and SSH auth flow through this.
3. **Hammerspoon** — Open the app, grant Accessibility permission when prompted, enable "Launch at Login" from the menu bar icon.
4. **Karabiner-Elements** — Open the app and enable it. The Hyper layer (Caps Lock) and all custom remaps are in `karabiner.json` and load automatically. Note: `karabiner.json` is *copied*, not symlinked, into `~/.config/karabiner/karabiner.json` — Karabiner-Elements rewrites that file on save, which silently breaks a symlink. Rerun `./setup` (or `cp karabiner.json ~/.config/karabiner/karabiner.json`) after editing it in the repo.
5. **Vimium** — Install the Vimium browser extension, then import `vimium-options.json` via the extension's options page.
6. **1Password CLI** — Run `op signin` and authenticate.
7. **Mission Control** — Open System Settings > Desktop & Dock > Mission Control. Uncheck "Automatically rearrange Spaces based on most recent use" and check "Displays have separate Spaces".
8. **Project switcher** — Create `~/.config/tlo/projects/dirs` and list the directories you want indexed. See [Project switcher config](#project-switcher-config) below.

## What's configured

| Tool | Config | Notes |
|------|--------|-------|
| Neovim | `nvim/` | lazy.nvim, LSP (jdtls, gopls, lua), completion, treesitter |
| Zsh | `.zshrc`, `.zprofile` | vi mode, prompt, history search |
| Git | `.gitconfig` | SSH commit signing via 1Password, aliases, rebase on pull |
| Tmux | `.tmux.conf` | vim-style navigation, smart pane switching, Catppuccin Mocha theme via tpm |
| Ghostty | `ghostty/config` | Terminal with Monaspace font |
| WezTerm | `wezterm/wezterm.lua` | Active default terminal (Catppuccin Mocha) |
| Hammerspoon | `hammerspoon/` | Custom window tiler, app launcher, project switcher, Bluetooth switching |
| Karabiner | `karabiner.json` | Caps Lock as Hyper + Esc, modal layers for windows/apps/projects |
| Vimium | `vimium-options.json` | Browser keyboard navigation |
| Jujutsu | `.jjconfig.toml`, `jj.zsh` | `j` wrapper around the `jj` CLI |

## Project switcher config

The project switcher (Hyper+R) reads `~/.config/tlo/projects/dirs`, ini-style:

```
[directories]
$HOME/code          # scan for immediate subdirectories
=$HOME/dotfiles      # add this path directly
!node_modules        # ignore pattern
$HOME/work -> 2       # assign to macOS space 2
```

`~/.config/tlo/projects/recents` is auto-managed (most-recently-used list, capped at 50).

## Key bindings

### Hyper layer (Caps Lock)

Caps Lock acts as a Hyper key. Tap alone = Escape. (On the Kinesis Advantage, Escape also
triggers the Hyper layer, in addition to Caps Lock.)

| Shortcut | Action |
|----------|--------|
| Hyper+F | App launcher |
| Hyper+, | Window manager |
| Hyper+R | Project switcher |
| Hyper+E | Browser tab switcher |
| Hyper+N | Bluetooth switcher |
| Hyper+Z | Config layer |
| Hyper+A | Keypad layer |

### App launcher (Hyper+F, then...)

| Key | App |
|-----|-----|
| T | Ghostty |
| B | Google Chrome |
| C | ChatGPT |
| M | Mail |
| F | Finder |
| W | WhatsApp |
| N | Capture note |

### Window manager (Hyper+,, then...)

| Key | Action |
|-----|--------|
| ←/→/↑/↓ | Focus window |
| Shift+←/→ | Swap window left/right |
| H / S | Decrease / increase width |
| R | Cycle width (1/3, 1/2, 2/3, full) |
| F | Full width |
| I / O | Slurp into column / barf out |
| 1–9 | Switch to space N |
| Shift+1–9 | Move window to space N |
| Esc | Exit |

### Tmux

Prefix is `Ctrl+Space`.

| Shortcut | Action |
|----------|--------|
| Prefix+\ | Split horizontal |
| Prefix+- | Split vertical |
| Ctrl+H/N/T/S | Navigate panes (vim-aware) |
