function extract --description "Expand or extract bundled & compressed files"
    if not set -q argv[1]
        echo "Usage: extract_file <file1> <file2> ... <fileN>"
        return 1
    end

    for file in $argv
        if test -f $file
            echo -s "Extracting : " (set_color --bold blue) $file (set_color normal) \n

            switch $file
                case "*.tar" "*.tar.xz"
                    tar -xvf $file
                case "*.tar.bz2" "*.tbz2"
                    tar --bzip2 -xvf $file
                case "*.tar.gz" "*.tgz"
                    tar --gzip -xvf $file
                case "*.bz" "*.bz2"
                    bunzip2 $file
                case "*.gz"
                    gunzip $file
                case "*.rar"
                    unrar x $file
                case "*.zip"
                    unzip -uo $file -d (basename $file .zip)
                case "*.Z"
                    uncompress $file
                case "*.pax"
                    pax -r <$file
                case "*.deb"
                    ar -xv $file
                    tar -xvf data.tar.xz
                case "*.7z"
                    7z x $file -o(basename $file .7z)
                case '*'
                    echo "Extension not recognized, cannot extract $file" \n
            end
        else
            echo "$file is not a valid file"
        end
    end
end
