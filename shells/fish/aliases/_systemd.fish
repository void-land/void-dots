# systemctl commands
abbr sysstat "systemctl status"
abbr sysstart "systemctl start"
abbr sysstop "systemctl stop"
abbr sysrestart "systemctl restart"
abbr sysreload "systemctl reload"
abbr sysenable "systemctl enable"
abbr sysdisable "systemctl disable"
abbr syslist "systemctl list-units"
abbr syslistfailed "systemctl list-units --failed"
abbr sysactive "systemctl list-units --state=active"

# Power management
abbr syspoweroff "systemctl poweroff"
abbr sysreboot "systemctl reboot"
abbr syssuspend "systemctl suspend"
abbr syshibernate "systemctl hibernate"
abbr syshybrid "systemctl hybrid-sleep"

# Daemon management
abbr sysdaemon "systemctl daemon-reload"
abbr sysrescue "systemctl rescue"
abbr sysemergency "systemctl emergency"

# User systemctl commands
abbr sysstatuser "systemctl --user status"
abbr sysstartuser "systemctl --user start"
abbr sysstopuser "systemctl --user stop"
abbr sysrestartuser "systemctl --user restart"
abbr sysenableuser "systemctl --user enable"
abbr sysdisableuser "systemctl --user disable"

# Analysis commands
abbr sysblame "systemd-analyze blame"
abbr syscritical "systemd-analyze critical-chain"
abbr systime "systemd-analyze time"
abbr sysplot "systemd-analyze plot"
abbr sysdot "systemd-analyze dot"
abbr sysverify "systemd-analyze verify"
abbr syscat "systemd-analyze cat-config"
abbr sysunit "systemd-analyze unit-paths"
abbr syssecurity "systemd-analyze security"

# Log viewing
abbr jctl journalctl
abbr jctlf "journalctl -f"
abbr jctlboot "journalctl -b"
abbr jctluser "journalctl --user"
abbr jctlerr "journalctl -p err"
abbr jctlunit "journalctl -u"
abbr jctlsince "journalctl --since"
abbr jctluntil "journalctl --until"
abbr jctltoday "journalctl --since today"
abbr jctlyesterday "journalctl --since yesterday"
