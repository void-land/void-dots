function speedtest-fish --description 'Download a file from a given URL with an option to store it in RAM or disk using wget or axel'
    if test (count $argv) -lt 3
        echo "Usage: speedtest <RAM|DISK> <WGET|AXEL> <URL>"
        return 1
    end

    set MODE $argv[1]
    set TOOL (string lower $argv[2])
    set URL $argv[3]

    switch $MODE
        case RAM
            set DESTINATION /dev/shm/temp_speedtest_file
            echo "Download mode: RAM"
        case DISK
            set DESTINATION /dev/null
            echo "Download mode: DISK"
        case '*'
            echo "Invalid mode. Use 'RAM' or 'DISK'."
            return 1
    end

    switch $TOOL
        case wget
            if not type -q wget
                echo "wget not found. Please install wget."
                return 1
            end
            echo "Using wget for downloading..."
            wget -q --show-progress --progress=bar -O $DESTINATION $URL
        case axel
            if not type -q axel
                echo "axel not found. Please install axel."
                return 1
            end
            echo "Using axel for downloading..."
            axel -n 16 -a -o $DESTINATION $URL
        case '*'
            echo "Invalid download tool. Use 'WGET' or 'AXEL'."
            return 1
    end

    echo "Download completed. File stored at $DESTINATION."

    if test $MODE = RAM
        echo "Removing file from RAM..."
        rm -f $DESTINATION
        echo "File removed."
    else
        echo "File is saved on disk at $DESTINATION. Please remove it manually if not needed."
    end
end

alias ir="speedtest-fish RAM AXEL http://dl2.steamdl.ir/download_test/200MB.bin"
alias irwget="speedtest-fish RAM WGET http://dl2.steamdl.ir/download_test/200MB.bin"
