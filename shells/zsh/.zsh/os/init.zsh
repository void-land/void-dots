if [[ "$OS" = void ]]; then
    source ~/.zsh/os/_void.zsh
elif [[ "$OS" = debian ]]; then
    source ~/.zsh/os/_debian.zsh
fi
