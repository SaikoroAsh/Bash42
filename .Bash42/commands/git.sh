### Git ###

unalias gg 2>/dev/null
gg()
{
        if [[ $# == 0 ]]; then
                echo -e '\033[31mPlease specify a file extension like "c" "py"...\033[0m'
        else
                for arg in "$@"
                do
                        find . -name "*.$arg" -exec git add {} +
                done
                git commit
        fi
}


alias gu="git add -u"


alias gs="git status"


alias gpom="git push origin main"


alias gp="git push"


alias gc="git clone"

alias fdata='du -h /home/$USER | sort -hr | head -20'

gcd()
{
	    if [[ $# == 1 ]]; then
                git clone $1 && cd $(basename "$_" .git)
        elif [[ $# == 2 ]]; then
                git clone $1 $2 && cd $2
        elif [[ $# == 0 ]]; then
                echo -e '\033[31mPlease specify a git repository.\033[0m'
        fi
}


gd()
{
	git commit -m "$1"
	git push
}


gre()
{
	git remote remove origin && echo "Old remote deleted" || echo "Error: Suppression remote"
	git remote add origin "$1" && echo "New remote added" || echo "Error: Add remote"
	git push --set-upstream origin main && echo "Push done" || echo "Error: Push"
}

gbr() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "gbr: not a git repository" >&2
        return 1
    fi

    local branches=($(git branch 2>/dev/null | sed "s/\* //"))

    if [ ${#branches[@]} -eq 0 ]; then
        echo "gbr: no branches yet (no commits)" >&2
        return 1
    fi

    local current=$(git branch --show-current)
    local selected=0
    local count=${#branches[@]}

    for i in "${!branches[@]}"; do
        [[ "${branches[$i]}" == "$current" ]] && selected=$i
    done

    _gbr_cleanup() {
        tput cnorm
        trap - INT TERM EXIT
    }

    _gbr_draw() {
        tput cuu "$count" 2>/dev/null || true
        for i in "${!branches[@]}"; do
            local marker="  "
            [[ "${branches[$i]}" == "$current" ]] && marker="* "
            if [ "$i" -eq "$selected" ]; then
                echo -e "\e[7m > ${marker}${branches[$i]}\e[0m"
            else
                echo "   ${marker}${branches[$i]}"
            fi
        done
    }

    for i in "${!branches[@]}"; do
        local marker="  "
        [[ "${branches[$i]}" == "$current" ]] && marker="* "
        if [ "$i" -eq "$selected" ]; then
            echo -e "\e[7m > ${marker}${branches[$i]}\e[0m"
        else
            echo "   ${marker}${branches[$i]}"
        fi
    done

    trap '_gbr_cleanup; return 130' INT
    trap '_gbr_cleanup; return 143' TERM
    trap '_gbr_cleanup' EXIT
    tput civis

    while IFS= read -rsn1 key; do
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            case $key in
                '[A') ((selected > 0)) && ((selected--)) ;;
                '[B') ((selected < count - 1)) && ((selected++)) ;;
            esac
        elif [[ $key == '' ]]; then
            break
        fi
        _gbr_draw
    done

    _gbr_cleanup
    echo
    git checkout "${branches[$selected]}"
}
