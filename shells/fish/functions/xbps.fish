function xbps --argument-names sub_command -d "Short and friendly command wrapper for XBPS"
    if begin
            not set -q argv[1]; or contains -- -h $argv; or contains -- --help $argv
        end
        echo "Usage: xbps COMMAND [OPTIONS] [arg...]"
        echo "Commands:"
        echo "  pkgs             Change directory to VOID_PACKAGES_PATH"
        echo "  shutdown         Shutdown the system immediately"
        echo "  reboot           Reboot the system immediately"
        echo "  repos            List XBPS repositories"
        echo "  pkgf             Find which package owns a file"
        echo "  install          Install and sync or update packages"
        echo "  add              Install package without sync"
        echo "  sync             Sync all repos"
        echo "  update           Update the system and installed packages"
        echo "  upgrade          Upgrade all installed pacakges"
        echo "  remove           Remove packages and their dependencies"
        echo "  search           Search for packages"
        echo "  info             Show package information"
        echo "  locate           Locate a package's files"
        echo "  list             List installed packages"
        echo "  hold             Hold a package to prevent updates"
        echo "  unhold           Unhold a package to allow updates"
        echo "  mirror           Update XBPS mirror list"
        echo "  kill             Kill all processes matching a pattern"
        echo "  clean-cache      Remove cached packages"
        echo "  clear-cache      Clean all cached packages"
        echo "  services         List services in /etc/sv/"
        echo "  active-services  List services in /var/service/"
        echo "  restart          Restart a service"
        echo "  status           Show the status of a service"
        echo "  start            Start a service"
        echo "  stop             Stop a service"
        return 0
    end

    switch $sub_command
        case pkgs
            cd $VOID_PACKAGES_PATH

        case shutdown
            sudo shutdown -h now

        case reboot
            sudo reboot

        case repos
            xbps-query -L

        case pkgf
            xbps-query -f $argv[2..-1]

        case install
            sudo xbps-install -S $argv[2..-1]

        case add
            sudo xbps-install $argv[2..-1]

        case sync
            sudo xbps-install -S

        case upgrade
            sudo xbps-install -Su

        case update
            sudo xbps-install -Su $argv[2..-1]

        case remove
            sudo xbps-remove -R $argv[2..-1]

        case search
            xbps-query -Rs $argv[2..-1]

        case info
            xbps-query -S $argv[2..-1]

        case locate
            xbps-query -f $argv[2..-1]

        case list
            xbps-query -l

        case hold
            sudo xbps-pkgdb -m hold $argv[2..-1]

        case unhold
            sudo xbps-pkgdb -m unhold $argv[2..-1]

        case mirror
            sudo xmirror

        case kill
            pkill -f $argv[2..-1]

        case clean-cache
            sudo xbps-remove -O

        case clear-cache
            echo 'Clean: all cache packages' && sudo rm /var/cache/xbps/*

        case services
            ls -la /etc/sv/

        case active-services
            ls -la /var/service/

        case restart
            sudo sv restart $argv[2..-1]

        case status
            sudo sv status $argv[2..-1]

        case start
            sudo sv up $argv[2..-1]

        case stop
            sudo sv down $argv[2..-1]

        case enable
            if not set -q argv[2]
                echo "Error: Please provide the name of the service to enable"

                return 1
            end

            for service in $argv[2..-1]
                sudo ln -s /etc/sv/$service /var/service
            end

        case disable
            if not set -q argv[2]
                echo "Error: Please provide the name of the service to remove"

                return 1
            end

            for service in $argv[2..-1]
                sudo rm -rf /var/service/$service
            end


        case '*'
            echo "Unknown command: $argv[1]"
            echo "Use 'xbps --help' to see the list of available commands."
    end
end
