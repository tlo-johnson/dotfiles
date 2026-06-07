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

COMMON="$REPO/common"

echo "==> Linking common configs..."
link "$COMMON/.zshrc"          "$HOME/.zshrc"
link "$COMMON/.zprofile"       "$HOME/.zprofile"
link "$COMMON/.gitconfig"      "$HOME/.gitconfig"
link "$COMMON/.jjconfig.toml"  "$HOME/.jjconfig.toml"
link "$COMMON/.tmux.conf"      "$HOME/.tmux.conf"
link "$COMMON/nvim"            "$HOME/.config/nvim"

# Bootstrap machine-specific git config (email + commit signing) from template.
if [[ ! -e "$HOME/.gitconfig.specific" ]]; then
  cp "$COMMON/.gitconfig.specific.template" "$HOME/.gitconfig.specific"
  echo "    created ~/.gitconfig.specific from template (edit: email + signing key)"
fi
