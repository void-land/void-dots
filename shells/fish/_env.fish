set -x ZELLIJ_START false
set -x OS_ID (grep -i -w 'ID=' /etc/os-release | awk -F= '{print $2}')
set -x OS (grep -i -w "ID=" /etc/os-release | grep -oP '(?<=")[^"]*')
set -x NEKORAY_PATH /opt/nekoray/nekoray
set -x CODE_PATH /opt/vscode/code
set -x DOTFILES $HOME/.dots
set -x VOID_PACKAGES_PATH $HOME/.local/pkgs/void-packages
set -x DNS_CHANGER $HOME/.scripts/dns-changer/main.sh
set -x STEAM_OS $HOME/.steam-os/main.sh
set -x SPEEDTEST_DOWNLOAD_URL "http://185.239.106.174/assets/12mb.png"

fish_add_path $HOME/.local/bin

if test -d "/home/$USER/platform-tools"
    fish_add_path "$HOME/platform-tools"
end

if test -d "/home/$USER/.deno"
    set -x DENO_INSTALL "/home/$USER/.deno"
    fish_add_path "$DENO_INSTALL/bin"
end

if test -d "/home/$USER/.cargo"
    source "/home/$USER/.cargo/env"
end

if test -d "/home/$USER/.bun"
    if test -s "/home/$USER/.bun/_bun"
        source "/home/$USER/.bun/_bun"
    end
    set -x BUN_INSTALL "$HOME/.bun"
    fish_add_path "$BUN_INSTALL/bin"
end

if test -d "/home/$USER/.local/share/pnpm"
    set -x PNPM_HOME "/home/$USER/.local/share/pnpm"
end

if test -f "/home/hesam/google-cloud-sdk/path.fish.inc"
    source "/home/hesam/google-cloud-sdk/path.fish.inc"
end

if test -f "/home/hesam/google-cloud-sdk/completion.fish.inc"
    source "/home/hesam/google-cloud-sdk/completion.fish.inc"
end

fish_add_path "$PNPM_HOME"
