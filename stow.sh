#!/bin/bash

# Resolve the repo from the script's own location so it works from any cwd.
LINUX_CONFIGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HOME_DIR="$LINUX_CONFIGS_DIR/home"
TERMINAL_DIR="$LINUX_CONFIGS_DIR/shell"
PLASMA_DIR="$LINUX_CONFIGS_DIR/plasma"
LINUX_DOTFILES_DIR="$LINUX_CONFIGS_DIR/dotfiles"

ZED_DIR="$LINUX_CONFIGS_DIR/editors/zed"
VSCODE_CONFIGS_DIR="$LINUX_CONFIGS_DIR/editors/vscode/configs"
VSCODE_TARGET_DIRS=("$HOME/.config/VSCodium/User" "$HOME/.config/Code - OSS/User")

DRY_RUN=false

display_help() {
	echo "Usage: $0 [-s | -u] [-n] [-h]"
	echo "  -s   Stow dotfiles"
	echo "  -u   Unstow dotfiles"
	echo "  -n   Dry run: print what would be done without touching anything"
	echo "  -h   Display this help message"
}

log() {
	local timestamp
	timestamp=$(date +"%T")
	echo -e "\n======> $1 : $timestamp\n"
}

# run CMD... — executes CMD, or just prints it in dry-run mode
run() {
	if [[ "$DRY_RUN" == true ]]; then
		echo "[dry-run] $*"
	else
		"$@"
	fi
}

# Symlink SOURCE to exactly TARGET. An existing symlink is replaced; a real
# file/dir is moved aside to TARGET.bak.<timestamp> instead of being clobbered
# (or, for a dir, having the link silently nested inside it).
create_link() {
	local source=$1
	local target=$2

	if [[ ! -e "$source" ]]; then
		echo "Source does not exist: $source"
		return 1
	fi

	[[ -d "$(dirname "$target")" ]] || run mkdir -p "$(dirname "$target")"

	if [[ -e "$target" && ! -L "$target" ]]; then
		local backup
		backup="$target.bak.$(date +%Y%m%d%H%M%S)"
		echo "Backing up existing $target ===> $backup"
		run mv "$target" "$backup"
	fi

	run ln -sfn "$source" "$target"
	echo "$source ===> $target"
}

# Symlink every direct child (including dotfiles) of SOURCE_DIR into TARGET_DIR.
create_links() {
	local source_dir=$1
	local target_dir=$2

	if [[ ! -d "$source_dir" ]]; then
		echo "Source directory does not exist: $source_dir"
		return 1
	fi

	local item
	shopt -s nullglob dotglob
	for item in "$source_dir"/*; do
		create_link "$item" "$target_dir/$(basename "$item")"
	done
	shopt -u nullglob dotglob
}

# Remove TARGET only if it is a symlink pointing at SOURCE, so real files
# (or links owned by something else) are never deleted.
delete_link() {
	local source=$1
	local target=$2

	if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
		run unlink "$target"
		echo "Removed: $target"
	elif [[ -e "$target" || -L "$target" ]]; then
		echo "Skipped (not our symlink): $target"
	else
		echo "Not found: $target"
	fi
}

delete_links() {
	local source_dir=$1
	local target_dir=$2

	if [[ ! -d "$source_dir" || ! -d "$target_dir" ]]; then
		echo "Source or target directory does not exist: $source_dir -> $target_dir"
		return 1
	fi

	local item
	shopt -s nullglob dotglob
	for item in "$source_dir"/*; do
		delete_link "$item" "$target_dir/$(basename "$item")"
	done
	shopt -u nullglob dotglob
}

stow() {
	create_links "$HOME_DIR" ~
	log "Utilities stowed successfully!"

	create_links "$LINUX_DOTFILES_DIR" ~/.config
	log "Base dotfiles stowed successfully!"

	create_links "$TERMINAL_DIR" ~/.config
	log "Terminal dotfiles stowed successfully!"

	create_links "$PLASMA_DIR" ~/.config
	log "Plasma stowed successfully!"

	create_link "$ZED_DIR" ~/.config/zed

	local dir
	for dir in "${VSCODE_TARGET_DIRS[@]}"; do
		create_links "$VSCODE_CONFIGS_DIR" "$dir"
	done
	log "Editors dotfiles stowed successfully!"
}

unstow() {
	delete_link "$ZED_DIR" ~/.config/zed

	local dir
	for dir in "${VSCODE_TARGET_DIRS[@]}"; do
		delete_links "$VSCODE_CONFIGS_DIR" "$dir"
	done

	delete_links "$HOME_DIR" ~
	delete_links "$TERMINAL_DIR" ~/.config
	delete_links "$PLASMA_DIR" ~/.config
	delete_links "$LINUX_DOTFILES_DIR" ~/.config

	log "All configs unstowed successfully!"
}

action=""
while getopts "usnh" opt; do
	case $opt in
	s) action=stow ;;
	u) action=unstow ;;
	n) DRY_RUN=true ;;
	h)
		display_help
		exit 0
		;;
	*)
		display_help
		exit 1
		;;
	esac
done

if [[ -z "$action" ]]; then
	display_help
	exit 1
fi

"$action"
