set --query pacu_helper_commands || set --global pacu_helper_commands \
    "install:Install new package" \
    "reinstall:Reinstall package" \
    "remove:Remove packages and dependencies" \
    "upgrade:Upgrade all installed packages" \
    "update:Update the system and installed packages" \
    "search:Search for packages" \
    "info:Show package information" \
    "list:List explicitly installed packages" \
    "clean-cache:Remove old cached packages" \
    "prune-cache:Remove all cached packages" \
    "hold:Hold a package to prevent updates" \
    "unhold:Unhold a package to allow updates" \
    "services:List all systemd services" \
    "active-services:List active systemd services" \
    "restart:Restart a system service" \
    "restart-user:Restart a user service" \
    "reload:Reload a system service" \
    "reload-user:Reload a user service" \
    "status:Show the status of a system service" \
    "status-user:Show the status of a user service" \
    "start:Start a system service" \
    "start-user:Start a user service" \
    "stop:Stop a system service" \
    "stop-user:Stop a user service" \
    "enable:Enable a system service after reboot" \
    "enable-user:Enable a user service after reboot" \
    "disable:Disable a system service after reboot" \
    "disable-user:Disable a user service after reboot" \
    "enable-now:Enable and start a system service" \
    "enable-now-user:Enable and start a user service" \
    "disable-now:Disable and stop a system service" \
    "disable-now-user:Disable and stop a user service"
