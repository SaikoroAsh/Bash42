_help42_plain()
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
    echo -e "  ║   ${CYANB} gsc  :${WHITE} Select files, enter a message, commit and push${CYAN} ${NEW}           ║"
    echo -e "  ║   ${CYANB} gre  :${WHITE} Relink your local repo to a a new remote${CYAN}                       ║"
    echo -e "  ║   ${CYANB} gb   :${WHITE} Run git branch${CYAN}                                                 ║"
    echo -e "  ║   ${CYANB} gbr  :${WHITE} Interface your git branches${CYAN} ${UPDATED}                          ║"
    echo -e "  ║   ${CYANB} gbc  :${WHITE} Creates a new branch${CYAN} ${NEW}                                     ║"
    echo -e "  ║   ${CYANB} gav  :${WHITE} Show local and remote branches with last commit${CYAN} ${NEW}          ║"
    echo -e "  ║   ${CYANB} grpo :${WHITE} Update the remote branches from origin${CYAN} ${NEW}                   ║"
    echo -e "  ║   ${CYANB} grv  :${WHITE} Display the SSH link of the repo${CYAN} ${NEW}                         ║"

    echo "  ║                                                                          ║"
    echo -e "  ║   ${WHITEB}[Terminal and Tools:]${CYAN}                                                  ║"
    echo "  ║                                                                          ║"
    echo -e "  ║   ${CYANB} nav  :${WHITE} Interactive directory navigator${CYAN} ${UPDATED}                      ║"
    echo -e "  ║   ${CYANB} cpal :${WHITE} Select ANSI 256 colors and text styles${CYAN} ${NEW}                   ║"
    echo -e "  ║   ${CYANB} iph  :${WHITE} Analyze IP/mask (network, broadcast, host range)${CYAN} ${NEW}         ║"
    echo -e "  ║   ${CYANB} mask :${WHITE} Reference table of all /1-/32 subnet masks.${CYAN} ${NEW}              ║"
    echo -e "  ║   ${CYANB} fdata:${WHITE} Shows the path of the 20 most datavore directories${CYAN}             ║"
    echo -e "  ║   ${CYANB} fm   :${WHITE} Opens a new file manager windows for the given path${CYAN} ${NEW}      ║"
    echo -e "  ║   ${CYANB} hub  :${WHITE} Open hub links for 42 websites ${CYAN} ${NEW}                          ║"
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

