set --query pacu_helper_commands || set --global pacu_helper_commands \
    "install:Install new package" \
    "reinstall:Reinstall package" \
    "remove:Remove packages and dependencies" \
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
    "restart:Restart a service" \
    "status:Show the status of a service" \
    "start:Start a service" \
    "stop:Stop a service" \
    "enable:Enable a systemd service" \
    "disable:Disable a systemd service"