alias bmax="ddcutil setvcp 10 100 --noverify"
alias bmin="ddcutil setvcp 10 10 --noverify"

bright() {
    ddcutil setvcp 10 $1 --noverify
}
