help42()
{
    # Colors
    WHITEB='\033[1;37m'
    CYAN='\033[0;36m'
    CYANB='\033[1;36m'
    RED='\033[0;31m'
    WHITE='\033[0;37m'
    GREEN='\033[0;32m'
    MAGENTA='\033[0;35m'
    RESET='\033[0m'

    # Tag
    NEW="${GREEN}[new]${CYAN}"
    UPDATED="${MAGENTA}[updated]${CYAN}"

    echo -e "${CYAN}"
    echo "  ╔══════════════════════════════════════════════════════════════════════════╗"
    echo -e "  ║                                ${WHITEB}[HELP 42]${CYAN}                                 ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════════╝"
    echo "  ╔══════════════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                          ║"


    echo -e "  ║   ${WHITEB}[C Editor & Compilation:]${CYAN}                                              ║"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${CYANB} ccw :${WHITE} Compile with all moulinette flags${CYAN}                               ║"
    echo -e "  ║   ${CYANB} ff  :${WHITE} Run the norminette${CYAN}                                              ║"
    echo -e "  ║   ${CYANB} v   :${WHITE} Open vim ${CYAN}                                                       ║"
    echo -e "  ║   ${CYANB} vh  :${WHITE} Open vim with header 42 ${CYAN}                                        ║"
    echo -e "  ║   ${CYANB} a   :${WHITE} Execute the a.out file${CYAN}                                          ║"
    echo -e "  ║   ${CYANB} rv  :${WHITE} Checks multiple things to prepare for a review${CYAN}                  ║"


    echo "  ║                                                                          ║"
    echo -e "  ║   ${WHITEB}[Python:]${CYAN}                                                              ║"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${CYANB} p   :${WHITE} Execute with python3${CYAN}                                            ║"
    echo -e "  ║   ${CYANB} ffp :${WHITE} Check .py with mypy and flake8${CYAN}                                  ║"


    echo "  ║                                                                          ║"
    echo -e "  ║   ${WHITEB}[Git:]${CYAN}                                                                 ║"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${CYANB} gg  :${WHITE} Git add files of your directory and sub-directories by ${CYAN}         ║"
    echo -e "  ║          ${WHITE} extensions and open a commit message window ${CYAN}                   ║"
    echo -e "  ║   ${CYANB} ga   :${WHITE} Run git add on provided files${CYAN}                                  ║"
    echo -e "  ║   ${CYANB} gaa  :${WHITE} Run git add --all${CYAN}                                              ║"
    echo -e "  ║   ${CYANB} gu   :${WHITE} Add all modified files${CYAN}                                         ║"
    echo -e "  ║   ${CYANB} gs   :${WHITE} Run git status${CYAN}                                                 ║"
    echo -e "  ║   ${CYANB} gpom :${WHITE} Run git push on the main branch${CYAN}                                ║"
    echo -e "  ║   ${CYANB} gp   :${WHITE} Run git push on the actual branch${CYAN}                              ║"
    echo -e "  ║   ${CYANB} gc   :${WHITE} Run git clone${CYAN}                                                  ║"
    echo -e "  ║   ${CYANB} gcd  :${WHITE} Git clone and go to the directory created${CYAN}                      ║"
    echo -e "  ║   ${CYANB} gd   :${WHITE} Commit to your git repo and pushes it directly${CYAN}                 ║"
    echo -e "  ║   ${CYANB} gre  :${WHITE} Relink your local repo to a a new remote${CYAN}                       ║"
    echo -e "  ║   ${CYANB} gbr  :${WHITE} Interface your git branches${CYAN}                                    ║"
    echo -e "  ║   ${CYANB} gav  :${WHITE} Show local and remote branches with last commit${CYAN} ${NEW}          ║"
    echo -e "  ║   ${CYANB} grpo :${WHITE} Update the remote branches from origin${CYAN} ${NEW}                   ║"

    echo "  ║                                                                          ║"
    echo -e "  ║   ${WHITEB}[Terminal and Tools:]${CYAN}                                                  ║"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${CYANB} nav  :${WHITE} Interactive directory navigator${CYAN}                                ║"
    echo -e "  ║   ${CYANB} iph  :${WHITE} Analyze IP/mask (network, broadcast, host range)${CYAN} ${NEW}         ║"
    echo -e "  ║   ${CYANB} mask :${WHITE} reference table of all /1-/32 subnet masks.${CYAN} ${NEW}              ║"
    echo -e "  ║   ${CYANB} fdata:${WHITE} Shows the path of the 20 most datavore directories${CYAN} ${UPDATED}   ║"


    echo -e "  ║                                                                          ║"
    echo -e "  ║   ${WHITEB}[Bash42:]${CYAN}                                                              ║"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${CYANB} help42:${WHITE} Shows this help page${CYAN} ${UPDATED}                                ║"
    echo -e "  ║   ${CYANB} b42   :${WHITE} Update to the latest version${CYAN}                                  ║"
    echo -e "  ║   ${CYANB} max42 :${WHITE} Set the big welcome banner${CYAN} ${NEW}                              ║"
    echo -e "  ║   ${CYANB} min42 :${WHITE} Set the compact welcome banner${CYAN} ${NEW}                          ║"
    echo -e "  ║   ${CYANB} mute42:${WHITE} Disable the welcome banner${CYAN} ${NEW}                              ║"
    echo -e "  ║   ${CYANB} sl    :${WHITE} Same as ls but if you're not so good with your keyboard${CYAN}       ║"


    echo "  ║                                                                          ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}