_help42_load_entries()
{
    HELP42_NAMES=()
    HELP42_SHORTS=()
    HELP42_GUIDES=()
    HELP42_CATEGORIES=()

    local entries=(
        "ccw|Compile C files with the project moulinette flags|Compile the current C project with Bash42's usual moulinette flow. It is the standard quick build/validation step before a review or test run."
        "ff|Run Norminette on the current project|Run the 42 style checker on the code in the current folder. This catches formatting and rule violations before submission."
        "v|Open Vim|Launch Vim in the current directory so you can edit the active project file. Use it for fast C or shell editing when you do not want a full IDE."
        "vh|Open Vim with the 42 header template|Open Vim preloaded with the standard 42 header template so you can fill in the project metadata before coding."
        "a|Run the compiled program|Execute the generated executable from the current project. This is the usual way to test a C binary after compilation."
        "rv|Run review preparation checks|Runs the checks commonly used before a 42 review: compile, sanitize, and inspect the project state to catch obvious errors early."
        "p|Run a Python file with Python 3|Execute the current Python script with python3. This is the default quick test command for small scripts and project entry points."
        "ffp|Check Python files with mypy and flake8|Validate Python code with the static tools used in Bash42. It helps catch type issues and style violations before finalizing work."
        "pcc|Remove Python cache directories|Delete __pycache__ and .mypy_cache folders under the selected path. Use -n or --dry-run to preview matches without deleting anything."
        "cve|Create a Python virtual environment|Create a local venv in the current directory or in a target path, so dependencies stay isolated from the system Python."
        "on|Activate a Python virtual environment|Source a venv so your shell uses the project-specific Python environment and installed packages."
        "off|Deactivate the active virtual environment|Return the shell to the system Python environment after you are done working in the project virtualenv."
        "gg|Stage files by extension and commit|Collect files matching a given extension, stage them, and open your commit editor. Useful when you want to commit only a subset of files by type."
        "ga|Stage specific files|Add exact files you pass as arguments to the index. This is the most precise staging command for a selective commit."
        "gaa|Stage all changes|Add all tracked and untracked modifications with git add --all so the working tree is fully staged for a commit."
        "gu|Stage modified and deleted tracked files|Stage updates and removals for tracked files without adding new untracked items. Useful for a focused save before a commit."
        "gs|Show repository status|Display the current branch, tracked changes, staged files, and untracked files so you know exactly what is pending."
        "gpom|Push the main branch to origin|Quickly push the main branch to the default remote, useful when your project workflow keeps main as the public branch."
        "gp|Push the current branch|Push the branch currently checked out, without forcing the branch name to main. This is the default branch-safe push command."
        "gc|Clone a Git repository|Clone a remote repository and keep the standard workflow short and predictable. Useful when you want to start from an existing project quickly."
        "gcd|Clone a repo and enter it|Clone a repository and immediately move into the created directory, reducing the setup steps between cloning and editing."
        "gd|Commit and push directly|Create a commit with the given message and immediately push it upstream. Good for quick save-and-sync work."
        "gsc|Interactive commit helper|Select files, write a commit message, and push from a full-screen Bash UI. This is the guided git workflow for people who prefer a menu over raw Git commands."
        "gre|Relink a repo to a new remote|Remove the old origin and add a new one, then set upstream on the main branch so the repo points to the correct remote."
        "gb|List branches|Display the branch list for the current repository so you can keep track of your local environment."
        "gbr|Browse and manage branches|Open a full-screen branch browser to move around local branches, inspect their state, merge them, or delete them safely."
        "gbc|Create and switch to a new branch|Create a new locally named branch and immediately check it out so the next work happens in the correct context."
        "gav|Show local and remote branch activity|List branches together with recent commit info, which helps spot what is stale or recently changed."
        "grpo|Prune stale remote references|Clean up remote-tracking branches that no longer exist on the remote, keeping git status and fetch results easier to follow."
        "grv|Show remote URLs|Display the configured Git remote URLs, useful when you need to verify the repo is linked to the right origin."
        "nav|Interactive directory navigator|Browse the filesystem in a small terminal menu and jump to folders without manually typing long paths every time."
        "cpal|Browse ANSI colours and text styles|Open a palette selector for terminal colours, bold text, reverse video, and other display styles for Bash source editing."
        "iph|Analyze an IP and subnet|Resolve IP addresses, masks, network addresses, broadcast addresses, and host ranges in one compact helper."
        "mask|Subnet mask reference table|Print the full /1 through /32 mask table so you can quickly reference CIDR values without memorizing them."
        "fdata|List the biggest directories under home|Show the largest directories in /home/$USER so you can find heavy folders and clean up space quickly."
        "fm|Open a file manager window|Launch a graphical file manager on the selected path so you can interact visually. This is handy when you want a quick visual browser."
        "hub|Browse 42 links|Open the main 42 websites and dashboards from a command-line menu, saving you from remembering each URL."
        "vsc|Open the current directory in VS Code|Launch VS Code from the command line so the project opens directly in your editor without a manual path selection."
        "cln|Remove build and cache artifacts|Delete generated binaries, Python caches, and related temporary files to keep the project tree clean. Add -v or -venv to also remove virtual environments."
        "help42|Browse Bash42 commands and guides|Open the interactive Bash42 help browser. It is the guided way to explore commands and their usage without scanning the whole file manually."
        "b42|Update Bash42|Download the latest version of the Bash42 configuration and reload it in the current shell context."
        "max42|Enable the large welcome banner|Turn on the expanded welcome display when you want the full Bash42 intro to appear at shell startup."
        "min42|Enable the compact welcome banner|Switch Bash42 back to the smaller startup banner for a cleaner terminal at login."
        "mute42|Disable the welcome banner|Turn off the Bash42 startup banner completely when you prefer a minimal prompt at shell launch."
        "sl|Open the Bash42 project page|Quick shortcut to the project's repository page so you can share, browse, or visit the project from the shell."
    )

    local item name short guide category
    for item in "${entries[@]}"; do
        IFS='|' read -r name short guide <<< "$item"
        case $name in
            ccw|ff|v|vh|a|rv) category='C Editor & Compilation' ;;
            p|ffp|pcc|cve|on|off) category='Python' ;;
            gg|ga|gaa|gu|gs|gpom|gp|gc|gcd |gd|gsc|gre|gb|gbr|gbc|gav|grpo|grv) category='Git' ;;
            nav|cpal|iph|mask|fdata|fm|hub|vsc|cln) category='Terminal and Tools' ;;
            *) category='Bash42' ;;
        esac
        HELP42_NAMES+=("$name")
        HELP42_SHORTS+=("$short")
        HELP42_GUIDES+=("$guide")
        HELP42_CATEGORIES+=("$category")
    done
}

