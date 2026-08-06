abbr refish "source ~/.config/fish/config.fish"
abbr cfish "find ~/.config/fish/ -maxdepth 1 -name 'fish_variables*' -not -name 'fish_variables' -delete -print"

# -------------------- Shell Helper Abbreviations --------------------
abbr --position anywhere --add fnull "&> /dev/null" # Pipe everything to /dev/null
abbr --position anywhere --add fb "| bat"
