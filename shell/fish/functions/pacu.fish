function pacu -d "Short and friendly command wrapper for Pacman"
    if begin
            not set -q argv[1]; or contains -- -h $argv; or contains -- --help $argv
        end
        _pacu_display_help
        return 0
    end

    set -l proxy
    set -l rest
    for arg in $argv
        switch $arg
            case --proxy
                set proxy $pacu_proxy
            case '--proxy=*'
                set proxy (string replace -- --proxy= '' $arg)
                test -n "$proxy"; or set proxy $pacu_proxy
            case '*'
                set -a rest $arg
        end
    end

    if not set -q rest[1]
        _pacu_display_help
        return 0
    end

    set -l sub_command $rest[1]
    set -l cmd_args $rest[2..-1]

    set -l proxy_env
    if test -n "$proxy"
        set proxy_env ALL_PROXY=$proxy
        set -l network_commands install install-local local reinstall update upgrade sync downgrade check
        if contains -- $sub_command $network_commands
            echo (set_color cyan 2>/dev/null)"Using proxy: $proxy"(set_color normal 2>/dev/null)
        else
            echo (set_color yellow 2>/dev/null)"Warning: --proxy has no effect for '$sub_command'"(set_color normal 2>/dev/null)
        end
    end

    switch $sub_command
        case install
            _pacu_require_args "Please provide at least one package name to install" $cmd_args; or return 1
            sudo $proxy_env pacman -S $cmd_args

        case install-local local
            _pacu_require_args "Please provide at least one package file (.pkg.tar.*)" $cmd_args; or return 1
            sudo $proxy_env pacman -U $cmd_args

        case reinstall
            _pacu_require_args "Please provide at least one package name to reinstall" $cmd_args; or return 1
            sudo $proxy_env pacman -S --noconfirm $cmd_args

        case remove
            _pacu_require_args "Please provide at least one package name to remove" $cmd_args; or return 1
            sudo pacman -Rns $cmd_args

        case update
            sudo $proxy_env pacman -Sy $cmd_args

        case upgrade
            sudo $proxy_env pacman -Syu $cmd_args

        case sync
            sudo $proxy_env pacman -Syyu $cmd_args

        case downgrade
            sudo $proxy_env pacman -Syyuu $cmd_args

        case check
            if command -q checkupdates
                env $proxy_env checkupdates $cmd_args
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

function _pacu_display_help
    if not set -q pacu_helper_commands
        set -l conf_file (status dirname)/../conf.d/pacu.fish
        test -f $conf_file; and source $conf_file
    end

    echo "Usage: pacu COMMAND [--proxy[=URL]] [arg...]"
    echo ""
    echo "Commands:"

    for cmd in $pacu_helper_commands
        set -l parts (string split ':' $cmd)
        printf "  %-18s %s\n" $parts[1] $parts[2]
    end

    echo ""
    echo "Options:"
    printf "  %-18s %s\n" "--proxy[=URL]" "Route downloads via ALL_PROXY (default: $pacu_proxy)"
    printf "  %-18s %s\n" "" "Applies to install, install-local, reinstall, update, upgrade, sync, downgrade, check"
end
