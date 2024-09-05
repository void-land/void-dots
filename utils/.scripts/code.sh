#!/usr/bin/env sh

name="code"
display_name="Visual Studio Code"

local_bin_path="$HOME/.local/bin"
local_application_path="$HOME/.local/share/applications"
app_installation_directory="$HOME/.local/vscode-stable"

executable_path="$app_installation_directory/code"
desktop_local_application="$local_application_path/$name.desktop"
desktop_icon_path="$app_installation_directory/resources/app/resources/linux/code.png"

# download_location=$(mktemp -d /tmp/vscode-XXXXXX)
download_location=/tmp/vscode

set -eu

main() {
	arch="$(uname -m)"
	platform="$(uname -s)"
	channel="${ZED_CHANNEL:-stable}"

	if [ "$platform" = "Darwin" ]; then
		platform="macos"
	elif [ "$platform" = "Linux" ]; then
		platform="linux"
	else
		echo "Unsupported platform $platform"

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
		echo "Unsupported architecture: $arch"

		exit 1
		;;
	esac

	# Run platform functions

	$platform "$@"

	# if [ "$(which "zed")" = "$HOME/.local/bin/zed" ]; then
	# 	echo "Zed has been installed. Run with 'zed'"
	# else
	# 	echo "To run Zed from your terminal, you must add ~/.local/bin to your PATH"
	# 	echo "Run:"

	# 	case "$SHELL" in
	# 	*zsh)
	# 		echo "   echo 'export PATH=\$HOME/.local/bin:\$PATH' >> ~/.zshrc"
	# 		echo "   source ~/.zshrc"
	# 		;;
	# 	*fish)
	# 		echo "   fish_add_path -U $HOME/.local/bin"
	# 		;;
	# 	*)
	# 		echo "   echo 'export PATH=\$HOME/.local/bin:\$PATH' >> ~/.bashrc"
	# 		echo "   source ~/.bashrc"
	# 		;;
	# 	esac

	# 	echo "To run Zed now, '~/.local/bin/zed'"
	# fi
}

download() {
	if command -v curl >/dev/null 2>&1; then
		curl -fL "$@"
	elif command -v wget >/dev/null 2>&1; then
		wget -O- "$@"
	else
		echo "Could not find 'curl' or 'wget' in your path"

		exit 1
	fi
}

linux() {
	# if [ -n "${ZED_BUNDLE_PATH:-}" ]; then
	# 	cp "$ZED_BUNDLE_PATH" "$temp/zed-linux-$arch.tar.gz"
	# else
	# 	echo "Downloading Vscode into $download_location \n"

	# 	download "https://code.visualstudio.com/sha/download?build=stable&os=$platform-deb-$arch" >$download_location/code.deb
	# fi

	# Setup ~/.local directories
	mkdir -p "$local_bin_path" "$local_application_path"
	mkdir -p "$app_installation_directory"

	# Remove older version
	rm -rf "$app_installation_directory"

	echo $download_location

	# Unpack .deb package
	ar xv "$download_location/code.deb"
	tar -xzf "$download_location/data.tar.xz" -C "$download_location"
	mv * "$download_location/usr/share" "$app_installation_directory"

	# Link the binary
	# if [ -f "$HOME/.local/zed$suffix.app/bin/zed" ]; then
	# 	ln -sf "$HOME/.local/zed$suffix.app/bin/zed" "$HOME/.local/bin/zed"
	# else
	# 	# support for versions before 0.139.x.
	# 	ln -sf "$HOME/.local/zed$suffix.app/bin/cli" "$HOME/.local/bin/zed"
	# fi

	# Copy .desktop file
	# desktop_file_path="$HOME/.local/share/applications/${appid}.desktop"
	# cp "$HOME/.local/zed$suffix.app/share/applications/zed$suffix.desktop" "${desktop_file_path}"
	# sed -i "s|Icon=zed|Icon=$HOME/.local/zed$suffix.app/share/icons/hicolor/512x512/apps/zed.png|g" "${desktop_file_path}"
	# sed -i "s|Exec=zed|Exec=$HOME/.local/zed$suffix.app/libexec/zed-editor|g" "${desktop_file_path}"
}

main "$@"
