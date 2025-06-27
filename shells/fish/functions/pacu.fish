function pacu -d "Short and friendly command wrapper for Pacman and Systemd"
    if begin
            not set -q argv[1]; or contains -- -h $argv; or contains -- --help $argv
        end
        _pacu_display_help
        return 0
    end

    set -l sub_command $argv[1]
    set -l cmd_args $argv[2..-1]

    switch $sub_command
        case install
            sudo pacman -S $cmd_args

        case reinstall
            sudo pacman -S --noconfirm $cmd_args

        case remove
            sudo pacman -Rns $cmd_args

        case update
            sudo pacman -Sy $cmd_args

        case upgrade
            sudo pacman -Syu

        case sync
            sudo pacman -Syyu

        case search
            pacman -Ss $cmd_args

        case info
            pacman -Si $cmd_args

        case list
            pacman -Qe

        case clean-cache
            sudo pacman -Sc

        case prune-cache
            sudo pacman -Scc

        case hold
            echo "$cmd_args" | sudo tee -a /etc/pacman.conf

        case unhold
            sudo sed -i "/$cmd_args/d" /etc/pacman.conf

        case services
            echo -e "--- System Services ---"
            systemctl list-unit-files --type=service --no-pager

            echo -e "\n--- User Services ---"
            systemctl --user list-unit-files --type=service --no-pager

        case active-services
            echo -e "--- System Services ---"
            systemctl list-units --type=service --state=active --no-legend --no-pager

            echo -e "\n--- User Services ---"
            systemctl --user list-units --type=service --state=active --no-legend --no-pager

        case start
            sudo systemctl start $cmd_args

        case status
            systemctl status $cmd_args

        case stop
            sudo systemctl stop $cmd_args

        case restart
            sudo systemctl restart $cmd_args

        case reload
            sudo systemctl reload $cmd_args

        case enable
            sudo systemctl enable $cmd_args

        case disable
            sudo systemctl disable $cmd_args

        case enable-now
            sudo systemctl enable --now $cmd_args

        case disable-now
            sudo systemctl disable --now $cmd_args

        case start-user
            systemctl --user start $cmd_args

        case status-user
            systemctl --user status $cmd_args

        case stop-user
            systemctl --user stop $cmd_args

        case restart-user
            systemctl --user restart $cmd_args

        case reload-user
            systemctl --user reload $cmd_args

        case enable-user
            systemctl --user enable $cmd_args

        case disable-user
            systemctl --user disable $cmd_args

        case enable-now-user
            systemctl --user enable --now $cmd_args

        case disable-now-user
            systemctl --user disable --now $cmd_args

        case '*'
            echo "Unknown command: $sub_command"
            echo "Use 'pacu --help' to see the list of available commands."
            return 1
    end
end

function _pacu_display_help
    echo "Usage: pacu COMMAND [OPTIONS] [arg...]"
    echo "Commands:"

    for cmd in $pacu_helper_commands
        set -l parts (string split ':' $cmd)
        printf "  %-15s %s\n" $parts[1] $parts[2]
    end
end
