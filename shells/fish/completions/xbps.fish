function __void_active_services
    command ls /var/service/
end

function __void_services
    command ls /etc/sv
end

set -l list_all_packages "(__fish_print_xbps_packages)"
set -l list_installed_packages "(__fish_print_xbps_packages -i)"

complete -c xbps -n "not __fish_use_subcommand" -s h -l help -d "Show help"

for cmd in $xbps_helper_commands
    set -l command (string split ':' $cmd)
    complete -c xbps -n __fish_use_subcommand -a $command[1] -f -d "$command[2]"
end

set -l pkg_commands install add update search locate

for cmd in $pkg_commands
    complete -c xbps -n "__fish_seen_subcommand_from $cmd" -a "$list_all_packages" -f
end

set -l installed_pkg_commands remove locate hold unhold pkgf info

for cmd in $installed_pkg_commands
    complete -c xbps -n "__fish_seen_subcommand_from $cmd" -a "$list_installed_packages" -f
end

complete -c xbps -n "__fish_seen_subcommand_from restart status start stop disable" -xa "(__void_active_services)" -f
complete -c xbps -n "__fish_seen_subcommand_from enable" -a "(__void_services)" -f
# complete -c xbps -n "__fish_seen_subcommand_from kill" -a "()" -f
