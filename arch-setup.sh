#!/bin/bash

# Arch Linux Post Installation Setup Script

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# When true, ask_prompt auto-confirms (used once the user has already
# picked what to run via the exclude-style selector in full_setup).
ASSUME_YES=false

declare -a ORDERS_LIST=(
	"BASE_PACKAGES"
	"AUDIO_PACKAGES"
	"GPU_DRIVERS"
	"GAMING_PACKAGES"
	"UTILITIES"
	"FONTS"
)

declare -A PACKAGES_LIST=(
	["UTILITIES"]="turbostat glances htop btop stress-ng cpu-x"
	["BASE_PACKAGES"]="base-devel fish tmux bandwhich jq git curl axel xz zstd fzf networkmanager bluez bluez-utils xdg-utils wl-clipboard alacritty evince"
	["AUDIO_PACKAGES"]="pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack pavucontrol"
	["GPU_DRIVERS"]="mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader vulkan-mesa-layers vulkan-extra-layers vulkan-tools xf86-video-amdgpu"
	["GAMING_PACKAGES"]="steam umu-launcher gamescope mangohud gamemode lib32-mangohud lib32-gamemode goverlay"
	["FONTS"]="ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji ttf-liberation"
)

declare -a AUR_PACKAGES=(
	"vscodium-bin"
	"google-chrome"
	"vazirmatn-fonts"
)

declare -a SERVICES_LIST=(
	"NetworkManager"
	"bluetooth"
)

declare -a USER_SERVICES_LIST=(
	"pipewire"
	"wireplumber"
	"pipewire-pulse"
)

# Steps executed by full_setup, in order. Names and functions are paired by index.
declare -a STEP_NAMES=(
	"Update system"
	"Enable multilib repository"
	"Install pacman packages"
	"Enable system services"
	"Enable user services"
	"Install AUR packages"
	"Setup Persian locale (fa_IR UTF-8)"
	"Setup Fish shell as default"
	"Configure gaming environment (GameMode group, NTSync)"
)

declare -a STEP_FUNCS=(
	update_system
	setup_multilib
	setup_packages
	setup_services
	setup_user_services
	setup_aur_packages
	setup_locales
	setup_fish_shell
	setup_gaming_config
)

trap exit_trap SIGINT SIGTERM

exit_trap() {
	echo -e "\n\n${RED}[!]${NC} Installation interrupted. Cleaning up..."
	exit 1
}

log() {
	echo -e "\n${GREEN}[+]${NC} $1"
}

error() {
	echo -e "${RED}[!]${NC} $1"
}

ask_prompt() {
	local question="$1"

	# Already confirmed via the up-front selection screen, skip re-asking.
	if [[ "$ASSUME_YES" == true ]]; then
		return 0
	fi

	while true; do
		read -p "$question (Y/n) [Y]: " choice
		case "$choice" in
		[Yy] | "") return 0 ;;
		[Nn]) return 1 ;;
		*) echo "Please enter Y or N (or press Enter for Yes)." ;;
		esac
	done
}

# Generic yay-style exclude picker.
# Usage: select_exclusions <name-of-input-array-var> <label> <name-of-output-array-var>
# Prints a numbered list of the given array's elements, prompts once for
# items to exclude (accepts "1 2 3", "1-3", "^4", space/comma separated,
# "^" prefix optional), and writes the 1-based excluded indices into the
# caller-supplied output array (nameref) - no global state involved, so
# nested calls (e.g. setup_packages calling this again for its own list)
# can never clobber a different call's result.
select_exclusions() {
	local -n items_ref="$1"
	local label="${2:-items}"
	local -n out_ref="$3"

	echo -e "${BLUE}::${NC} Following $label will be executed:"
	for i in "${!items_ref[@]}"; do
		printf "%2d  %s\n" "$((i + 1))" "${items_ref[$i]}"
	done
	echo -e "${BLUE}==>${NC} ${label^} to exclude: (eg: \"1 2 3\", \"1-3\", \"^4\")"
	echo -e "${RED} -> Excluding $label may result in a partial setup${NC}"
	read -p "==> " excl_input

	out_ref=()
	if [[ -n "$excl_input" ]]; then
		# normalize commas to spaces so both styles work
		excl_input="${excl_input//,/ }"
		for token in $excl_input; do
			token="${token#^}"
			if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
				for ((i = "${BASH_REMATCH[1]}"; i <= "${BASH_REMATCH[2]}"; i++)); do
					out_ref[$i]=1
				done
			elif [[ "$token" =~ ^[0-9]+$ ]]; then
				out_ref[$token]=1
			fi
		done
	fi
}

display_help() {
	echo "Usage: $0 [-s | -a | -p | -m | -l | -f | -k] [-h]"
	echo " -s  Full system setup"
	echo " -a  Install AUR packages only"
	echo " -p  Install pacman packages only"
	echo " -m  Enable multilib repository"
	echo " -l  Setup locales (Persian)"
	echo " -f  Setup fish shell"
	echo " -k  Apply KWin / Graphics performance tweaks"
	echo " -g  Configure gaming environment (GameMode group, NTSync)"
	echo " -h  Show this help"
}

