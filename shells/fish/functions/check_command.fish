function check_command --description 'Check if a command exists'
    set program $argv[1]

    if not type -q $program
        echo "Error: $program command not found"
        return 1
    end
end
