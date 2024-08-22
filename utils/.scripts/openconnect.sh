#!/bin/bash

SERVER="iosmtn.apibaz.info"
USER="vbaz568161"
PASSWORD="2489"

check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: Please run the script with sudo."
        exit 1
    fi
}

connect() {
    echo "Connecting to VPN at $SERVER as $USER..."

    sudo openconnect --server="$SERVER" --user="$USER" --no-dtls <<END
yes
$PASSWORD
END
}

check_sudo
connect
