# if test (tty) = "/dev/tty1"
#     if not set -q HYPRLAND_RUNNING
#         if type -q Hyprland
#             set -g HYPRLAND_RUNNING 1

#             exec dbus-run-session Hyprland
#         else
#             echo "Hyprland not found in PATH"
#         end
#     end
# end
