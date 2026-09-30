#!/bin/bash

# Lint every tracked shell script in the repo.
#   bash scripts : bash -n, shfmt (tabs), shellcheck (if installed)
#   fish scripts : fish --no-execute
# Vendored files (fisher plugins, oh-my-tmux, alacritty themes) are skipped.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR" || exit 1

WRITE=false
failed=0

display_help() {
	echo "Usage: $0 [-w] [-h]"
	echo "  -w   Rewrite bash scripts in place with shfmt instead of only diffing"
	echo "  -h   Display this help message"
}

# Tracked bash scripts: *.sh plus extensionless files with a bash shebang.
bash_files() {
	local f
	while IFS= read -r f; do
		[[ -f "$f" ]] || continue
		if [[ "$f" == *.sh ]] || head -n1 "$f" | grep -qE '^#!.*\bbash\b'; then
			echo "$f"
		fi
	done < <(git ls-files -- ':!:shell/fish/plugins/**' ':!:dotfiles/alacritty/themes/**' ':!:*.fish')
}

fish_files() {
	git ls-files -- '*.fish' ':!:shell/fish/plugins/**'
}

fail() {
	echo "✗ $*"
	failed=1
}

while getopts "wh" opt; do
	case $opt in
	w) WRITE=true ;;
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

mapfile -t BASH_FILES < <(bash_files)
mapfile -t FISH_FILES < <(fish_files)

echo "==> bash -n (${#BASH_FILES[@]} files)"
for f in "${BASH_FILES[@]}"; do
	bash -n "$f" || fail "syntax: $f"
done

if command -v shfmt &>/dev/null; then
	echo "==> shfmt"
	if [[ "$WRITE" == true ]]; then
		shfmt -w "${BASH_FILES[@]}"
	else
		shfmt -d "${BASH_FILES[@]}" || fail "shfmt: run '$0 -w' to fix formatting"
	fi
else
	echo "==> shfmt not installed, skipping (pacman -S shfmt)"
fi

if command -v shellcheck &>/dev/null; then
	echo "==> shellcheck"
	shellcheck -x "${BASH_FILES[@]}" || fail "shellcheck"
else
	echo "==> shellcheck not installed, skipping (pacman -S shellcheck)"
fi

if command -v fish &>/dev/null; then
	echo "==> fish --no-execute (${#FISH_FILES[@]} files)"
	for f in "${FISH_FILES[@]}"; do
		fish --no-execute "$f" || fail "syntax: $f"
	done
fi

if ((failed)); then
	echo "Lint failed."
	exit 1
fi
echo "All checks passed."
