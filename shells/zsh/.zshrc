ZSH_THEME="nebirhos"
plugins=(zsh-syntax-highlighting zsh-autosuggestions git themes jsontools)
source $ZSH/oh-my-zsh.sh

source ~/.zsh/_keybinds.zsh
source ~/.zsh/functions/init.zsh
source ~/.zsh/aliases/init.zsh
source ~/.zsh/os/init.zsh

eval "$(atuin init zsh --disable-up-arrow)"
