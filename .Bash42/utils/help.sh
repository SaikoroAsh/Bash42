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
    echo -e "  ║   ${CYANB} ff  :${WHITE} Run the norminette ${CYAN}                                             ║"
    echo -e "  ║   ${CYANB} v   :${WHITE} Open vim ${CYAN}                                                       ║"
    echo -e "  ║   ${CYANB} vh  :${WHITE} Open vim with header 42 ${CYAN}                                        ║"
    echo -e "  ║   ${CYANB} a   :${WHITE} Execute the a.out file${CYAN}                                          ║"
    echo -e "  ║   ${CYANB} rv  :${WHITE} Checks multiple things to prepare for a review${CYAN}                  ║"


    echo "  ║                                                                          ║"
    echo -e "  ║   ${WHITEB}[Python:]${CYAN}                                                              ║"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${CYANB} p   :${WHITE} Execute with python3${CYAN}                                            ║"
    echo -e "  ║   ${CYANB} ffp :${WHITE} Check .py with mypy and flake8${CYAN} ${NEW}                            ║"


    echo "  ║                                                                          ║"
    echo -e "  ║   ${WHITEB}[Git:]${CYAN}                                                                 ║"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${CYANB} gg   :${WHITE} Add all the .c file of your directory and sub-directories ${CYAN}     ║"
    echo -e "  ║         ${WHITE} to git and open a commit message window ${CYAN}                        ║"
    echo -e "  ║   ${CYANB} gu   :${WHITE} Add all modified files${CYAN} ${NEW}                                   ║"
    echo -e "  ║   ${CYANB} gs   :${WHITE} Run git status${CYAN} ${NEW}                                           ║"
    echo -e "  ║   ${CYANB} gpom :${WHITE} Run git push on the main branch${CYAN}                                ║"
    echo -e "  ║   ${CYANB} gp   :${WHITE} Run git push on the actual branch${CYAN}                              ║"
    echo -e "  ║   ${CYANB} gc   :${WHITE} Run git clone${CYAN}                                                  ║"
    echo -e "  ║   ${CYANB} gcd  :${WHITE} Git clone and go to the directory created${CYAN}                      ║"
    echo -e "  ║   ${CYANB} gd   :${WHITE} Commit to your git repo and pushes it directly${CYAN} ${NEW}           ║"
    echo -e "  ║   ${CYANB} gre  :${WHITE} Relink your local repo to a a new remote${CYAN} ${NEW}                 ║"
    echo -e "  ║   ${CYANB} fdata:${WHITE} Shows the path of the 20 most datavore directories${CYAN} ${NEW}       ║"


    echo -e "  ║                                                                          ║"
    echo -e "  ║   ${WHITEB}[Bash42:]${CYAN}                                                              ║"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${CYANB} help42:${WHITE} Shows this help page${CYAN} ${UPDATED}                                ║"
    echo -e "  ║   ${CYANB} b42   :${WHITE} Update to the latest version${CYAN}                                  ║"
    echo -e "  ║   ${CYANB} sl    :${WHITE} Same as ls but if you're not so good with your keyboard${CYAN}       ║"


    echo "  ║                                                                          ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}
