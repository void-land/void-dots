function nix_setup --description 'First time setup nix on void linux'
    if not type -q nix
        echo "Installing necessary dependencies..."

        sudo xbps-install -y nix
    end

    echo "Configuring Fish shell for Nix..."

    if not test -L /var/service/nix-daemon
        echo "Creating symlink for nix-daemon service..."

        sudo ln -sfn /etc/sv/nix-daemon /var/service
    else
        echo "Symlink for nix-daemon service already exists."
    end

    if not nix-channel --list | grep -q nixpkgs-unstable
        nix-channel --add http://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
    else
        echo "nixpkgs-unstable channel already added."
    end

    nix-channel --update

    # echo "set -x NIX_PATH \$NIX_PROFILE/.nix-profile/etc/profile.d/nix.sh" >>$__fish_config_dir/config.fish
    # echo "source \$NIX_PATH" >>$__fish_config_dir/config.fish

    echo "Nix has been installed and configured for Fish shell!"
end
