EDITOR=nvim
eval "$(/opt/homebrew/bin/brew shellenv)"
alias g=git
set -o vi

bindkey -v

alias obsidian="~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents"

# ssh-agent
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Ruby
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# Java 21
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
export JAVA_HOME="/opt/homebrew/Cellar/openjdk@21/21.0.10"

# >>> JVM installed by coursier >>>
# export JAVA_HOME="/Users/tlo/Library/Caches/Coursier/arc/https/github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.24%252B8/OpenJDK11U-jdk_x64_mac_hotspot_11.0.24_8.tar.gz/jdk-11.0.24+8/Contents/Home"
# <<< JVM installed by coursier <<<

# >>> coursier install directory >>>
export PATH="$PATH:/Users/tlo/Library/Application Support/Coursier/bin"
# <<< coursier install directory <<<

export PATH="$HOME/ds/bin:$HOME/bin:$HOME/bin/ds:$PATH"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
