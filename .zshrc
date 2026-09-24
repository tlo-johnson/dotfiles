# enable tab-completion (required for jj, git, etc.)
fpath=(~/dotfiles/completions $fpath)
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
source ~/dotfiles/jj.zsh

[[ -f "$HOME/.config/op/plugins.sh" ]] && source "$HOME/.config/op/plugins.sh"
eval "$(direnv hook zsh)"
eval "$(fzf --zsh)"
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

source ~/.zshrc-*