_help42_interactive()
{
    _help42_load_entries

    local R=$'\e[0m' B=$'\e[1m' D=$'\e[2m' CYN=$'\e[36m'
    local BG=$'\e[48;5;237m' WHITE=$'\e[1;37m'
    local cur=0 top=0 i idx end cols rows list_rows left_w right_w k rest n
    local selected_guide entry_label guide_text rule txt fill bg ptr line category previous_category selected_row row_count
    local -a guide_lines=()
    local -a row_types=() row_indices=() row_labels=()

    n=${#HELP42_NAMES[@]}
    previous_category=""
    for (( idx = 0; idx < n; idx++ )); do
        category=${HELP42_CATEGORIES[$idx]}
        if [[ $category != "$previous_category" ]]; then
            row_types+=(category)
            row_indices+=(-1)
            row_labels+=("$category")
            previous_category=$category
        fi
        row_types+=(command)
        row_indices+=($idx)
        row_labels+=("${HELP42_NAMES[$idx]}")
    done
    row_count=${#row_types[@]}

    old=$(stty -g 2>/dev/null || echo '')
    stty_old="$old"
    stty -echo -isig 2>/dev/null || true
    tput smcup 2>/dev/null || true
    tput civis 2>/dev/null || true

    trap '_help42_cleanup "$stty_old"' EXIT INT TERM

    while true; do
        cols=$(tput cols 2>/dev/null || echo 80)
        rows=$(tput lines 2>/dev/null || echo 24)

        left_w=$(( cols / 3 ))
        (( left_w < 30 )) && left_w=30
        (( left_w > 36 )) && left_w=36
        right_w=$(( cols - left_w - 4 ))
        (( right_w < 10 )) && right_w=10
        list_rows=$(( rows - 6 ))
        (( list_rows < 3 )) && list_rows=3
        selected_row=0
        for (( idx = 0; idx < row_count; idx++ )); do
            if [[ ${row_types[$idx]} == command ]] && (( row_indices[idx] == cur )); then
                selected_row=$idx
                break
            fi
        done
        (( selected_row < top )) && top=$selected_row
        (( selected_row >= top + list_rows )) && top=$(( selected_row - list_rows + 1 ))
        if (( top > 0 && selected_row < top + list_rows - 1 )) && [[ ${row_types[$top]} == command && ${row_types[$((top - 1))]} == category ]]; then
            (( top-- ))
        fi
        end=$(( top + list_rows )); (( end > row_count )) && end=$row_count

        selected_guide="${HELP42_GUIDES[$cur]}"
        guide_lines=()
        while IFS= read -r guide_text; do
            guide_lines+=("$guide_text")
        done < <(printf '%s\n' "$selected_guide" | fold -sw "$(( right_w - 1 ))")

        printf '\e[H\e[J'
        printf ' %s%shelp42%s  %s%d/%d%s\n' "$B" "$CYN" "$R" "$D" "$((cur + 1))" "$n" "$R"
        printf -v rule '%*s' $(( cols - 2 )) ''
        rule=${rule// /─}
        printf ' %s%s%s\n' "$D" "$rule" "$R"

        for (( i = 0; i < list_rows; i++ )); do
            idx=$(( top + i ))
            if (( idx < row_count )); then
                if [[ ${row_types[$idx]} == category ]]; then
                    category=${row_labels[$idx]}
                    printf '  %s%s[%s]%s' "$B" "$WHITE" "$category" "$R"
                    printf '%*s' $(( left_w - ${#category} - 4 )) ''
                else
                    entry_label=${row_labels[$idx]}
                    bg=""
                    ptr=" "
                    if (( row_indices[idx] == cur )); then
                        bg=$BG
                        ptr="${CYN}▌"
                    fi
                    line="${bg} ${ptr}${R}${bg}  ${CYN}${B}${entry_label}${R}${bg}"
                    printf '%s' "$line"
                    printf '%*s' $(( left_w - ${#entry_label} - 4 )) ''
                fi
            else
                printf '    '
                printf '%*s' "$(( left_w - 4 ))" ''
            fi
            printf ' %s│%s ' "$CYN" "$R"
            if (( i < ${#guide_lines[@]} )); then
                printf '%s\n' "${guide_lines[$i]}"
            else
                printf '\n'
            fi
        done

        txt=""
        (( top > 0 )) && txt+="↑ $top more  "
        (( end < row_count )) && txt+="↓ $(( row_count - end )) more"
        if [[ -n $txt ]]; then
            fill=$(( cols - 6 - ${#txt} )); (( fill < 0 )) && fill=0
            printf -v rule '%*s' "$fill" ''; rule=${rule// /─}
            printf ' %s── %s %s%s\n' "$D" "$txt" "$rule" "$R"
        else
            printf ' %s%s%s\n' "$D" "${rule}" "$R"
        fi
        printf ' %s↑↓%s%s move%s  %sq%s%s quit%s\n' "$B" "$R" "$D" "$R" "$B" "$R" "$D" "$R"

        IFS= read -rsn1 k || break
        if [[ $k == $'\033' ]]; then
            IFS= read -rsn2 -t 0.05 rest || true
            case $rest in
                '[A') k=UP ;;
                '[B') k=DOWN ;;
                '[C') k=RIGHT ;;
                '[D') k=LEFT ;;
                *) k=ESC ;;
            esac
        fi

        case $k in
            UP|k) (( cur > 0 )) && (( cur-- )) ;;
            DOWN|j) (( cur < n - 1 )) && (( cur++ )) ;;
            q|Q|$'\x03'|ESC) break ;;
            '')
                _help42_cleanup "$stty_old"
                trap - EXIT INT TERM
                _help42_plain
                return 0
                ;;
        esac
    done

    _help42_cleanup "$stty_old"
    trap - EXIT INT TERM
}

_help42_cleanup()
{
    local stty_old="$1"
    tput cnorm 2>/dev/null || true
    tput rmcup 2>/dev/null || true
    if [[ -n "$stty_old" ]]; then
        stty "$stty_old" 2>/dev/null || stty sane 2>/dev/null || true
    fi
}

help42()
{
    if [[ "$1" == "--plain" || "$1" == "-p" || "$1" == "--help" || "$1" == "-h" ]]; then
        _help42_plain
        return 0
    fi

    if [[ ! -t 0 || ! -t 1 ]]; then
        _help42_plain
        return 0
    fi

    _help42_interactive
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

