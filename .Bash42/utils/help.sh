help42()
{
    # Colors
    WHITEB='\033[1;37m'
    CYAN='\033[0;36m'
    CYANB='\033[1;36m'
    RED='\033[0;31m'
    WHITE='\033[0;37m'
    GREEN='\033[0;32m'
    GREEN_NEW='\033[5;38;5;2m'
    MAGENTA='\033[0;35m'
    RESET='\033[0m'

    # Tag
    NEW="${GREEN_NEW}[new]${CYAN}"
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
    echo -e "  ║   ${CYANB} pcc :${WHITE} Remove Python cache dirs (arg: path, -n dry-run)${CYAN}                ║"
    echo -e "  ║   ${CYANB} cve :${WHITE} Creates a venv (arg 1 = name)${CYAN}                                   ║"
    echo -e "  ║   ${CYANB} on  :${WHITE} Sources venv (arg 1 = name)${CYAN}                                     ║"
    echo -e "  ║   ${CYANB} off :${WHITE} Deactivates venv${CYAN}                                                ║"


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
    echo -e "  ║   ${CYANB} gb   :${WHITE} Run git branch${CYAN}                                                 ║"
    echo -e "  ║   ${CYANB} gbr  :${WHITE} Interface your git branches${CYAN}                                    ║"
    echo -e "  ║   ${CYANB} gbc  :${WHITE} Creates a new branch${CYAN} ${NEW}                                     ║"
    echo -e "  ║   ${CYANB} gav  :${WHITE} Show local and remote branches with last commit${CYAN} ${NEW}          ║"
    echo -e "  ║   ${CYANB} grpo :${WHITE} Update the remote branches from origin${CYAN} ${NEW}                   ║"
    echo -e "  ║   ${CYANB} grv  :${WHITE} Display the SSH link of the repo${CYAN} ${NEW}                         ║"


    echo "  ║                                                                          ║"
    echo -e "  ║   ${WHITEB}[Terminal and Tools:]${CYAN}                                                  ║"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${CYANB} nav  :${WHITE} Interactive directory navigator${CYAN}                                ║"
    echo -e "  ║   ${CYANB} cpal :${WHITE} Select ANSI 256 colors and text styles${CYAN} ${NEW}                   ║"
    echo -e "  ║   ${CYANB} iph  :${WHITE} Analyze IP/mask (network, broadcast, host range)${CYAN} ${NEW}         ║"
    echo -e "  ║   ${CYANB} mask :${WHITE} Reference table of all /1-/32 subnet masks.${CYAN} ${NEW}              ║"
    echo -e "  ║   ${CYANB} fdata:${WHITE} Shows the path of the 20 most datavore directories${CYAN}             ║"
    echo -e "  ║   ${CYANB} fm   :${WHITE} Opens a new file manager windows for the given path${CYAN} ${NEW}      ║"
    echo -e "  ║   ${CYANB} vsc  :${WHITE} Opens vscode for the given path${CYAN} ${NEW}                          ║"
    echo -e "  ║   ${CYANB} cln  :${WHITE} Removes a.out files, __pycache__, and .mypy_cache dirs.${CYAN} ${NEW}  ║"
    echo -e "  ║   ${CYANB}    -v / -venv :${WHITE} this flag remove the venv as well ${CYAN} ${NEW}              ║"


    echo -e "  ║                                                                          ║"
    echo -e "  ║   ${WHITEB}[Bash42:]${CYAN}                                                              ║"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${CYANB} help42:${WHITE} Shows this help page${CYAN}                                          ║"
    echo -e "  ║   ${CYANB} b42   :${WHITE} Update to the latest version${CYAN}                                  ║"
    echo -e "  ║   ${CYANB} max42 :${WHITE} Set the big welcome banner${CYAN}                                    ║"
    echo -e "  ║   ${CYANB} min42 :${WHITE} Set the compact welcome banner${CYAN}                                ║"
    echo -e "  ║   ${CYANB} mute42:${WHITE} Disable the welcome banner${CYAN}                                    ║"
    echo -e "  ║   ${CYANB} sl    :${WHITE} Same as ls but if you're not so good with your keyboard${CYAN}       ║"


    echo "  ║                                                                          ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# Remove Python caches: __pycache__ and .mypy_cache
pcc()
{
    local dry=0
    local path="."
    if [ "$1" = "-n" ] || [ "$1" = "--dry-run" ]; then
        dry=1
        shift
    fi
    if [ -n "$1" ]; then
        path="$1"
    fi
    if [ "$dry" -eq 1 ]; then
        find "$path" -type d \( -name "__pycache__" -o -name ".mypy_cache" \) -print
        return
    fi
    # Delete matched directories safely using null delimiters
    find "$path" -type d \( -name "__pycache__" -o -name ".mypy_cache" \) -print0 | xargs -0 -r rm -rf --
    echo "Removed Python cache directories under: $path"
}

