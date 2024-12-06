function xbps -d "Short and friendly command wrapper for XBPS"
    if begin
            not set -q argv[1]; or contains -- -h $argv; or contains -- --help $argv
        end
        _xbps_display_help
        return 0
    end

    set -l sub_command $argv[1]
    set -l cmd_args $argv[2..-1]

    switch $sub_command
        case pkgs
            _xbps_change_to_packages_dir

        case shutdown
            sudo shutdown -h now

        case reboot
            sudo reboot

        case repos
            xbps-query -L

        case pkgf
            _xbps_validate_args $cmd_args && xbps-query -f $cmd_args

        case install
            sudo xbps-install -S $cmd_args

        case add
            sudo xbps-install $cmd_args

        case sync
            sudo xbps-install -S

        case upgrade
            sudo xbps-install -Su

        case update
            sudo xbps-install -Su $cmd_args

        case remove
            sudo xbps-remove -R $cmd_args

        case search
            xbps-query -Rs $cmd_args

        case info
            xbps-query -S $cmd_args

        case locate
            xbps-query -f $cmd_args

        case list
            xbps-query -l

        case hold
            _xbps_validate_args $cmd_args && sudo xbps-pkgdb -m hold $cmd_args

        case unhold
            _xbps_validate_args $cmd_args && sudo xbps-pkgdb -m unhold $cmd_args

        case mirror
            if not command -v xmirror >/dev/null
                echo "xmirror is not installed. Installing..."
                sudo xbps-install -y xmirror

                sudo xmirror
            end

            sudo xmirror

        case kill
            _xbps_validate_args $cmd_args && pkill -f $cmd_args

        case clean-cache
            sudo xbps-remove -O

        case prune-cache
            echo 'Clean: all cache packages'

            sudo rm /var/cache/xbps/*

        case services
            ls -la /etc/sv/

        case active-services
            ls -la /var/service/

        case restart
            _xbps_validate_args $cmd_args && sudo sv restart $cmd_args

        case status
            _xbps_validate_args $cmd_args && sudo sv status $cmd_args

        case start
            _xbps_validate_args $cmd_args && sudo sv up $cmd_args

        case stop
            _xbps_validate_args $cmd_args && sudo sv down $cmd_args

        case enable
            _xbps_manage_service enable $cmd_args

        case disable
            _xbps_manage_service disable $cmd_args

        case '*'
            echo "Unknown command: $sub_command"
            echo "Use 'xbps --help' to see the list of available commands."
            return 1
    end
end

function _xbps_display_help
    echo "Usage: xbps COMMAND [OPTIONS] [arg...]"
    echo "Commands:"

    for cmd in $xbps_helper_commands
        set -l parts (string split ':' $cmd)

        printf "  %-15s %s\n" $parts[1] $parts[2]
    end
end

function _xbps_change_to_packages_dir
    if set -q VOID_PACKAGES_PATH
        cd $VOID_PACKAGES_PATH
    else
        echo "Error: VOID_PACKAGES_PATH is not set"
        return 1
    end
end

function _xbps_validate_args
    if not set -q argv[1]
        echo "Error: At least one argument is required"
        return 1
    end
end

function _xbps_manage_service
    set -l action $argv[1]
    set -l services $argv[2..-1]

    if not set -q services[1]
        echo "Error: Please provide the name of the service to $action"
        return 1
    end

    for service in $services
        switch $action
            case enable
                sudo ln -s /etc/sv/$service /var/service
            case disable
                sudo rm -rf /var/service/$service
        end
    end
end
