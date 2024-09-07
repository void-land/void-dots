#!/usr/bin/env sh

arch="$(uname -m)"
platform="$(uname -s)"
channel="${VSCODE_BUILD:-stable}"

name="code"
display_name="Visual Studio Code"

local_bin_path="$HOME/.local/bin"
local_application_path="$HOME/.local/share/applications"
app_installation_path="$HOME/.local/vscode-stable"

executable_path="$app_installation_path/code/code"
desktop_icon_path="$app_installation_path/pixmaps/vscode.png"

download_location=/tmp/vscode
download_file="$download_location/code.deb"

set -eu

log() {
	local color_reset="\033[0m"
	local color_green="\033[32m"
	local color_yellow="\033[33m"
	local color_red="\033[31m"
	local color_blue="\033[34m"

	case "$1" in
	success)
		echo "${color_green}[SUCCESS] ===>${color_reset} $2"
		;;
	info)
		echo "${color_blue}[INFO] ===>${color_reset} $2"
		;;
	warning)
		echo "${color_yellow}[WARNING] ===>${color_reset} $2"
		;;
	error)
		echo "${color_red}[ERROR] ===>${color_reset} $2"
		;;
	*)
		echo "$2"
		;;
	esac
}

main() {
	log info "Detected platform: $platform"
	log info "Detected architecture: $arch"

	if [ "$platform" = "Darwin" ]; then
		platform="macos"
	elif [ "$platform" = "Linux" ]; then
		platform="linux"
	else
		log error "Unsupported platform $platform"

		exit 1
	fi

	case "$arch" in
	x86_64)
		arch="x64"
		;;
	i[3-6]86)
		arch="x86"
		;;
	arm64 | aarch64)
		arch="arm64"
		;;
	armv7* | armv6* | arm32)
		arch="armhf"
		;;
	*)
		log error "Unsupported architecture: $arch"
		exit 1
		;;
	esac

	log info "Installing $display_name for $platform-$arch"

	do_fetch
	do_install

	log success "$display_name installation completed."

	# Display instructions for adding ~/.local/bin to PATH
	# display_path_instructions
}

do_fetch() {
	local download_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-$arch"

	mkdir -p "$download_location"

	log info "Downloading Visual Studio Code..."
	curl --progress-bar -fLC - "$download_url" -o "$download_file"
}

do_install() {
	log info "Setting up installation directories"
	rm -rf "$app_installation_path"
	mkdir -p "$local_bin_path" "$local_application_path" "$app_installation_path"

	log info "Extracting Vscode from the package"
	cd "$download_location"
	ar xv "$download_file"
	tar xfv "$download_location/data.tar.xz" -C "$download_location"
	mv "$download_location/usr/share/"* "$app_installation_path"

	if [ -f "$executable_path" ]; then
		ln -sf "$executable_path" "$local_bin_path"

		log success "Linked binary to $local_bin_path"
	else
		log error "Failed to link vscode binary"

		exit 1
	fi

	log info "Updating .desktop file with executable and icon paths"

	for file in "$app_installation_path/applications/"*.desktop; do
		sed -i "s|/usr/share/code/code|$executable_path|g" "$file"
		sed -i "s|Icon=vscode|Icon=$desktop_icon_path|g" "$file"
	done

	cp "$app_installation_path/applications/"*.desktop "$local_application_path"

	log success ".desktop files updated and copied to $local_application_path"
}

main "$@"
