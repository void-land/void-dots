#!/usr/bin/env bash

# Resolve the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMES_DIR="$SCRIPT_DIR/themes"
TEMP_DIR="/tmp/alacritty-theme-temp"

echo "Creating themes directory if it does not exist: $THEMES_DIR"
mkdir -p "$THEMES_DIR"

echo "Cloning alacritty-theme repository..."
rm -rf "$TEMP_DIR"

if git clone --depth 1 https://github.com/alacritty/alacritty-theme.git "$TEMP_DIR"; then
    echo "Copying theme TOML files..."
    cp -v "$TEMP_DIR"/themes/*.toml "$THEMES_DIR"/

    echo "Cleaning up temporary directory..."
    rm -rf "$TEMP_DIR"

    echo "All themes successfully downloaded and updated!"
else
    echo "Error: Failed to clone repository."
    exit 1
fi
