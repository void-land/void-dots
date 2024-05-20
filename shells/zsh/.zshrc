ZSH_THEME="nebirhos"
plugins=(zsh-syntax-highlighting zsh-autosuggestions git themes jsontools)
source $ZSH/oh-my-zsh.sh

source ~/.zsh/functions/main.zsh
source ~/.zsh/aliases/export.zsh
source ~/.zsh/os/export.zsh

eval "$(atuin init zsh --disable-up-arrow)"
