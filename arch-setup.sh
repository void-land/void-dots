#!/bin/bash

# Arch Linux Post Installation Setup Script

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

declare -a ORDERS_LIST=(
	"BASE_PACKAGES"
	"AUDIO_PACKAGES"
	"GPU_DRIVERS"
	"GAMING_PACKAGES"
	"UTILITIES"
	"FONTS"
)

declare -A PACKAGES_LIST=(
	["UTILITIES"]="alacritty evince htop btop stress-ng cpu-x"
	["BASE_PACKAGES"]="base-devel fish tmux bandwhich jq git curl axel xz zstd fzf networkmanager bluez bluez-utils xdg-utils wl-clipboard"
	["AUDIO_PACKAGES"]="pipewire wireplumber pipewire-pulse pipewire-alsa pipewire-jack pavucontrol"
	["GPU_DRIVERS"]="mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader vulkan-mesa-layers vulkan-extra-layers vulkan-tools xf86-video-amdgpu"
	["GAMING_PACKAGES"]="steam gamescope mangohud gamemode lib32-mangohud lib32-gamemode"
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
	while true; do
		read -p "$question (Y/n) [Y]: " choice
		case "$choice" in
		[Yy] | "") return 0 ;;
		[Nn]) return 1 ;;
		*) echo "Please enter Y or N (or press Enter for Yes)." ;;
		esac
	done
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
	local packages_list=""
	for order in "${ORDERS_LIST[@]}"; do
		packages_list+="${PACKAGES_LIST["$order"]} "
	done

	log "Following package groups will be installed:"
	echo -e "$packages_list\n"

	if ! ask_prompt "Do you want to continue with installation?"; then
		error "Action cancelled..."
		return 0
	fi

	log "Installing packages..."
	sudo pacman -S --noconfirm $packages_list
}

setup_aur_packages() {
	local packages_list=""
	for package in "${AUR_PACKAGES[@]}"; do
		packages_list+="${package} "
	done

	log "Following AUR package groups will be installed:"
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

full_setup() {
	check_root
	clear
	log "Starting full Arch Linux post-installation setup..."

	update_system
	setup_multilib
	setup_packages
	setup_services
	setup_user_services
	setup_aur_packages
	setup_locales
	setup_fish_shell
	setup_kwin_tweaks

	log "Setup completed! Please reboot your system to ensure all changes take effect."
}

while getopts "sapmlhfk" opt; do
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
