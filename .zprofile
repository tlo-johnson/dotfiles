EDITOR=nvim

eval "$(/opt/homebrew/bin/brew shellenv)"

alias obsidian="~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents"

# ssh-agent
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# Java (managed by jenv)
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"

# >>> coursier install directory >>>
export PATH="$PATH:/Users/tlo/Library/Application Support/Coursier/bin"
# <<< coursier install directory <<<

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Put the repo's bin/ scripts (e.g. secure-input-culprit) on PATH so they're runnable by name.
[[ -d "$HOME/dotfiles/bin" ]] && export PATH="$HOME/dotfiles/bin:$PATH"

export PATH="$HOME/ds/bin:$HOME/ds/bin/api-calls:$HOME/bin:$HOME/bin/ds:$PATH"
