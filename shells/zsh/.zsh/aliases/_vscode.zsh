CODE_DOWNLOAD_URL="https://code.visualstudio.com/sha/download\?build\=stable\&os\=linux-x64"
CODE_DOWNLOAD_PATH="/tmp/vscode.tar.gz"
CODE_TMP_FOLDER="/tmp/VSCode-linux-x64"

alias code="$CODE_PATH --no-sandbox"
alias codeupdate="wget -q --show-progress -c -O $CODE_DOWNLOAD_PATH $CODE_DOWNLOAD_URL"

codeup() {
    codeupdate

    if [ -f $CODE_DOWNLOAD_PATH ]; then
        tar -xvf $CODE_DOWNLOAD_PATH -C /tmp

        if [ -d $CODE_TMP_FOLDER ]; then
            mv $CODE_TMP_FOLDER /tmp/vscode
        fi

        sudo rm -rf /opt/vscode
        sudo mv /tmp/vscode /opt

        echo "Code updated successfully!"
    else
        echo "Error: File $CODE_DOWNLOAD_PATH does not exist."
    fi
}
