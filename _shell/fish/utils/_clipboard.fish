function copyfile --description 'Copy file(s) to clipboard for pasting in file managers'
    argparse --name=copyfile h/help a/absolute c/cut -- $argv
    or return 1

    if set -q _flag_help
        echo "Usage: copyfile [OPTIONS] <file1> [file2] [file3] ..."
        echo ""
        echo "Copy files to clipboard for pasting in KDE Dolphin or other file managers"
        echo ""
        echo "Options:"
        echo "  -h, --help      Show this help message"
        echo "  -a, --absolute  Use absolute paths (default: auto-detect)"
        echo "  -c, --cut       Cut files instead of copy (move operation)"
        echo ""
        echo "Examples:"
        echo "  copyfile document.pdf"
        echo "  copyfile file1.txt file2.png file3.zip"
        echo "  copyfile -c oldfile.txt"
        echo "  copyfile ~/Downloads/*.pdf"
        return 0
    end

    if test (count $argv) -lt 1
        echo "❌ Error: No files specified"
        echo "Run 'copyfile --help' for usage information"
        return 1
    end

    if not type -q wl-copy
        echo "❌ wl-copy not found. Install: sudo pacman -S wl-clipboard"
        return 1
    end

    set operation copy
    if set -q _flag_cut
        set operation cut
    end

    set file_uris
    set valid_count 0
    set invalid_files

    for file in $argv
        if test -e $file
            set abs_path (realpath $file)
            set file_uris $file_uris "file://$abs_path"
            set valid_count (math $valid_count + 1)
        else
            set invalid_files $invalid_files $file
        end
    end

    if test (count $invalid_files) -gt 0
        echo "⚠️  Warning: Some files don't exist:"
        for invalid in $invalid_files
            echo "   - $invalid"
        end
    end

    if test $valid_count -eq 0
        echo "❌ Error: No valid files to copy"
        return 1
    end

    if test $operation = cut
        printf "cut\n%s\n" (string join \n $file_uris) | wl-copy -t text/uri-list
        echo "✂️  Cut $valid_count file(s) to clipboard (move operation)"
    else
        printf "%s\n" (string join \n $file_uris) | wl-copy -t text/uri-list
        echo "📋 Copied $valid_count file(s) to clipboard"
    end

    if test $valid_count -le 5
        echo ""
        echo "Files:"
        for file in $argv
            test -e $file; and echo "  ✓ $(basename $file)"
        end
    else
        echo "  ($valid_count files total)"
    end

    return 0
end
