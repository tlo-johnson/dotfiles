# enable tab-completion (required for jj, git, etc.)
fpath=(~/bin $fpath)
[[ -d ~/ds/bin ]] && fpath=(~/ds/bin $fpath)
autoload -Uz compinit && compinit -u
command -v jj &>/dev/null && source <(jj util completion zsh)

PROMPT='%F{green}%~ %f-> '

# Use vi mode in shell
set -o vi

# history substring search
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search

export PATH="$HOME/.local/bin:$PATH"

alias g=git
alias j=jj
alias claude-ds='CLAUDE_CONFIG_DIR=~/.claude-ds claude --allowedTools "Read,Grep,Glob"'

[[ -f "$HOME/.config/op/plugins.sh" ]] && source "$HOME/.config/op/plugins.sh"
[[ -f ~/ds/.zshrc ]] && source ~/ds/.zshrc

# OS-specific config
echo "os type: $OSTYPE"
case "$OSTYPE" in
  darwin*) [[ -f "$HOME/.zshrc.mac"   ]] && source "$HOME/.zshrc.mac" ;;
  linux*)  [[ -f "$HOME/.zshrc.wsl" ]] && source "$HOME/.zshrc.wsl" ;;
esac
