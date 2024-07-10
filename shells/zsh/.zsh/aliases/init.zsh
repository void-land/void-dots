source ~/.zsh/aliases/_flatpak.zsh
source ~/.zsh/aliases/_git.zsh
source ~/.zsh/aliases/_network.zsh
source ~/.zsh/aliases/_vscode.zsh
source ~/.zsh/aliases/_brightness.zsh

alias dotfiles="cd $DOTFILES && ls"
alias projects="cd $HOME/Code && ls"

alias alist="alias"
alias fetch="neofetch"
alias wget-scrape="wget -m -k -K -E"
alias pcp="pwd | wl-copy && echo 'Path : $(pwd) copied to clipboard !'"
alias grub-path="cd /etc/default"
alias findbin="whereis"
alias pmx="chmod +x"
alias pmr="chmod -x"
alias steam="steam -forcedesktopscaling=1"
alias steamos="$STEAM_OS"
alias z="zellij"
alias zk="zellij kill-all-sessions -y"
alias sp="LD_PRELOAD=/usr/lib/spotify-adblock.so spotify"
alias nk="$NEKORAY_PATH"
alias snk="sudo -EH $NEKORAY_PATH"
alias serve="miniserve -z"
alias myip="curl "http://ip-api.com/json/" | pp_json"
alias reloadshell="omz reload"
# alias yo="echo '¯\_(ツ)_/¯'"
alias hardware="inxi -b"
alias psfind="ps -aux | grep"
alias dsu="dust -d 1 -b"
alias edit-dns="sudo nano /etc/resolv.conf"
alias dns-changer="sudo $DNS_CHANGER"
alias lt="eza --header --icons -l"
alias lf="eza -lF --color=always"
alias ld="eza -lD --header"
alias lh="eza -dl .* --group-directories-first"
alias ll="eza -al --group-directories-first"
