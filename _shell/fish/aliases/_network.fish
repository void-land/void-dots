abbr -a lip "ip -4 addr show (ip route get 1.1.1.1 | awk '{print \$5; exit}') | grep -oP '(?<=inet\s)\d+(\.\d+){3}'"

abbr dg "dig google.com"
abbr dip "dig +short myip.opendns.com @resolver1.opendns.com -4"
abbr dci "sudo chattr -i /etc/resolv.conf"
abbr dcp "sudo chattr +i /etc/resolv.conf"

abbr pg "ping -c 10 -i 0.002 -v 8.8.8.8"
abbr pgr "ping -c 100 -i 0.002 -v 8.8.8.8"
abbr pgi "ping -c 100 -i 0.002 -v digikala.com"

abbr mtru "mtr --udp -P 53"
abbr mtrt "mtr --tcp -P 443"
abbr trt "sudo traceroute --tcp --port=443"
abbr tru "sudo traceroute --udp --port=53"

for port in 1080 2080 3080 4080
    abbr --position anywhere --add socks$port "https_proxy='socks5h://localhost:$port' http_proxy='socks5h://localhost:$port'"
    abbr --position anywhere --add http$port "https_proxy='http://localhost:$port' http_proxy='http://localhost:$port'"
end
