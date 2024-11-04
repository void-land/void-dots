function group --argument-names sub_command -d "Short and friendly command wrapper for group management"
    if begin
            not set -q argv[1]; or contains -- -h $argv; or contains -- --help $argv
        end
        echo "Usage: group COMMAND [OPTIONS] [arg...]"
        echo "Commands:"
        echo "  list              List all groups"
        echo "  add               Add a new group"
        echo "  remove            Remove an existing group"
        echo "  add-user          Add a user to a group"
        echo "  remove-user       Remove a user from a group"
        echo "  info              Show information about a specific group"
        echo "  users             List all users in a specific group"
        echo "  check             Check if a user is in a specific group"
        return 0
    end

    switch $sub_command
        case list
            __fish_print_groups

        case add
            if not set -q argv[2]
                echo "Error: Please provide a group name to add"
                return 1
            end
            sudo groupadd $argv[2]

        case remove
            if not set -q argv[2]
                echo "Error: Please provide a group name to remove"
                return 1
            end
            sudo groupdel $argv[2]

        case add-user
            if not set -q argv[2]; or not set -q argv[3]
                echo "Error: Please provide both a user name and group name"
                return 1
            end
            sudo usermod -aG $argv[3] $argv[2]

        case remove-user
            if not set -q argv[2]; or not set -q argv[3]
                echo "Error: Please provide both a user name and group name"
                return 1
            end
            sudo gpasswd -d $argv[2] $argv[3]
            

        case info
            if not set -q argv[2]
                echo "Error: Please provide a group name"
                return 1
            end
            getent group $argv[2]

        case users
            if not set -q argv[2]
                echo "Error: Please provide a group name"
                return 1
            end
            getent group $argv[2] | awk -F: '{print $4}'
            
        case '*'
            echo "Unknown command: $argv[1]"
            echo "Use 'group --help' to see the list of available commands."
    end
end
