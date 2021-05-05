set -o vi

alias ls='ls --color=auto'

export EDITOR=nvim
export PATH="~/tools/automation:~/tools/scripts:/home/tlo/bin:$PATH"
export DOCKER_HOST=unix:///run/user/1000/docker.sock

currDir=$(cd $(dirname "${BASH_SOURCE[0]}") >/dev/null 2>&1 && pwd)
source $currDir/dotfiles/bash/git
source $currDir/dotfiles/bash/centralmarket.sh
source $currDir/dotfiles/bash/prompt
source $currDir/dotfiles/bash/pass.sh

# load nvm - sadness cause I don't really want nvm
source /usr/share/nvm/init-nvm.sh
