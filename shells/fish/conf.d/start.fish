if test (tty) = "/dev/tty1"
    if not set -q HYPRLAND_RUNNING
        set -g HYPRLAND_RUNNING 1
        
        exec dbus-run-session Hyprland
    end
end