function __void_active_services
    ls /var/service/
end

function __void_services
    ls /etc/sv
end

complete -c xbps -n "not __fish_use_subcommand" -s h -l help -d "Show help"
complete -c xbps -n __fish_use_subcommand -a pkgs -f -d "Change directory to VOID_PACKAGES_PATH"
complete -c xbps -n __fish_use_subcommand -a shutdown -f -d "Shutdown the system immediately"
complete -c xbps -n __fish_use_subcommand -a reboot -f -d "Reboot the system immediately"
complete -c xbps -n __fish_use_subcommand -a repos -f -d "List XBPS repositories"
complete -c xbps -n __fish_use_subcommand -a pkgf -f -d "Find which package owns a file"
complete -c xbps -n __fish_use_subcommand -a install -f -d "Install or update packages"
complete -c xbps -n __fish_use_subcommand -a sync -f -d "Sync all repos"
complete -c xbps -n __fish_use_subcommand -a update -f -d "Update the system and installed packages"
complete -c xbps -n __fish_use_subcommand -a remove -f -d "Remove packages and their dependencies"
complete -c xbps -n __fish_use_subcommand -a search -f -d "Search for packages"
complete -c xbps -n __fish_use_subcommand -a info -f -d "Show package information"
complete -c xbps -n __fish_use_subcommand -a locate -f -d "Locate a package's files"
complete -c xbps -n __fish_use_subcommand -a list -f -d "List installed packages"
complete -c xbps -n __fish_use_subcommand -a hold -f -d "Hold a package to prevent updates"
complete -c xbps -n __fish_use_subcommand -a unhold -f -d "Unhold a package to allow updates"
complete -c xbps -n __fish_use_subcommand -a mirror -f -d "Update XBPS mirror list"
complete -c xbps -n __fish_use_subcommand -a kill -f -d "Kill all processes matching a pattern"
complete -c xbps -n __fish_use_subcommand -a clean-cache -f -d "Remove cached packages"
complete -c xbps -n __fish_use_subcommand -a clear-cache -f -d "Clean all cached packages"
complete -c xbps -n "__fish_seen_subcommand_from install" -a "(__fish_print_packages)" -f
complete -c xbps -n "__fish_seen_subcommand_from update" -a "(__fish_print_packages)" -f
complete -c xbps -n "__fish_seen_subcommand_from remove" -a "(__fish_print_xbps_packages -i)" -f
complete -c xbps -n "__fish_seen_subcommand_from search" -a "(__fish_print_packages)" -f
complete -c xbps -n "__fish_seen_subcommand_from info" -a "(__fish_print_xbps_packages -i)" -f
complete -c xbps -n "__fish_seen_subcommand_from locate" -a "(__fish_print_xbps_packages -i)" -f
complete -c xbps -n "__fish_seen_subcommand_from hold" -a "(__fish_print_xbps_packages -i)" -f
complete -c xbps -n "__fish_seen_subcommand_from unhold" -a "(__fish_print_xbps_packages -i)" -f
complete -c xbps -n "__fish_seen_subcommand_from kill" -a "(__fish_print_processes)" -f
complete -c xbps -n "__fish_seen_subcommand_from clean-cache" -a "(__fish_print_packages)" -f
complete -c xbps -n "__fish_seen_subcommand_from clear-cache" -a "(__fish_print_packages)" -f

complete -c xbps -n __fish_use_subcommand -a services -f -d "List services in /etc/sv/"
complete -c xbps -n __fish_use_subcommand -a active-services -f -d "List services in /var/service/"
complete -c xbps -n __fish_use_subcommand -a restart -f -d "Restart a service"
complete -c xbps -n __fish_use_subcommand -a status -f -r -d "Show the status of a service"
complete -c xbps -n __fish_use_subcommand -a start -f -d "Start a service"
complete -c xbps -n __fish_use_subcommand -a stop -f -d "Stop a service"
complete -c xbps -n __fish_use_subcommand -a disable -f -d "Disable a service by removing the symlink"
complete -c xbps -n __fish_use_subcommand -a enable -f -d "Enable a service by creating a symlink"
complete -c xbps -n "__fish_seen_subcommand_from restart" -xa "(__void_active_services)" -f
complete -c xbps -n "__fish_seen_subcommand_from status" -xa "(__void_active_services)" -f
complete -c xbps -n "__fish_seen_subcommand_from start" -xa "(__void_active_services)" -f
complete -c xbps -n "__fish_seen_subcommand_from stop" -xa "(__void_active_services)" -f
complete -c xbps -n "__fish_seen_subcommand_from disable" -a "(__void_active_services)" -f
complete -c xbps -n "__fish_seen_subcommand_from enable" -a "(__void_services)" -f
