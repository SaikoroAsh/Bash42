__bash42_welcome_mode_file()
{
    echo "$HOME/.Bash42/.welcome_mode"
}

__bash42_set_welcome_mode()
{
    local mode="$1"
    local mode_file

    mode_file="$(__bash42_welcome_mode_file)"
    printf "%s\n" "$mode" > "$mode_file"
}

__bash42_get_welcome_mode()
{
    local mode_file

    mode_file="$(__bash42_welcome_mode_file)"
    if [[ -f "$mode_file" ]]; then
        cat "$mode_file"
    else
        echo "max"
    fi
}

__bash42_welcomebash42_big()
{
    # Colors
    WHITE='\033[0;38;5;231m'
    CYAN='\033[0;36m'
    PURPLE='\033[38;5;135m'
    RED='\033[0;31m'
    WHITEB='\033[1;38;5;231m'
    GREEN='\033[0;32m'
    RESET='\033[0m'

    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${WHITEB}██╗    ██╗███████╗██╗      ██████╗ ██████╗ ███╗   ███╗███████╗${CYAN}         ║"
    echo -e "  ║   ${WHITEB}██║    ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗ ████║██╔════╝${CYAN}         ║"
    echo -e "  ║   ${WHITEB}██║ █╗ ██║█████╗  ██║     ██║     ██║   ██║██╔████╔██║█████╗  ${CYAN}         ║"
    echo -e "  ║   ${WHITEB}██║███╗██║██╔══╝  ██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝  ${CYAN}         ║"
    echo -e "  ║   ${WHITEB}╚███╔███╔╝███████╗███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║███████╗${CYAN}         ║"
    echo -e "  ║   ${WHITEB} ╚══╝╚══╝ ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝${CYAN}         ║"
    echo "  ║                                                                          ║"
    echo -e "  ║  ${WHITEB} ████████╗ ██████╗ ${CYAN}   ${CYAN}██████╗  █████╗ ███████╗██╗  ██╗██╗  ██╗██████╗ ${CYAN}  ║"
    echo -e "  ║  ${WHITEB} ╚══██╔══╝██╔═══██╗${CYAN}   ${CYAN}██╔══██╗██╔══██╗██╔════╝██║  ██║██║  ██║╚════██╗${CYAN}  ║"
    echo -e "  ║  ${WHITEB}    ██║   ██║   ██║${CYAN}   ${CYAN}██████╔╝███████║███████╗███████║███████║ █████╔╝${CYAN}  ║"
    echo -e "  ║  ${WHITEB}    ██║   ██║   ██║${CYAN}   ${CYAN}██╔══██╗██╔══██║╚════██║██╔══██║╚════██║██╔═══╝${CYAN}   ║"
    echo -e "  ║  ${WHITEB}    ██║   ╚██████╔╝${CYAN}   ${CYAN}██████╔╝██║  ██║███████║██║  ██║     ██║███████╗${CYAN}  ║"
    echo -e "  ║  ${WHITEB}    ╚═╝    ╚═════╝ ${CYAN}   ${CYAN}╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝     ╚═╝╚══════╝${CYAN}  ║"
    echo "  ║                                                                          ║"
    echo -e "  ║         ${WHITEB} For Help: help42                       To Update: b42 ${CYAN}          ║"
    echo "  ║                                                                          ║"

    echo "  ╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "                     ${WHITE} by: SaikoroAsh & osavarin & LMuny ${CYAN}                      "

    echo -e "${RESET}"
}

__bash42_welcomebash42_small()
{
    local CYAN='\033[0;36m'
    local WHITEB='\033[1;38;5;231m'
    local WHITE='\033[3;37m'
    local PURPLE='\033[38;5;135m'
    local RESET='\033[0m'

    echo -e "${CYAN}  ╔═══════════════════════════════╗"
    echo -e "  ║       ${WHITEB}WELCOME TO ${CYAN}BASH42${CYAN}       ║"
    echo -e "  ║      ${WHITE}help42 for commands${CYAN}      ║"
    echo -e "  ╚═══════════════════════════════╝${RESET}"
}

welcomebash42()
{
    local mode
    local force="$1"

    if [[ "$force" != "--force" && -n "${BASH42_WELCOME_SHOWN:-}" ]]; then
        return
    fi

    BASH42_WELCOME_SHOWN=1
    export BASH42_WELCOME_SHOWN

    mode="$(__bash42_get_welcome_mode)"

    case "$mode" in
        mute)
            ;;
        min)
            __bash42_welcomebash42_small
            ;;
        *)
            __bash42_welcomebash42_big
            ;;
    esac
}

max42()
{
    __bash42_set_welcome_mode "max"
    welcomebash42 --force
}

min42()
{
    __bash42_set_welcome_mode "min"
    welcomebash42 --force
}

mute42()
{
    __bash42_set_welcome_mode "mute"
}
