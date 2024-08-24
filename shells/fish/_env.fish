set -U fish_greeting

set hydro_multiline false

set --universal nvm_default_version latest

set -x ZELLIJ_AUTO_START false
set -x ZELLIJ_AUTO_ATTACH true
set -x ZELLIJ_AUTO_EXIT false

set -x STARSHIP_AUTO_START false
set -x STARSHIP_CONFIG $HOME/.config/starship/text_prompt.toml

set -x OS_ID (grep -i -w 'ID=' /etc/os-release | awk -F= '{print $2}')
set -x OS (grep -i -w "ID=" /etc/os-release | grep -oP '(?<=")[^"]*')
set -x NEKORAY_PATH /opt/nekoray/nekoray
set -x CODE_PATH /opt/vscode/code
set -x DOTFILES $HOME/.dots
set -x VOID_PACKAGES_PATH $HOME/.local/pkgs/void-packages
set -x DNS_CHANGER $HOME/.scripts/dns-changer/main.sh
set -x STEAM_OS $HOME/.steam-os/main.sh

set -x BUN_INSTALL $HOME/.bun
set -x DENO_INSTALL $HOME/.deno
set -x PNPM_HOME $HOME/.local/share/pnpm

fish_add_path $HOME/go/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/platform-tools

fish_add_path $BUN_INSTALL/bin
fish_add_path $DENO_INSTALL/bin
fish_add_path $PNPM_HOME

fish_add_path $HOME/.spicetify

fish_add_path $HOME/.nix-profile/bin
