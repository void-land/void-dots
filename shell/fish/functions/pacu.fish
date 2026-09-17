function pacu -d "Short and friendly command wrapper for Pacman"
    if begin
            not set -q argv[1]; or contains -- -h $argv; or contains -- --help $argv
        end
        _pacu_display_help
        return 0
    end

    set -l sub_command $argv[1]
    set -l cmd_args $argv[2..-1]

    switch $sub_command
        case install
            _pacu_require_args "Please provide at least one package name to install" $cmd_args; or return 1
            sudo pacman -S $cmd_args

        case install-local local
            _pacu_require_args "Please provide at least one package file (.pkg.tar.*)" $cmd_args; or return 1
            sudo pacman -U $cmd_args

        case reinstall
            _pacu_require_args "Please provide at least one package name to reinstall" $cmd_args; or return 1
            sudo pacman -S --noconfirm $cmd_args

        case remove
            _pacu_require_args "Please provide at least one package name to remove" $cmd_args; or return 1
            sudo pacman -Rns $cmd_args

        case update
            sudo pacman -Sy $cmd_args

        case upgrade
            sudo pacman -Syu $cmd_args

        case sync
            sudo pacman -Syyu $cmd_args

        case check
            if command -q checkupdates
                checkupdates $cmd_args
            else
                pacman -Qu $cmd_args
            end

        case search
            _pacu_require_args "Please provide a search term" $cmd_args; or return 1
            pacman -Ss $cmd_args

        case search-installed
            _pacu_require_args "Please provide a search term" $cmd_args; or return 1
            pacman -Qs $cmd_args

        case search-file locate
            _pacu_require_args "Please provide a file pattern to search for" $cmd_args; or return 1
            pacman -F $cmd_args

        case owns
            _pacu_require_args "Please provide a file path" $cmd_args; or return 1
            pacman -Qo $cmd_args

        case info
            _pacu_require_args "Please provide a package name" $cmd_args; or return 1
            pacman -Si $cmd_args

        case info-installed
            _pacu_require_args "Please provide an installed package name" $cmd_args; or return 1
            pacman -Qi $cmd_args

        case files
            _pacu_require_args "Please provide a package name to list files" $cmd_args; or return 1
            pacman -Ql $cmd_args

        case list
            pacman -Qe $cmd_args

        case list-all
            pacman -Q $cmd_args

        case deps
            _pacu_require_args "Please provide a package name" $cmd_args; or return 1
            if command -q pactree
                pactree $cmd_args
            else
                pacman -Qi $cmd_args | grep -E '^(Name|Depends On)'
            end

        case revdeps
            _pacu_require_args "Please provide a package name" $cmd_args; or return 1
            if command -q pactree
                pactree -r $cmd_args
            else
                pacman -Qi $cmd_args | grep -E '^(Name|Required By)'
            end

        case orphans
            set -l orphans (pacman -Qtdq)
            if test (count $orphans) -eq 0
                echo "No orphaned packages found."
                return 0
            end
            echo "Orphaned packages ("(count $orphans)"): "
            printf "  %s\n" $orphans

        case autoremove
            set -l orphans (pacman -Qtdq)
            if test (count $orphans) -eq 0
                echo "No orphaned packages to remove."
                return 0
            end

            echo "Orphaned packages ("(count $orphans)"): "
            printf "  %s\n" $orphans

            sudo pacman -Rns $orphans

        case clean-cache
            sudo pacman -Sc $cmd_args

        case clean-cache-all
            sudo pacman -Scc $cmd_args

        case prune-cache
            if command -q paccache
                echo "Pruning pacman cache (retaining recent versions)..."
                sudo paccache -r $cmd_args
            else
                set -l cache_dir /var/cache/pacman/pkg
                if not test -d $cache_dir
                    echo "Cache directory $cache_dir does not exist."
                    return 0
                end

                set -l count (find $cache_dir -type f -name "*.pkg.tar.*" 2>/dev/null | wc -l)
                set -l size (du -sh $cache_dir 2>/dev/null | cut -f1)

                echo "Total cache size: $size"
                echo "Cached package files: $count"
                echo ""

                read -l -P 'Remove all cached packages? [y/N] ' confirm

                switch $confirm
                    case Y y
                        echo "Pruning cache..."
                        sudo rm -rfv $cache_dir/*
                    case '*'
                        echo "Operation cancelled."
                        return 1
                end
            end

        case hold
            _pacu_require_args "Please provide at least one package to hold" $cmd_args; or return 1
            _pacu_manage_hold hold $cmd_args

        case unhold
            _pacu_require_args "Please provide at least one package to unhold" $cmd_args; or return 1
            _pacu_manage_hold unhold $cmd_args

        case list-held
            set -l held (pacman-conf IgnorePkg 2>/dev/null | string match -r '\S+')
            if test (count $held) -eq 0
                echo "No packages currently held."
            else
                echo "Held packages:"
                printf "  %s\n" $held
            end

        case '*'
            set -l red (set_color red 2>/dev/null)
            set -l normal (set_color normal 2>/dev/null)
            echo "$red"Unknown command: "$sub_command""$normal"
            echo "Use 'pacu --help' to see the list of available commands."
            return 1
    end
end

function _pacu_require_args
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

function _pacu_manage_hold
    set -l action $argv[1]
    set -l pkgs $argv[2..-1]

    sudo python3 -c '
import sys, re

action = sys.argv[1]
pkgs = sys.argv[2:]
conf_path = "/etc/pacman.conf"

with open(conf_path, "r") as f:
    lines = f.readlines()

in_options = False
ignore_idx = -1
current_pkgs = []

for i, line in enumerate(lines):
    stripped = line.strip()
    if stripped.startswith("[") and stripped.endswith("]"):
        in_options = (stripped == "[options]")
        continue
    if in_options:
        m = re.match(r"^\s*#?\s*IgnorePkg\s*=\s*(.*)$", line)
        if m:
            ignore_idx = i
            if not stripped.startswith("#"):
                current_pkgs = m.group(1).split()
            break

if action == "hold":
    added = []
    for p in pkgs:
        if p not in current_pkgs:
            current_pkgs.append(p)
            added.append(p)
    if not added:
        print(f"Package(s) already held: {\" \".join(pkgs)}")
        sys.exit(0)
    new_line = f"IgnorePkg = {\" \".join(current_pkgs)}\n"
    if ignore_idx != -1:
        lines[ignore_idx] = new_line
    else:
        for i, line in enumerate(lines):
            if line.strip() == "[options]":
                lines.insert(i + 1, new_line)
                break
    print(f"Held package(s): {\" \".join(added)}")

elif action == "unhold":
    removed = []
    for p in pkgs:
        if p in current_pkgs:
            current_pkgs.remove(p)
            removed.append(p)
    if not removed:
        print(f"Package(s) were not held: {\" \".join(pkgs)}")
        sys.exit(0)
    if ignore_idx != -1:
        if current_pkgs:
            lines[ignore_idx] = f"IgnorePkg = {\" \".join(current_pkgs)}\n"
        else:
            lines[ignore_idx] = "#IgnorePkg   =\n"
    print(f"Unheld package(s): {\" \".join(removed)}")

with open(conf_path, "w") as f:
    f.writelines(lines)
' $action $pkgs
end

function _pacu_display_help
    if not set -q pacu_helper_commands
        set -l conf_file (status dirname)/../conf.d/pacu.fish
        test -f $conf_file; and source $conf_file
    end

    echo "Usage: pacu COMMAND [OPTIONS] [arg...]"
    echo ""
    echo "Commands:"

    for cmd in $pacu_helper_commands
        set -l parts (string split ':' $cmd)
        printf "  %-18s %s\n" $parts[1] $parts[2]
    end
end
