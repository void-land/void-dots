if not set -q sysu_helper_commands
    set -l conf_file (status dirname)/../conf.d/sysu.fish
    test -f $conf_file; and source $conf_file
end

function __sysu_is_user
    set -l tokens (commandline -poc)
    for t in $tokens
        if contains -- "$t" -u --user; or string match -q "*-user" -- "$t"
            return 0
        end
    end
    return 1
end

function __sysu_services
    if __sysu_is_user
        systemctl --user list-unit-files --type=service --no-pager --no-legend 2>/dev/null | awk '{print $1}'
    else
        systemctl list-unit-files --type=service --no-pager --no-legend 2>/dev/null | awk '{print $1}'
    end
end

function __sysu_active_services
    if __sysu_is_user
        systemctl --user list-units --type=service --state=active --no-pager --plain --no-legend 2>/dev/null | awk '{print $1}'
    else
        systemctl list-units --type=service --state=active --no-pager --plain --no-legend 2>/dev/null | awk '{print $1}'
    end
end

complete -c sysu -s h -l help -d "Show help"
complete -c sysu -s u -l user -d "Manage user services"

for cmd in $sysu_helper_commands
    set -l command (string split ':' $cmd)
    complete -c sysu -n __fish_use_subcommand -a $command[1] -f -d "$command[2]"
end

# Support -user subcommands for backward compatibility
set -l user_subcommands \
    "start-user:Start a user service" \
    "stop-user:Stop a user service" \
    "restart-user:Restart a user service" \
    "reload-user:Reload a user service" \
    "status-user:Show status of a user service" \
    "enable-user:Enable a user service at boot" \
    "disable-user:Disable a user service from booting" \
    "enable-now-user:Enable and start a user service immediately" \
    "disable-now-user:Disable and stop a user service immediately"

for cmd in $user_subcommands
    set -l command (string split ':' $cmd)
    complete -c sysu -n __fish_use_subcommand -a $command[1] -f -d "$command[2]"
end

set -l active_unit_cmds status stop restart reload disable disable-now log logs journal status-user stop-user restart-user reload-user disable-user disable-now-user
for cmd in $active_unit_cmds
    complete -c sysu -n "__fish_seen_subcommand_from $cmd" -xa "(__sysu_active_services)" -f
end

set -l all_unit_cmds start enable enable-now cat edit mask unmask start-user enable-user enable-now-user
for cmd in $all_unit_cmds
    complete -c sysu -n "__fish_seen_subcommand_from $cmd" -xa "(__sysu_services)" -f
end

set -l no_arg_cmds services list active active-services failed daemon-reload dr
for cmd in $no_arg_cmds
    complete -c sysu -n "__fish_seen_subcommand_from $cmd" -f
end
