# Use vi mode in shell
set -o vi

# Customize prompt
autoload -Uz vcs_info
precmd() { vcs_info }

zstyle ':vcs_info:git:*' formats '%b '

setopt PROMPT_SUBST
PROMPT='%F{green}%*%f %~%f %F{red}${vcs_info_msg_0_}%f-> '

# history substring search
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
export PATH="/opt/homebrew/Cellar/libpq/18.2/bin:$HOME/.local/bin:$PATH"

alias docker=/Applications/Docker.app/Contents/Resources/bin/docker
alias g=git
alias claude-ds='CLAUDE_CONFIG_DIR=~/.claude-ds claude'

source "$HOME/.config/op/plugins.sh"
