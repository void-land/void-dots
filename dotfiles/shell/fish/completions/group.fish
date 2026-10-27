# Group function completions
complete -c group -n "not __fish_use_subcommand" -s h -l help -d "Show help for group management"

complete -c group -n __fish_use_subcommand -a list -f -d "List all groups"
complete -c group -n __fish_use_subcommand -a add -f -d "Add a new group"
complete -c group -n __fish_use_subcommand -a remove -f -d "Remove an existing group"

complete -c group -n __fish_use_subcommand -a add-user -f -d "Add a user to a group"
complete -c group -n __fish_use_subcommand -a remove-user -f -d "Remove a user from a group"
complete -c group -n __fish_use_subcommand -a info -f -d "Show information about a specific group"
complete -c group -n __fish_use_subcommand -a users -f -d "List all users in a specific group"
complete -c group -n __fish_use_subcommand -a check -f -d "Check if a user is in a specific group"

# Argument completions for specific subcommands
complete -c group -n "__fish_seen_subcommand_from add" -xa "(__fish_print_groups)" -f -d "Specify a group name"
complete -c group -n "__fish_seen_subcommand_from remove" -xa "(__fish_print_groups)" -f -d "Specify a group name to remove"

complete -c group -n "__fish_seen_subcommand_from add-user; and test (count (commandline -opc)) -eq 2" -xa "(__fish_complete_users)" -d "Specify a user to add to a group"
complete -c group -n "__fish_seen_subcommand_from add-user; and test (count (commandline -opc)) -eq 3" -xa "(__fish_complete_groups)" -d "Specify the group to add the user to"

complete -c group -n "__fish_seen_subcommand_from remove-user; and test (count (commandline -opc)) -eq 2" -xa "(__fish_complete_users)" -d "Specify a user to remove from a group"
complete -c group -n "__fish_seen_subcommand_from remove-user; and test (count (commandline -opc)) -eq 3" -xa "(__fish_complete_groups)" -d "Specify the group to remove the user from"

complete -c group -n "__fish_seen_subcommand_from info" -xa "(__fish_complete_groups)" -f -d "Specify a group name for info"
complete -c group -n "__fish_seen_subcommand_from users" -xa "(__fish_complete_groups)" -f -d "Specify a group name to list users"