check_root() {
	if [ "$(id -u)" = 0 ]; then
		error "Please run this script as a regular user, not root."
		exit 1
	fi
}

update_system() {
	log "Optimizing Pacman configurations..."
	# Enable parallel downloads (12) and color if not already set
	sudo sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 12/' /etc/pacman.conf
	sudo sed -i 's/^#Color/Color/' /etc/pacman.conf

	log "Updating system packages..."
	if ! ask_prompt "Do you want to update the system?"; then
		error "Action cancelled..."
		return 0
	fi
	sudo pacman -Syu --noconfirm
}

setup_multilib() {
	log "Enabling multilib repository..."
	if ! ask_prompt "Do you want to enable multilib repository?"; then
		error "Action cancelled..."
		return 0
	fi

	if grep -q "^\[multilib\]" /etc/pacman.conf; then
		echo "Multilib repository is already enabled."
		return 0
	fi

	sudo sed -i '/\[multilib\]/,/Include.*mirrorlist/ s/^#//' /etc/pacman.conf
	sudo pacman -Sy
	log "Multilib repository enabled successfully."
}

setup_packages() {
	local -A excluded_groups=()
	select_exclusions ORDERS_LIST "package groups" excluded_groups

	local packages_list=""
	for i in "${!ORDERS_LIST[@]}"; do
		local idx=$((i + 1))
		[[ -n "${excluded_groups[$idx]}" ]] && continue
		packages_list+="${PACKAGES_LIST["${ORDERS_LIST[$i]}"]} "
	done

	if [[ -z "${packages_list// /}" ]]; then
		echo "No package groups selected, skipping installation."
		return 0
	fi

	log "Following packages will be installed:"
	echo -e "$packages_list\n"

	if ! ask_prompt "Do you want to continue with installation?"; then
		error "Action cancelled..."
		return 0
	fi

	log "Installing packages..."
	sudo pacman -S --noconfirm $packages_list
}

setup_aur_packages() {
	local -A excluded_aur=()
	select_exclusions AUR_PACKAGES "AUR packages" excluded_aur

	local packages_list=""
	for i in "${!AUR_PACKAGES[@]}"; do
		local idx=$((i + 1))
		[[ -n "${excluded_aur[$idx]}" ]] && continue
		packages_list+="${AUR_PACKAGES[$i]} "
	done

	if [[ -z "${packages_list// /}" ]]; then
		echo "No AUR packages selected, skipping installation."
		return 0
	fi

	log "Following AUR packages will be installed:"
	echo -e "$packages_list\n"

	if ! ask_prompt "Do you want to install AUR packages ?"; then
		error "Action cancelled..."
		return 0
	fi

	if ! command -v yay &>/dev/null; then
		log "Installing yay dependencies first..."
		sudo pacman -S --needed --noconfirm base-devel git

		log "Installing yay AUR helper..."
		cd /tmp || exit 1
		git clone https://aur.archlinux.org/yay.git
		cd yay || exit 1
		makepkg -si --noconfirm
		cd ~ || exit 1
	fi

	yay -S --noconfirm $packages_list
}

setup_services() {
	log "Enabling system services..."
	if ! ask_prompt "Do you want to enable required system services?"; then
		error "Action cancelled..."
		return 0
	fi

	for service in "${SERVICES_LIST[@]}"; do
		if systemctl is-enabled "$service" &>/dev/null; then
			echo "Service $service is already enabled, skipping..."
		else
			sudo systemctl enable --now $service
			echo "Service $service enabled"
		fi
	done
}

setup_user_services() {
	log "Enabling user services..."
	if ! ask_prompt "Do you want to enable user services?"; then
		error "Action cancelled..."
		return 0
	fi

	for service in "${USER_SERVICES_LIST[@]}"; do
		if systemctl --user is-enabled "$service" &>/dev/null; then
			echo "User service $service is already enabled, skipping..."
		else
			systemctl --user enable --now $service
			echo "User service $service enabled"
		fi
	done
}

setup_locales() {
	log "Setting up Persian locale..."
	if ! ask_prompt "Do you want to enable Persian locale (fa_IR UTF-8)?"; then
		error "Action cancelled..."
		return 0
	fi

	if grep -q "^fa_IR UTF-8" /etc/locale.gen; then
		echo "Persian locale is already uncommented."
	else
		sudo sed -i 's/#fa_IR UTF-8/fa_IR UTF-8/' /etc/locale.gen
	fi

	sudo locale-gen
	log "Persian locale enabled successfully."
}

setup_fish_shell() {
	log "Setting up Fish shell..."
	if ! ask_prompt "Do you want to set Fish as your default shell?"; then
		error "Action cancelled..."
		return 0
	fi

	if ! grep -q "/bin/fish" /etc/shells; then
		echo /bin/fish | sudo tee -a /etc/shells
	fi

	chsh -s /bin/fish
	log "Fish shell set as default. Changes will take effect after logout/login."
}

