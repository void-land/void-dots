set --query pacu_helper_commands || set --global pacu_helper_commands \
    "install:Install package(s)" \
    "install-local:Install local package file(s) (.pkg.tar.zst)" \
    "reinstall:Reinstall package(s) without confirmation" \
    "remove:Remove package(s) and unused dependencies" \
    "update:Refresh package databases" \
    "upgrade:Full system upgrade" \
    "sync:Force refresh databases and upgrade system" \
    "check:Check for available updates" \
    "search:Search for packages in remote repositories" \
    "search-installed:Search among installed packages" \
    "search-file:Find which package owns a remote file" \
    "owns:Find which installed package owns a local file" \
    "info:Show detailed repository package information" \
    "info-installed:Show information for an installed package" \
    "files:List all files installed by a package" \
    "list:List explicitly installed packages" \
    "list-all:List all installed packages" \
    "deps:Show package dependency tree" \
    "revdeps:Show reverse dependency tree for a package" \
    "orphans:List orphaned packages" \
    "autoremove:Remove all orphaned packages" \
    "clean-cache:Remove uninstalled packages from cache" \
    "clean-cache-all:Remove all packages from cache" \
    "prune-cache:Prune pacman package cache" \
    "hold:Hold package(s) from system upgrades" \
    "unhold:Unhold package(s) to allow upgrades" \
    "list-held:List packages held from upgrades"
