abbr startk "exec /usr/lib/plasma-dbus-run-session-if-needed /usr/bin/startplasma-wayland"
abbr starth "exec dbus-run-session start-hyprland"

abbr sturbo "sudo turbostat --interval 1 --show PkgWatt,CorWatt,RAMWatt,Core,CPU,Bzy_MHz,IRQ"
abbr smount "sudo mount -a"

abbr ggrub "sudo grub-mkconfig -o /boot/grub/grub.cfg"

abbr jar "java -jar"

abbr static "ldd ./"

abbr axel "axel -n 32"

abbr fkill "pkill -f"
abbr sfkill "sudo pkill -f"
abbr idkill "kill -9"
abbr pkill "pkill -9"
abbr spkill "sudo pkill -9"
abbr psfind "ps -aux | grep"

abbr siotop "sudo iotop -oPa"
abbr dfl "df -h"
abbr dux "du -sh *"
abbr dus "dust -d 1 -b"
abbr sdus "sudo dust -d 1 -b"
abbr duse "du -sh"

abbr cpd "pwd | wl-copy"
abbr srm "sudo rm"
abbr rmf "rm -fv"
abbr srmf "sudo rm -fv"
abbr rmfa "rm -fv *"
abbr rmd "rm -rfv"
abbr srmd "sudo rm -rfv"
abbr rma "rm -rfv *"
abbr ins "grep -E 'sse3|sse4|avx|avx2' /proc/cpuinfo"

abbr sshkey "ssh-keygen -t rsa -b 4096 -C 'hesam.init@gmail.com'"
abbr kssh "kitty +kitten ssh -o TCPKeepAlive=yes -o ServerAliveInterval=30"

abbr scode "SUDO_EDITOR='code -nw' sudo -e"
abbr coder "code ./ -r"
abbr coden "code ./ -n"

abbr jellyfin "jellyfin --webdir /usr/share/jellyfin/web --datadir ~/.jellyfin"
