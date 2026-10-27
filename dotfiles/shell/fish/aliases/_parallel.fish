abbr pfiles "ls | parallel 'echo -n {} = ; ls {} | wc -l'"

abbr paxel "cat urls.txt | parallel --keep-order --jobs 8 'axel -n 16 {} --quiet'"
abbr pwget "cat urls.txt | parallel --keep-order --jobs 8 'wget --content-disposition -c {}'"

abbr pdns "cat ./dnslist.txt | parallel -X --keep-order --jobs 80 'dig @{} -p 53 +short +retry=0 +timeout=1 google.com >/dev/null && echo {}'"
