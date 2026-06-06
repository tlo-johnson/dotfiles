# dotfiles

Works on both **macOS** and **Linux / WSL**. `setup` detects the OS (`$OSTYPE`)
and installs packages with Homebrew on macOS or apt on Linux, then symlinks the
portable configs plus the matching OS variant. macOS-only GUI app configs
(Hammerspoon, Karabiner, Ghostty) are skipped on Linux.

## Setup

```sh
git clone https://github.com/tlo-johnson/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup
```

This installs packages (Homebrew on macOS, apt on Linux), creates all symlinks,
and bootstraps `~/.gitconfig.specific` from the template. Then follow the manual
steps printed at the end.

## Manual steps

### Both OSes

- **Git identity & signing** — Edit `~/.gitconfig.specific` (created from `.gitconfig.specific.template`) with your email and commit-signing key.

### macOS

After running `./setup`:

1. **1Password SSH agent** — Open 1Password > Settings > Developer > enable "Use the SSH agent". Git commit signing and SSH auth flow through this.
2. **Hammerspoon** — Open the app, grant Accessibility permission when prompted, enable "Launch at Login" from the menu bar icon.
3. **Karabiner-Elements** — Open the app and enable it. The Hyper layer (Caps Lock) and all custom remaps are in `karabiner.json` and load automatically.
4. **Vimium** — Install the Vimium browser extension, then import `vimium-options.json` via the extension's options page.
5. **1Password CLI** — Run `op signin` and authenticate.
6. **Mission Control** — Open System Settings > Desktop & Dock > Mission Control. Uncheck "Automatically rearrange Spaces based on most recent use" and check "Displays have separate Spaces"
7. **Project switcher** — Create `~/.config/tlo/projects/dirs` and list the directories you want indexed. See [Project switcher config](#project-switcher-config) below.

### Linux / WSL

`apt` covers most core tools; a few aren't in the default repos:

1. **jj (jujutsu)** — `cargo install --locked jj-cli`, or download a release binary. The `.zshrc` completion line is guarded, so a missing `jj` won't break shell startup.
2. **node / bun** — `sudo apt install nodejs npm`; bun via `curl -fsSL https://bun.sh/install | bash`.
3. **SSH agent / signing** — Configure in `~/.zprofile.linux` and `~/.gitconfig.specific` (e.g. bridge to the 1Password app on Windows via npiperelay, or use a local ssh-agent).

> Note: Hammerspoon, Karabiner, and Ghostty configs are macOS-only and are not symlinked on Linux. The `autohotkey/` folder is the Windows-host equivalent of Karabiner + Hammerspoon — see below.

### Windows host (WSL): AutoHotkey

The macOS Karabiner + Hammerspoon stack lives at the OS level, so its WSL equivalent runs on the
**Windows host**, not inside WSL. The `autohotkey/` folder is an [AutoHotkey v2](https://www.autohotkey.com/)
port. It deliberately does almost nothing inside WSL: even the project switcher reads its config and
scans the filesystem from the Windows side, touching WSL only for the one action that must run there
(the tmux session switch).

**Setup on the Windows host:**

1. Install **AutoHotkey v2**.
2. Copy the scripts Windows-side with **`./bin/sync-ahk`** (from WSL) — it finds your Windows
   Documents folder and copies `autohotkey/*.ahk` to `Documents\autohotkey\`. Re-run it after editing
   any `.ahk`. Then load `Documents\autohotkey\main.ahk` (it `#Include`s the rest); for autostart, drop
   a shortcut to it in `shell:startup`. (Alternatively, load directly from `\\wsl$\<distro>\…\autohotkey\`
   without copying.)
3. **Virtual desktops ("spaces")** need [VirtualDesktopAccessor.dll](https://github.com/Ciantic/VirtualDesktopAccessor) —
   download a build matching your Windows version and place it next to the scripts (or edit
   `VDA.DllPath` in `autohotkey/vda.ahk`). Missing/incompatible DLL only disables desktop switching;
   everything else still loads.
4. **Mic toggle** (`autohotkey/mic.ahk`): set `MicDevice` to your recording device's name (Sound
   settings → Input) if the default `"Microphone"` doesn't match. The on-screen "MIC IS ON" badge
   works regardless.
5. Adjust app exes in `autohotkey/apps.ahk` and `TERM_EXE` in `autohotkey/projects.ahk` to match your
   installs. The layout is **Dvorak** (matches the macOS setup) — triggers are bound to the Dvorak
   char on the intended physical key; see the table at the top of `autohotkey/hyper.ahk`.

The **project switcher** (Hyper+R) renders an AHK chooser GUI (search box + filtered list, like the
macOS `hs.chooser`). It reads **`Documents\autohotkey\projects.txt`** (a Windows-side file —
`sync-ahk` seeds it from `projects.txt.example` on first run) and enumerates the listed folders over
`\\wsl$\<distro>\…` using native Windows file APIs — no `wsl.exe` call to build the list. Selecting an
entry makes the one unavoidable WSL call: `wsl.exe -d <distro> … tmux …` to switch/create that
project's session, then focuses the terminal. Edit `projects.txt` to change what's listed (`bare line`
= scan children, `=path` = direct, `!pattern` = ignore). Recents are tracked in
`Documents\autohotkey\projects-recents.txt`. (`tmux switch-client` lands on your terminal when it
already has tmux attached.)

## What's configured

| Tool | Config | Notes |
|------|--------|-------|
| Neovim | `nvim/` | lazy.nvim, LSP (jdtls, gopls, lua), completion, treesitter |
| Zsh | `.zshrc`, `.zprofile` | vi mode, vcs prompt, history search |
| Git | `.gitconfig` | SSH commit signing via 1Password, aliases, rebase on pull |
| Tmux | `.tmux.conf` | vim-style navigation, smart pane switching |
| Ghostty | `ghostty/config` | Terminal with Monaspace font |
| Hammerspoon | `hammerspoon/` | PaperWM tiling, app launcher, project switcher, Bluetooth switching |
| PaperWM | `~/development/PaperWM.spoon` | Scrollable tiling window manager, symlinked into Spoons/ |
| Karabiner | `karabiner.json` | Caps Lock as Hyper + Esc, modal layers for windows/apps/projects |
| AutoHotkey | `autohotkey/` | Windows-host equivalent of Karabiner + Hammerspoon (Hyper layer, window tiling, virtual desktops, app launcher, keypad, mic, project chooser). Synced to Windows via `bin/sync-ahk` |
| Vimium | `vimium-options.json` | Browser keyboard navigation |

## Project switcher config

The project switcher (Hyper+R) reads from `~/.config/tlo/projects/`.

| File | Purpose |
|------|---------|
| `dirs` | Directories to index (required, you create this) |
| `ignore` | Directory names to skip (auto-created with `node_modules`) |
| `recents` | Recently opened projects (auto-managed) |
| `spaces` | Per-project space assignments (optional, you create this) |

**`dirs` format:**

```
# Children of this path are listed (one level deep)
$HOME/code

# This path itself is added directly (prefix with =)
=$HOME/dotfiles
```

**`spaces` format:**

```
$HOME/dotfiles 3
$HOME/code/myproject 1
```

## Key bindings

The tables below describe the macOS (Karabiner + Hammerspoon) layout. The WSL/Windows
`autohotkey/` port mirrors the same Hyper layer and sub-modes, except: window tiling uses
Windows virtual desktops for "spaces" (Hyper+, then `1`–`9`), the app launcher targets Windows
apps (`autohotkey/apps.ahk`), Hyper+Z reloads the AHK script, and Bluetooth switching is macOS-only.

### Hyper layer (Caps Lock)

Caps Lock acts as a Hyper key. Tap alone = Escape.

| Shortcut | Action |
|----------|--------|
| Hyper+Space | App launcher |
| Hyper+, | Window manager |
| Hyper+R | Project switcher |
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
