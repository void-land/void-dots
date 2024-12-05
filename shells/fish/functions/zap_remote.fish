function zap_remote -d "Download, process JSON, and store a simple index"
    if not set -q ZAP_MIRROR
        echo "Error: ZAP_MIRROR is not set." >&2
        return 1
    end

    if not set -q ZAP_DATA_DIR
        echo "Error: ZAP_DATA_DIR is not set." >&2
        return 1
    end

    set -l json_file "$ZAP_DATA_DIR/index.json"
    set -l index_file "$ZAP_PACKAGES_LOCAL_INDEX"

    if not test -d $ZAP_DATA_DIR
        echo "Creating directory: $ZAP_DATA_DIR"
        mkdir -p $ZAP_DATA_DIR
    end

    echo "Downloading packages list from $ZAP_MIRROR..."
    if not curl -q --progress-bar --location $ZAP_MIRROR --output $json_file
        echo "Error: Failed to download packages list from $ZAP_MIRROR" >&2
        return 1
    end

    if not test -s $json_file
        echo "Error: Downloaded file is empty or missing: $json_file" >&2
        return 1
    end

    if not jq -r '.[].name' $json_file >$index_file
        echo "Error: Failed to process JSON and extract names" >&2
        return 1
    end

    if not test -s $index_file
        echo "Error: Generated index file is empty or missing: $index_file" >&2
        return 1
    end

    echo "Packages list downloaded and processed successfully. Index saved to $index_file"
end
