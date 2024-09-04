function wgot --description "Resume a download with wget, following redirects"
    if test (count $argv) -eq 0
        echo "Error: No URL provided. Please provide a URL to download."
        return 1
    end

    wget --content-disposition -c $argv
end
