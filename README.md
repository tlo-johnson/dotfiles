# dotfiles

## Setup

```sh
git clone https://github.com/tlo-johnson/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup
```

This will install all Homebrew packages and create all symlinks. Then follow the manual steps printed at the end.

## Manual steps

After running `./setup`:

1. **1Password SSH agent** — Open 1Password > Settings > Developer > enable "Use the SSH agent". Git commit signing and SSH auth flow through this.
2. **Hammerspoon** — Open the app, grant Accessibility permission when prompted, enable "Launch at Login" from the menu bar icon.
3. **Karabiner-Elements** — Open the app and enable it. The Hyper layer (Caps Lock) and all custom remaps are in `karabiner.json` and load automatically.
4. **Vimium** — Install the Vimium browser extension, then import `vimium-options.json` via the extension's options page.
5. **1Password CLI** — Run `op signin` and authenticate.
6. **Project switcher** — Create `~/.config/tlo/projects/dirs` and list the directories you want indexed. See [Project switcher config](#project-switcher-config) below.

## What's configured

| Tool | Config | Notes |
|------|--------|-------|
| Neovim | `nvim/` | lazy.nvim, LSP (jdtls, gopls, lua), completion, treesitter |
| Zsh | `.zshrc`, `.zprofile` | vi mode, vcs prompt, history search |
| Git | `.gitconfig` | SSH commit signing via 1Password, aliases, rebase on pull |
| Tmux | `.tmux.conf` | vim-style navigation, smart pane switching |
| Ghostty | `ghostty/config` | Terminal with Monaspace font |
| Hammerspoon | `hammerspoon/` | Window management, app launcher, Bluetooth switching |
| Karabiner | `karabiner.json` | Caps Lock as Hyper + Esc, app switcher (Hyper+Space) |
| Vimium | `vimium-options.json` | Browser keyboard navigation |

## Project switcher config

The project switcher (Hyper+Space, then P) reads from `~/.config/tlo/projects/`.

| File | Purpose |
|------|---------|
| `dirs` | Directories to index (required, you create this) |
| `ignore` | Directory names to skip (auto-created with `node_modules`) |
| `recents` | Recently opened projects (auto-managed) |

**`dirs` format:**

```
# Children of this path are listed (one level deep)
$HOME/code

# This path itself is added directly (prefix with =)
=$HOME/dotfiles
```

## Key bindings

### Hyper layer (Caps Lock)

Caps Lock acts as a Hyper key. Tap alone = Escape.

| Shortcut | Action |
|----------|--------|
| Hyper+Space | App launcher |
| Hyper+W | Window manager |
| Hyper+N | Bluetooth switcher |
| Hyper+Z | Config layer |
| Hyper+A | Keypad layer |

### App launcher (Hyper+Space, then...)

| Key | App |
|-----|-----|
| T | Ghostty |
| B | Google Chrome |
| C | ChatGPT |
| M | Mail |
| F | Finder |
| W | WhatsApp |
| H | Previous app |
| N | Capture note |
| P | Open project |

### Window manager (Hyper+W, then...)

| Key | Action |
|-----|--------|
| ← | Left half |
| → | Right half |
| ↑ | Top half |
| ↓ | Bottom half |
| F | Toggle fullscreen |

### Tmux

Prefix is `Ctrl+Space`.

| Shortcut | Action |
|----------|--------|
| Prefix+\ | Split horizontal |
| Prefix+- | Split vertical |
| Ctrl+H/N/T/S | Navigate panes (vim-aware) |
