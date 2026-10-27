function git-setup -d "Setup Git configuration quickly"
    if not command -v git >/dev/null
        echo "Error: Git is not installed. Please install Git first."
        return 1
    end

    read -p "echo 'Enter your Git user name: '" -l name
    read -p "echo 'Enter your Git email: '" -l email

    if test -z "$name" || test -z "$email"
        echo "Error: Name and email are required."
        return 1
    end

    git config --global user.name "$name"
    git config --global user.email "$email"

    git config --global init.defaultBranch main
    git config --global pull.rebase false

    echo "Git configuration has been set up successfully!"
end