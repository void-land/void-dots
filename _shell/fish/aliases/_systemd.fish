# ==============================================================================
# SYSTEMCTL ABBREVIATIONS (Prefix: sc / scu)
# ==============================================================================

# Core Commands & Info
abbr sc systemctl
abbr scstatus "systemctl status"
abbr sccat "systemctl cat"
abbr scshow "systemctl show"
abbr scedit "sudo systemctl edit"

# System Actions (Sudo)
abbr scstart "sudo systemctl start"
abbr scstop "sudo systemctl stop"
abbr screstart "sudo systemctl restart"
abbr screload "sudo systemctl reload"
abbr scenable "sudo systemctl enable --now"
abbr scdisable "sudo systemctl disable --now"
abbr scmask "sudo systemctl mask"
abbr scunmask "sudo systemctl unmask"

# User Actions
abbr scusr "systemctl --user"
abbr scustatus "systemctl --user status"
abbr scustart "systemctl --user start"
abbr scustop "systemctl --user stop"
abbr scurestart "systemctl --user restart"
abbr scureload "systemctl --user reload"
abbr scuenable "systemctl --user enable --now"
abbr scudisable "systemctl --user disable --now"
abbr scuedit "systemctl --user edit"

# Unit States & Daemon Management
abbr scfailed "systemctl --failed"
abbr scufailed "systemctl --user --failed"
abbr sclist "systemctl list-units --type=service"
abbr sculist "systemctl --user list-units --type=service"
abbr scfiles "systemctl list-unit-files"
abbr scufiles "systemctl --user list-unit-files"
abbr scdr "sudo systemctl daemon-reload"
abbr scudr "systemctl --user daemon-reload"

# Status Checks (scriptable, exit-code friendly)
abbr scisact "systemctl is-active"
abbr sciena "systemctl is-enabled"
abbr scisfail "systemctl is-failed"

# Timers
abbr sclt "systemctl list-timers"
abbr scult "systemctl --user list-timers"

# Power Management
abbr screboot "sudo systemctl reboot"
abbr scpoweroff "sudo systemctl poweroff"
abbr scsuspend "sudo systemctl suspend"

# ==============================================================================
# JOURNALCTL ABBREVIATIONS (Prefix: jc)
# ==============================================================================

# Core & Unit Inspection
abbr jc journalctl
abbr jcf "journalctl -f"
abbr jcu "journalctl -u"
abbr jcfu "journalctl -f -u"
abbr jcboot "journalctl -b"
abbr jcusr "journalctl --user"
abbr jcerr "journalctl -p err"
abbr jcx "journalctl -xe"

# Time-Based Filters
abbr jcsince "journalctl --since"
abbr jcuntil "journalctl --until"
abbr jctoday "journalctl --since today"
abbr jcyesterday "journalctl --since yesterday"

# One-Liners & Fast Debugging (--no-pager)
abbr jcp3 "journalctl -p 3 --no-pager"
abbr jcnow "journalctl -f --no-pager"

# Boots & Kernel
abbr jclb "journalctl --list-boots"
abbr jcberr "journalctl -b -p 3 --no-pager"
abbr jclast "journalctl -b -1 --no-pager"
abbr jck "journalctl -b -k --no-pager"
abbr jclastk "journalctl -b -1 -k --no-pager"

# Housekeeping
abbr jcdisk "journalctl --disk-usage"
