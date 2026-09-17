function bsmax --description "Set maximum brightness"
    ddcutil setvcp 10 100 --noverify
end

function bsmin --description "Set minimum brightness"
    ddcutil setvcp 10 10 --noverify
end

function bs --description "Set brightness to a specific value. Usage: bs <brightness_value>"
    if test (count $argv) -ne 1
        echo "Error: Brightness value is required."

        echo "Usage: bs <brightness_value>"
        return 1
    end

    ddcutil setvcp 10 $argv[1] --noverify
end
