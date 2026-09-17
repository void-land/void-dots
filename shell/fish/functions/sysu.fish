function sysu -d "Short and friendly command wrapper for Systemd service management"
    argparse -s h/help u/user -- $argv; or return 1

    if set -q _flag_help; or test (count $argv) -eq 0
        _sysu_display_help
        return 0
    end

    set -l is_user 0
    if set -q _flag_user; or string match -q "*-user" -- $argv[1]
        set is_user 1
        set argv[1] (string replace -r -- '-user$' '' $argv[1])
    end

    set -l sub_command $argv[1]
    set -l cmd_args $argv[2..-1]

    set -l sudo_cmd
    set -l ctl systemctl
    set -l jrn journalctl

    if test $is_user -eq 1
        set ctl systemctl --user
        set jrn journalctl --user
    else
        set sudo_cmd sudo
    end

    switch $sub_command
        case start
            _sysu_require_args "Please provide at least one service name to start" $cmd_args; or return 1
            $sudo_cmd $ctl start $cmd_args

        case stop
            _sysu_require_args "Please provide at least one service name to stop" $cmd_args; or return 1
            $sudo_cmd $ctl stop $cmd_args

        case restart
            _sysu_require_args "Please provide at least one service name to restart" $cmd_args; or return 1
            $sudo_cmd $ctl restart $cmd_args; and $ctl status $cmd_args

        case reload
            _sysu_require_args "Please provide at least one service name to reload" $cmd_args; or return 1
            $sudo_cmd $ctl reload $cmd_args; and $ctl status $cmd_args

        case status
            _sysu_require_args "Please provide at least one service name to inspect" $cmd_args; or return 1
            $ctl status $cmd_args

        case enable
            _sysu_require_args "Please provide at least one service name to enable" $cmd_args; or return 1
            $sudo_cmd $ctl enable $cmd_args

        case disable
            _sysu_require_args "Please provide at least one service name to disable" $cmd_args; or return 1
            $sudo_cmd $ctl disable $cmd_args

        case enable-now
            _sysu_require_args "Please provide at least one service name to enable and start" $cmd_args; or return 1
            $sudo_cmd $ctl enable --now $cmd_args; and $ctl status $cmd_args

        case disable-now
            _sysu_require_args "Please provide at least one service name to disable and stop" $cmd_args; or return 1
            $sudo_cmd $ctl disable --now $cmd_args; and $ctl status $cmd_args

        case mask
            _sysu_require_args "Please provide at least one service name to mask" $cmd_args; or return 1
            $sudo_cmd $ctl mask $cmd_args

        case unmask
            _sysu_require_args "Please provide at least one service name to unmask" $cmd_args; or return 1
            $sudo_cmd $ctl unmask $cmd_args

        case cat
            _sysu_require_args "Please provide at least one service name to view unit file" $cmd_args; or return 1
            $ctl cat $cmd_args

        case edit
            _sysu_require_args "Please provide at least one service name to edit" $cmd_args; or return 1
            $sudo_cmd $ctl edit $cmd_args

        case log logs journal
            _sysu_require_args "Please provide a service name to view logs" $cmd_args; or return 1
            $jrn -u $cmd_args -e --no-pager

        case list services
            $ctl list-unit-files --type=service --no-pager $cmd_args

        case active active-services
            $ctl list-units --type=service --state=active --no-legend --no-pager $cmd_args

        case failed
            $ctl --failed --type=service --no-pager $cmd_args

        case daemon-reload dr
            $sudo_cmd $ctl daemon-reload

        case '*'
            set -l red (set_color red 2>/dev/null)
            set -l normal (set_color normal 2>/dev/null)
            echo "$red"Unknown command: "$sub_command""$normal"
            echo "Use 'sysu --help' to see the list of available commands."
            return 1
    end
end

function _sysu_require_args
    set -l msg $argv[1]
    set -l items $argv[2..-1]
    if test (count $items) -eq 0; or test -z (string trim -- "$items")
        set -l red (set_color red 2>/dev/null)
        set -l normal (set_color normal 2>/dev/null)
        echo "$red"Error: "$msg""$normal"
        return 1
    end
    return 0
end

function _sysu_display_help
    if not set -q sysu_helper_commands
        set -l conf_file (status dirname)/../conf.d/sysu.fish
        test -f $conf_file; and source $conf_file
    end

    echo "Usage: sysu [OPTIONS] COMMAND [arg...]"
    echo ""
    echo "Options:"
    echo "  -u, --user            Target user services instead of system services"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Commands:"

    for cmd in $sysu_helper_commands
        set -l parts (string split ':' $cmd)
        printf "  %-18s %s\n" $parts[1] $parts[2]
    end
end
