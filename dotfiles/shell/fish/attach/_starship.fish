if command -q starship; and test "$STARSHIP_AUTO_START" = true
    starship init fish | source
end
