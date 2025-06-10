function __arch_services
    systemctl list-unit-files --type=service --no-pager --no-legend | awk '{print $1}'
end

function __arch_active_services
    systemctl list-units --type=service --state=active --no-pager --plain --no-legend | awk '{print $1}'
end

function __arch_user_services
    systemctl --user list-unit-files --type=service --no-pager --no-legend | awk '{print $1}'
end

function __arch_active_user_services
    systemctl --user list-units --type=service --state=active --no-pager --plain --no-legend | awk '{print $1}'
end

complete -c pacu -n "not __fish_use_subcommand" -s h -l help -d "Show help"

for cmd in $pacu_helper_commands
    set -l command (string split ':' $cmd)
    complete -c pacu -n __fish_use_subcommand -a $command[1] -f -d "$command[2]"
end

set -l pkg_commands install reinstall info search

for cmd in $pkg_commands
    complete -c pacu -n "__fish_seen_subcommand_from $cmd" -xa "(pacman -Slq)" -f
end

set -l installed_pkg_commands remove update

for cmd in $installed_pkg_commands
    complete -c pacu -n "__fish_seen_subcommand_from $cmd" -xa "(pacman -Qq)" -f
end

set -l service_commands start status stop restart reload disable disable-now

for cmd in $service_commands
    complete -c pacu -n "__fish_seen_subcommand_from $cmd" -xa "(__arch_active_services)" -f
end

complete -c pacu -n "__fish_seen_subcommand_from enable" -xa "(__arch_services)" -f
complete -c pacu -n "__fish_seen_subcommand_from enable-now" -xa "(__arch_services)" -f

set -l user_service_commands start-user status-user stop-user restart-user reload-user disable-user disable-now-user

for cmd in $user_service_commands
    complete -c pacu -n "__fish_seen_subcommand_from $cmd" -xa "(__arch_active_user_services)" -f
end

complete -c pacu -n "__fish_seen_subcommand_from enable-user" -xa "(__arch_user_services)" -f
complete -c pacu -n "__fish_seen_subcommand_from enable-now-user" -xa "(__arch_user_services)" -f
