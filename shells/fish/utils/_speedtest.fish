function speedtest --description 'Download a file from a given URL with an option to store it in RAM or disk'
    if test (count $argv) -lt 2
        echo "Usage: speedtest <RAM|DISK> <URL>"
        return 1
    end

    set MODE $argv[1]
    set URL $argv[2]

    switch $MODE
        case "RAM"
            set DESTINATION /dev/shm/temp_speedtest_file
            echo "Download mode: RAM"
        case "DISK"
            set DESTINATION /dev/null
            echo "Download mode: DISK"
        case '*'
            echo "Invalid mode. Use 'RAM' or 'DISK'."
            return 1
    end

    if not type -q wget
        echo "wget command not found. Please install wget."
        return 1
    end

    echo "Downloading $URL to $DESTINATION"

    wget -q --show-progress --progress=bar -O $DESTINATION $URL

    echo "Download completed. File stored at $DESTINATION."

    if test $MODE = "RAM"
        echo "Removing file from RAM..."
        rm -f $DESTINATION
        echo "File removed."
    else
        echo "File is saved on disk at $DESTINATION. Please remove it manually if not needed."
    end
end

alias ir="speedtest RAM http://185.239.106.174/assets/12mb.png"
alias irdisk="speedtest DISK http://185.239.106.174/assets/12mb.png"
alias ht="speedtest RAM https://fsn1-speed.hetzner.com/100MB.bin"
