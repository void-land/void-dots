set --query xbps_helper_commands || set --global xbps_helper_commands \
    "pkgs:Change directory to VOID_PACKAGES_PATH" \
    "shutdown:Shutdown the system immediately" \
    "reboot:Reboot the system immediately" \
    "repos:List XBPS repositories" \
    "pkgf:Find which package owns a file" \
    "install:Install and sync or update packages" \
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
    "clean-cache:Remove cached packages by xbps" \
    "prune-cache:Remove cached packages folder " \
    "services:List services in /etc/sv/" \
    "active-services:List services in /var/service/" \
    "restart:Restart a service" \
    "status:Show the status of a service" \
    "start:Start a service" \
    "stop:Stop a service" \
    "enable:Enable a service" \
    "disable:Disable a service"
