function corl --description "Resume a download with curl, following redirects"
    if test (count $argv) -eq 0
        echo "Error: No URL provided. Please provide a URL to download."
        return 1
    end

    curl -O -L -C - $argv
end