setup_kwin_tweaks() {
	log "Setting up KWin & Graphics environment tweaks..."
	if ! ask_prompt "Do you want to add performance environment variables to /etc/environment?"; then
		error "Action cancelled..."
		return 0
	fi

	# Add KWin Triple Buffering Disable
	if grep -q "KWIN_DRM_DISABLE_TRIPLE_BUFFERING" /etc/environment; then
		echo "KWIN_DRM_DISABLE_TRIPLE_BUFFERING is already set."
	else
		echo "KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1" | sudo tee -a /etc/environment >/dev/null
		echo "Added KWIN_DRM_DISABLE_TRIPLE_BUFFERING=1 to /etc/environment"
	fi
}

# Returns 0 if the running kernel is >= 6.14 (minimum for NTSync).
check_ntsync_kernel() {
	local kver major minor
	kver=$(uname -r | grep -oE '^[0-9]+\.[0-9]+')
	major=$(echo "$kver" | cut -d. -f1)
	minor=$(echo "$kver" | cut -d. -f2)
	((major > 6 || (major == 6 && minor >= 14)))
}

# Returns 0 if the running kernel was built with CONFIG_NTSYNC=y or =m.
check_ntsync_kconfig() {
	local config_file="/boot/config-$(uname -r)"
	if [[ -r "$config_file" ]]; then
		grep -qE '^CONFIG_NTSYNC=[ym]' "$config_file" && return 0
	elif [[ -r /proc/config.gz ]]; then
		zgrep -qE '^CONFIG_NTSYNC=[ym]' /proc/config.gz && return 0
	else
		# Can't verify config, fall back to checking if the module/device is present.
		[[ -e /dev/ntsync ]] && return 0
		modinfo ntsync &>/dev/null && return 0
	fi
	return 1
}

setup_gaming_config() {
	log "Configuring gaming environment (GameMode group, NTSync)..."
	if ! ask_prompt "Do you want to apply gaming-specific configuration?"; then
		error "Action cancelled..."
		return 0
	fi

	# --- Add user to the gamemode group ---
	if id -nG "$USER" | grep -qw "gamemode"; then
		echo "User '$USER' is already in the gamemode group."
	elif getent group gamemode &>/dev/null; then
		sudo usermod -aG gamemode "$USER"
		echo "Added '$USER' to the gamemode group. Reboot/re-login for this to take effect."
	else
		error "The 'gamemode' group doesn't exist yet - is the gamemode package installed? (run -p or full setup first)"
	fi

	# --- NTSync ---
	log "Checking NTSync support..."
	if ! check_ntsync_kernel; then
		echo "Kernel $(uname -r) is older than 6.14 - NTSync isn't available, skipping."
		return 0
	fi
	if ! check_ntsync_kconfig; then
		echo "Kernel $(uname -r) wasn't built with CONFIG_NTSYNC - NTSync isn't available, skipping."
		return 0
	fi

	echo "Kernel supports NTSync."
	if lsmod | grep -qi '^ntsync'; then
		echo "ntsync module is already loaded."
	else
		if [[ -f /etc/modules-load.d/ntsync.conf ]] && grep -qx "ntsync" /etc/modules-load.d/ntsync.conf; then
			echo "ntsync is already configured to load at boot."
		else
			echo "ntsync" | sudo tee /etc/modules-load.d/ntsync.conf >/dev/null
			echo "Created /etc/modules-load.d/ntsync.conf so ntsync loads on every boot."
		fi

		if sudo modprobe ntsync 2>/dev/null; then
			echo "ntsync module loaded for this session."
		else
			error "Couldn't load ntsync right now - it will load automatically on next boot."
		fi
	fi

	log "Verify anytime with: lsmod | grep -i ntsync"
}

full_setup() {
	check_root
	clear
	log "Starting full Arch Linux post-installation setup..."

	# Show every step once, up front, yay-exclude style, instead of
	# asking Y/n before each individual function.
	local -A excluded_steps=()
	select_exclusions STEP_NAMES "steps" excluded_steps

	echo
	log "Running selected steps..."
	ASSUME_YES=true

	for i in "${!STEP_NAMES[@]}"; do
		local idx=$((i + 1))
		if [[ -n "${excluded_steps[$idx]}" ]]; then
			echo -e "${RED}[-]${NC} Skipping: ${STEP_NAMES[$i]}"
			continue
		fi
		"${STEP_FUNCS[$i]}"
	done

	ASSUME_YES=false
	log "Setup completed! Please reboot your system to ensure all changes take effect."
}

while getopts "sapmlhfkg" opt; do
	case $opt in
	s)
		full_setup
		;;
	a)
		check_root
		setup_aur_packages
		;;
	p)
		check_root
		setup_packages
		;;
	m)
		check_root
		setup_multilib
		;;
	l)
		check_root
		setup_locales
		;;
	f)
		check_root
		setup_fish_shell
		;;
	k)
		check_root
		setup_kwin_tweaks
		;;
	g)
		check_root
		setup_gaming_config
		;;
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

if [[ $# -eq 0 ]]; then
	display_help
fi