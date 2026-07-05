set --global zap_data $HOME/.local/zap

function __print_zap_installed_packages
    command zap list --no-color
end

function __print_zap_packages
    command cat $ZAP_PACKAGES_LOCAL_INDEX
end


complete -c zap -s h -l help -d "Show help information"
complete -c zap -s v -l version -d "Show version information"

set -l zap_commands \
    "list:List available or installed app images" \
    "search:Search for app images" \
    "install:Install an app image" \
    "upgrade:Updates all AppImages" \
    "update:Update installed app images" \
    "switch:Change version of installed app images" \
    "remove:Remove an installed app image" \
    "init:Configure zap interactively" \
    "daemon:Runs a daemon which periodically checks for updates for installed appimages" \
    "help:Show help information"

for cmd in $zap_commands
    set -l command (string split ':' $cmd)
    complete -c zap -n __fish_use_subcommand -a "$command[1]" -d "$command[2]" -f
end


set -l installed_pkg_commands update switch remove

for cmd in $installed_pkg_commands
    complete -c zap -n "__fish_seen_subcommand_from $cmd" -a "(__print_zap_installed_packages)" -f
end

complete -c zap -n "__fish_seen_subcommand_from install" -a "(__print_zap_packages)" -f

set -l install_flags \
    "executable:Name of the executable" \
    "from:Provide a repository slug, or a direct URL to an appimage." \
    "github:Use --from as repository slug to fetch from GitHub" \
    "select-first:Disable all prompts, and select the first item from the prompt if there are more than one choice." \
    "update:Update installed apps while updating metadata." \
    "silent:Do not ask interactive questions, and produce less logging" \
    "no-interactive:Do not ask interactive questions, and produce less logging" \
    "no-filter:Show all appimages regardless of architecture"

for flag in $install_flags
    set -l parts (string split ":" $flag)
    complete -c zap -n '__fish_seen_subcommand_from install' -l $parts[1] -d $parts[2]
end

set -l update_flags \
    "executable:Name of the executable which would be used as the unique identifier of the appimage on your system" \
    "select-first:Disable all prompts, and select the first item from the prompt if there are more than one choice." \
    "with-au:Use AppImageUpdate to delta update your appimage using zsync." \
    "with-appimageupdate:Use AppImageUpdate to delta update your appimage using zsync." \
    "appimageupdate:Use AppImageUpdate to delta update your appimage using zsync." \
    "au:Use AppImageUpdate to delta update your appimage using zsync." \
    "force-remove:Force a remove of a package before updating it" \
    "silent:Do not ask interactive questions, and produce less logging" \
    "no-interactive:Do not ask interactive questions, and produce less logging" \
    "no-filter:Show all appimages regardless of architecture"

for flag in $update_flags
    set -l parts (string split ":" $flag)
    complete -c zap -n '__fish_seen_subcommand_from update' -l $parts[1] -d $parts[2]
end

complete -c zap -n '__fish_seen_subcommand_from list' -l no-color -d 'Do not show AppImage executable names in color'
complete -c zap -n '__fish_seen_subcommand_from list' -l index -d ''
