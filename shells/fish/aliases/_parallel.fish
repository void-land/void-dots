abbr paxel "cat urls.txt | parallel --keep-order --jobs 8 'axel -n 16 {} 2>/dev/null || grep -n {} urls.txt'"
abbr pdns "cat ./dnslist.txt | parallel --keep-order --jobs 80 'dig @{} -p 53 +short +retry=0 +timeout=1 google.com >/dev/null && echo {}'"
