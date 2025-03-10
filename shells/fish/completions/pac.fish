function __arch_active_services
    systemctl list-units --type=service --state=active --no-pager --plain --no-legend | awk '{print $1}'
end

function __arch_services
    systemctl list-units --type=service --no-pager --plain --no-legend | awk '{print $1}'
end

complete -c pac -n "not __fish_use_subcommand" -s h -l help -d "Show help"

for cmd in $pac_helper_commands
    set -l command (string split ':' $cmd)
    complete -c pac -n __fish_use_subcommand -a $command[1] -f -d "$command[2]"
end

set -l pkg_commands install reinstall info update search

for cmd in $pkg_commands
    complete -c pac -n "__fish_seen_subcommand_from $cmd" -xa "(pacman -Slq)" -f
end

set -l installed_pkg_commands remove

for cmd in $installed_pkg_commands
    complete -c pac -n "__fish_seen_subcommand_from $cmd" -xa "(pacman -Qq)" -f
end

set -l service_commands restart status start stop disable

for cmd in $service_commands
    complete -c pac -n "__fish_seen_subcommand_from $cmd" -xa "(__arch_active_services)" -f
end

complete -c pac -n "__fish_seen_subcommand_from enable" -xa "(__arch_services)" -f
