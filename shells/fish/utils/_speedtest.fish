function speedtest --description 'Download a file from a given URL'
    if test (count $argv) -lt 1
        echo "Usage: downloader <URL>"
        return 1
    end

    set URL $argv[1]
    set DESTINATION /dev/null

    check_command wget

    echo "Downloading $URL to $DESTINATION"

    wget -q --show-progress --progress=bar -O $DESTINATION $URL
end

alias ir="speedtest http://185.239.106.174/assets/12mb.png"
alias ht="speedtest https://fsn1-speed.hetzner.com/100MB.bin"
