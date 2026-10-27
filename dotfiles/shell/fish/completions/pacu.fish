if not set -q pacu_helper_commands
    set -l conf_file (status dirname)/../conf.d/pacu.fish
    test -f $conf_file; and source $conf_file
end

complete -c pacu -s h -l help -d "Show help"

for cmd in $pacu_helper_commands
    set -l command (string split ':' $cmd)
    complete -c pacu -n __fish_use_subcommand -a $command[1] -f -d "$command[2]"
end

# Remote packages completion
set -l repo_pkg_commands install reinstall info deps revdeps
for cmd in $repo_pkg_commands
    complete -c pacu -n "__fish_seen_subcommand_from $cmd" -xa "(pacman -Slq)" -f
end

# Installed packages completion
set -l installed_pkg_commands remove files info-installed
for cmd in $installed_pkg_commands
    complete -c pacu -n "__fish_seen_subcommand_from $cmd" -xa "(pacman -Qq)" -f
end

# Local package files
complete -c pacu -n "__fish_seen_subcommand_from install-local local" -r -k -a "(__fish_complete_suffix .pkg.tar.zst .pkg.tar.xz)"

# File ownership queries
complete -c pacu -n "__fish_seen_subcommand_from owns" -F

# Search queries (freeform)
complete -c pacu -n "__fish_seen_subcommand_from search search-installed search-file locate" -f

# Subcommands taking no additional arguments
set -l no_arg_commands update upgrade sync downgrade check list list-all orphans autoremove clean-cache clean-cache-all prune-cache
for cmd in $no_arg_commands
    complete -c pacu -n "__fish_seen_subcommand_from $cmd" -f
end

# Proxy option for subcommands that download
complete -c pacu -n "__fish_seen_subcommand_from install install-local local reinstall update upgrade sync downgrade check" -l proxy -d "Route downloads via ALL_PROXY (default \$pacu_proxy)"
