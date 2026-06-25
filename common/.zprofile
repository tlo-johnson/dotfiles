EDITOR=nvim

# OS-specific config
case "$OSTYPE" in
  darwin*) [[ -f "$HOME/.zprofile.mac"   ]] && source "$HOME/.zprofile.mac" ;;
  linux*)  [[ -f "$HOME/.zprofile.wsl" ]] && source "$HOME/.zprofile.wsl" ;;
esac

export PATH="$HOME/ds/bin:$HOME/ds/bin/api-calls:$HOME/bin:$HOME/bin/ds:$PATH"
