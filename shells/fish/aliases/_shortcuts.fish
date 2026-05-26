abbr startk "exec /usr/lib/plasma-dbus-run-session-if-needed /usr/bin/startplasma-wayland"
abbr starth "exec dbus-run-session start-hyprland"

abbr jar "java -jar"

abbr static "ldd ./"

abbr axel "axel -n 32"

abbr dg "dig google.com"
abbr dip "dig +short myip.opendns.com @resolver1.opendns.com -4"

abbr pg "ping -c 10 -i 0.002 -v 8.8.8.8"
abbr pgr "ping -c 100 -i 0.002 -v 8.8.8.8"
abbr pgi "ping -c 100 -i 0.002 -v digikala.com"

abbr mtru "mtr --udp -P 53"
abbr mtrt "mtr --tcp -P 443"
abbr trt "sudo traceroute --tcp --port=443"
abbr tru "sudo traceroute --udp --port=53"

abbr fkill "pkill -f"
abbr sfkill "sudo pkill -f"
abbr pkill "pkill -9"
abbr spkill "sudo pkill -9"
abbr psfind "ps -aux | grep"

abbr dfl "df -h"
abbr dux "du -sh *"
abbr dus "dust -d 1 -b"
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

abbr -a lip "ip -4 addr show (ip route get 1.1.1.1 | awk '{print \$5; exit}') | grep -oP '(?<=inet\s)\d+(\.\d+){3}'"

abbr jellyfin "jellyfin --webdir /usr/share/jellyfin/web --datadir ~/.jellyfin"
