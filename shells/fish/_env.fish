set -U fish_greeting

set hydro_multiline false

set --universal nvm_default_version v23.9.0

set -x ZELLIJ_AUTO_START false
set -x ZELLIJ_AUTO_ATTACH true
set -x ZELLIJ_AUTO_EXIT false
set -x DBIN_INSTALL_DIR $HOME/.local/dbin

set -x PODMAN_IGNORE_CGROUPSV1_WARNING false

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

fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/go/bin
# fish_add_path $HOME/.local/bin
fish_add_path $HOME/.scripts
fish_add_path $HOME/platform-tools

fish_add_path $BUN_INSTALL/bin
fish_add_path $DENO_INSTALL/bin
fish_add_path $PNPM_HOME

fish_add_path $HOME/.spicetify

fish_add_path $HOME/.nix-profile/bin
fish_add_path $HOME/Tinygo/usr/local/bin
fish_add_path $HOME/.dotnet

set -x ANDROID_HOME /opt/android-sdk
# set -x JAVA_HOME /usr/lib/jvm/java-8-openjdk

fish_add_path $ANDROID_HOME/tools/bin
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin
fish_add_path $ANDROID_HOME/platform-tools
fish_add_path $ANDROID_HOME/emulator
