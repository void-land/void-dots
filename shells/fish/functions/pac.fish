function pac -d "Short and friendly command wrapper for Pacman"
    if begin
            not set -q argv[1]; or contains -- -h $argv; or contains -- --help $argv
        end
        _pac_display_help
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
            sudo pacman -Syu

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
            systemctl list-units --type=service

        case active-services
            systemctl list-units --type=service --state=active

        case restart
            sudo systemctl restart $cmd_args

        case status
            systemctl status $cmd_args

        case start
            sudo systemctl start $cmd_args

        case stop
            sudo systemctl stop $cmd_args

        case enable
            sudo systemctl enable $cmd_args

        case disable
            sudo systemctl disable $cmd_args

        case '*'
            echo "Unknown command: $sub_command"
            echo "Use 'pac --help' to see the list of available commands."
            return 1
    end
end

function _pac_display_help
    echo "Usage: pac COMMAND [OPTIONS] [arg...]"
    echo "Commands:"

    for cmd in $pac_helper_commands
        set -l parts (string split ':' $cmd)
        printf "  %-15s %s\n" $parts[1] $parts[2]
    end
end