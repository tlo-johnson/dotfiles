# enable tab-completion (required for jj, git, etc.)
fpath=(~/bin $fpath)
[[ -d ~/ds/bin ]] && fpath=(~/ds/bin $fpath)
[[ -d ~/ds/bin/api-calls ]] && fpath=(~/ds/bin/api-calls $fpath)
autoload -Uz compinit && compinit -u

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
source ~/dotfiles/common/jj.zsh
alias claude-ds='CLAUDE_CONFIG_DIR=~/.claude-ds claude --allowedTools "Read,Grep,Glob"'
alias claude-cap='CLAUDE_CONFIG_DIR=~/.claude-cap claude --allowedTools "Read,Grep,Glob"'

[[ -f "$HOME/.config/op/plugins.sh" ]] && source "$HOME/.config/op/plugins.sh"
eval "$(direnv hook zsh)"
