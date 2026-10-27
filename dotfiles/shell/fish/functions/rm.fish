function rm
    set -l has_recursive false
    set -l has_force false

    for arg in $argv
        if string match -q -- "-*" $arg
            if string match -qr -- ".*r.*" $arg
                set has_recursive true
            end
            if string match -qr -- ".*f.*" $arg
                set has_force true
            end
        end
    end

    if test "$has_recursive" = true -a "$has_force" = true
        set_color yellow
        echo "⚠️  Dangerous rm command intercepted!"
        set_color normal
        echo "  → rm $argv"
        echo ""

        # Defaulting to No (capital N)
        read -l -P ":: Proceed with deletion? [y/N] " confirm

        # If the input is NOT explicitly y or Y, abort execution
        if not string match -qi y -- "$confirm"
            set_color red
            echo ":: Cancelled."
            set_color normal
            return 1
        end
    end

    command rm $argv
end
