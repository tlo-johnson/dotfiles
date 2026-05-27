# enable tab-completion (required for jj, git, etc.)
fpath=(~/bin $fpath)
[[ -d ~/ds/bin ]] && fpath=(~/ds/bin $fpath)
autoload -Uz compinit && compinit -u
source <(jj util completion zsh)

PROMPT='%F{green}%~ %f-> '

# Use vi mode in shell
set -o vi

# history substring search
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
export PATH="/opt/homebrew/Cellar/libpq/18.3/bin:$HOME/.local/bin:$PATH"

# alias docker=/Applications/Docker.app/Contents/Resources/bin/docker
alias g=git
alias claude-ds='CLAUDE_CONFIG_DIR=~/.claude-ds claude --allowedTools "Read,Grep,Glob"'

source "$HOME/.config/op/plugins.sh"
