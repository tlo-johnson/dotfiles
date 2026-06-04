EDITOR=nvim

# OS-specific config
case "$OSTYPE" in
  darwin*) [[ -f "$HOME/.zprofile.mac"   ]] && source "$HOME/.zprofile.mac" ;;
  linux*)  [[ -f "$HOME/.zprofile.linux" ]] && source "$HOME/.zprofile.linux" ;;
esac

export PATH="$HOME/ds/bin:$HOME/bin:$HOME/bin/ds:$PATH"
