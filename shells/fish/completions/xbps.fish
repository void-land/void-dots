function __void_active_services
    command ls /var/service/
end

function __void_services
    command ls /etc/sv
end

complete -c xbps -n "not __fish_use_subcommand" -s h -l help -d "Show help"

set -l xbps_commands \
    "pkgs:Change directory to VOID_PACKAGES_PATH" \
    "shutdown:Shutdown the system immediately" \
    "reboot:Reboot the system immediately" \
    "repos:List XBPS repositories" \
    "pkgf:Find which package owns a file" \
    "install:Install or update packages" \
    "add:Install package without sync" \
    "sync:Sync all repos" \
    "update:Update the system and installed packages" \
    "upgrade:Upgrade all installed packages" \
    "remove:Remove packages and their dependencies" \
    "search:Search for packages" \
    "info:Show package information" \
    "locate:Locate a package's files" \
    "list:List installed packages" \
    "hold:Hold a package to prevent updates" \
    "unhold:Unhold a package to allow updates" \
    "mirror:Update XBPS mirror list" \
    "kill:Kill all processes matching a pattern" \
    "clean-cache:Remove cached packages" \
    "clear-cache:Clean all cached packages" \
    "services:List services in /etc/sv/" \
    "active-services:List services in /var/service/" \
    "restart:Restart a service" \
    "status:Show the status of a service" \
    "start:Start a service" \
    "stop:Stop a service" \
    "disable:Disable a service by removing the symlink" \
    "enable:Enable a service by creating a symlink"

for cmd in $xbps_commands
    set -l command (string split ':' $cmd)
    complete -c xbps -n __fish_use_subcommand -a $command[1] -f -d "$command[2]"
end

set -l pkg_commands install add update remove search info locate hold unhold clean-cache clear-cache

for cmd in $pkg_commands
    complete -c xbps -n "__fish_seen_subcommand_from $cmd" -a "(__fish_print_packages)" -f
end

set -l installed_pkg_commands remove info locate hold unhold pkgf

for cmd in $installed_pkg_commands
    complete -c xbps -n "__fish_seen_subcommand_from $cmd" -a "(__fish_print_xbps_packages -i)" -f
end

complete -c xbps -n "__fish_seen_subcommand_from restart status start stop disable" -xa "(__void_active_services)" -f
complete -c xbps -n "__fish_seen_subcommand_from enable" -a "(__void_services)" -f
complete -c xbps -n "__fish_seen_subcommand_from kill" -a "(__fish_print_processes)" -f
