if not set -q ZELLIJ
    if test "$ZELLIJ_AUTO_START" = true
        zellij
    end

    if test "$ZELLIJ_AUTO_EXIT" = true
        kill $fish_pid
    end
end
