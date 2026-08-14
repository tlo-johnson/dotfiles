#!/usr/bin/env zsh
# Shared symlink helper + the configs common to both OSes.
# Sourced by mac/setup and wsl/setup. The caller must set $REPO to the repo root.

# Symlink helper. Skips real files/dirs (so nothing is clobbered), but always
# refreshes an existing symlink — removing it first avoids the ln -sf footgun
# where linking over a symlinked directory nests the link inside it.
link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "    SKIP $dst (exists and is not a symlink — move it manually)"
    return
  fi
  [ -L "$dst" ] && rm "$dst"
  ln -s "$src" "$dst"
  echo "    $dst -> $src"
}

# Copy helper for destinations that an app rewrites in place (e.g. Karabiner-Elements
# replaces a symlinked config with a real file on save) — symlinking there just breaks
# silently after the first save, so we push a fresh copy on each setup run instead.
copy() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "    $dst (copied from $src)"
}

COMMON="$REPO/common"

echo "==> Linking common configs..."
link "$COMMON/.zshrc"          "$HOME/.zshrc"
link "$COMMON/.zprofile"       "$HOME/.zprofile"
link "$COMMON/.gitconfig"      "$HOME/.gitconfig"
link "$COMMON/.jjconfig.toml"  "$HOME/.jjconfig.toml"
link "$COMMON/.tmux.conf"      "$HOME/.tmux.conf"
link "$COMMON/nvim"            "$HOME/.config/nvim"
link "$COMMON/zsh-completions/_j" "$HOME/bin/_j"

# Bootstrap machine-specific git config (email + commit signing) from template.
if [[ ! -e "$HOME/.gitconfig.specific" ]]; then
  cp "$COMMON/.gitconfig.specific.template" "$HOME/.gitconfig.specific"
  echo "    created ~/.gitconfig.specific from template (edit: email + signing key)"
fi
