#!/bin/bash

LINUX_CONFIGS_DIR="$(pwd)"

HOME_DIR="$LINUX_CONFIGS_DIR/_home"
TERMINAL_DIR="$LINUX_CONFIGS_DIR/_shell"
PLASMA_DIR="$LINUX_CONFIGS_DIR/_plasma"
LINUX_DOTFILES_DIR="$LINUX_CONFIGS_DIR/_dotfiles"

ZED_DIR="$LINUX_CONFIGS_DIR/editors/zed"

display_help() {
	echo "Usage: [-s | -u] [-h]"
	echo "  -s   Stow dotfiles"
	echo "  -u   Unstow dotfiles"
	echo "  -h   Display this help message"
}

log() {
	local timestamp=$(date +"%T")
	local message="======> $1 : $timestamp"

	echo -e "\n$message\n"
}

create_link() {
	local source=$1
	local target=$2

	if [ ! -e "$source" ]; then
		echo "Source does not exist: $source"
		return 1
	fi

	if [ ! -d "$(dirname "$target")" ]; then
		mkdir -p "$(dirname "$target")"
	fi

	# if [ -e "$target" ]; then
	# 	rm -rf "$target"
	# fi

	ln -sfn "$source" "$target"
	echo "$source ===> $target"
}

create_links() {
	local source_dir=$1
	local target_dir=$2

	if [ ! -d $source_dir ]; then
		echo "Source directory does not exist."
		return 1
	fi

	if [ ! -d $target_dir ]; then
		mkdir -p $target_dir
	fi

	for item in "$source_dir"/* "$source_dir"/.*; do
		if [ -e "$item" ] && [ "$item" != "$source_dir/." ] && [ "$item" != "$source_dir/.." ]; then
			echo "$item ===> $target_dir"

			ln -sfn "$item" "$target_dir/"
		fi
	done
}

delete_links() {
	local source_dir=$1
	local target_dir=$2

	if [ ! -d $source_dir ] || [ ! -d $target_dir ]; then
		echo "Source or target directory does not exist."
		return 1
	fi

	for config in "$source_dir"/* "$source_dir"/.*; do
		config_name=$(basename $config)
		target_config="$target_dir/$config_name"

		if [ -e "$target_config" ]; then
			unlink $target_config
			echo "Removed: $target_config"
		else
			echo "Not found: $target_config"
		fi
	done
}

create_target_dir() {
	mkdir -p ~/.config
}

stow() {
	create_target_dir

	create_links $HOME_DIR ~
	log "Utilities stowed successfully!"

	create_links $LINUX_DOTFILES_DIR ~/.config
	log "Base dotfiles stowed successfully!"

	create_links $TERMINAL_DIR ~/.config
	log "Terminal dotfiles stowed successfully!"

	create_links $PLASMA_DIR ~/.config
	log "Plasma stowed successfully!"

	create_link $ZED_DIR ~/.config/zed
	log "Editors dotfiles stowed successfully!"
}

unstow() {
	unlink ~/.config/zed

	delete_links $HOME_DIR ~
	delete_links $TERMINAL_DIR ~/.config
	delete_links $PLASMA_DIR ~/.config
	delete_links $LINUX_DOTFILES_DIR ~/.config

	log "All configs ustowed successfully !"
}

while getopts "ush" opt; do
	case $opt in
	s)
		clear
		stow
		;;
	u)
		unstow
		;;
	h)
		display_help
		exit 0
		;;
	esac
done

if [[ $# -eq 0 ]]; then
	display_help
fi
