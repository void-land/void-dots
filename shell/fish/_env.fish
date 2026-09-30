set -g fish_greeting

set hydro_multiline false

set --global nvm_default_version lts/krypton

set -x ZELLIJ_AUTO_START false
set -x ZELLIJ_AUTO_ATTACH true
set -x ZELLIJ_AUTO_EXIT false
set -x DBIN_INSTALL_DIR $HOME/.local/dbin

set -x PODMAN_IGNORE_CGROUPSV1_WARNING false

set -x STARSHIP_AUTO_START false
set -x STARSHIP_CONFIG $HOME/.config/starship/config.toml

# Repo root, derived from the ~/.config/fish symlink so it follows wherever the repo is cloned
set -x DOTFILES (path dirname (path dirname (path resolve ~/.config/fish)))

set -x BUN_INSTALL $HOME/.bun
set -x DENO_INSTALL $HOME/.deno
set -x PNPM_HOME $HOME/.local/share/pnpm

fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/go/bin
# fish_add_path $HOME/.local/bin
fish_add_path $HOME/.scripts
fish_add_path $HOME/.vpn
fish_add_path $HOME/.umu-launchers
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
