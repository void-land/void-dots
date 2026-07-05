function load_files --description 'Load contents of directory'
    if not test -n "$argv"
        echo "Usage: load_files_in_directory <directory>"
        return 1
    end

    set directory $argv[1]

    if not test -d $directory
        echo "Error: '$directory' is not a valid directory."
        return 1
    end

    for file in (ls $directory/*.fish 2>/dev/null)
        source $file
    end
end
