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


alias ga="git add"


alias gaa="git add --all"


alias gu="git add -u"


alias gs="git status"


alias gpom="git push origin main"


alias gp="git push"


alias gc="git clone"


alias gb="git branch"


alias gav="git branch -av"


alias gbc="git checkout -b"


alias grpo="git remote prune origin"

alias grv="git remote -v"

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
    git rev-parse --is-inside-work-tree &>/dev/null || { echo "gbr: not a git repository" >&2; return 1; }

    local -a branches
    mapfile -t branches < <(git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null)
    local n=${#branches[@]}
    (( n == 0 )) && { echo "gbr: no branches yet (no commits)" >&2; return 1; }

    local current=$(git branch --show-current)
    local cur=0 top=0
    for i in "${!branches[@]}"; do [[ "${branches[$i]}" == "$current" ]] && cur=$i; done

    local R=$'\e[0m' B=$'\e[1m' D=$'\e[2m' REV=$'\e[7m'
    local RED=$'\e[31m' GRN=$'\e[32m' YEL=$'\e[33m' BLU=$'\e[34m' CYN=$'\e[36m'
    local BG=$'\e[48;5;237m'

    local old; old=$(stty -g); stty -echo -isig
    tput smcup; tput civis

    while true; do
        local cols rows vis end
        cols=$(tput cols); rows=$(tput lines)
        vis=$(( rows - 6 )); (( vis < 3 )) && vis=3
        (( cur < top )) && top=$cur
        (( cur >= top + vis )) && top=$(( cur - vis + 1 ))

        printf '\e[H\e[J'
        printf -v rule '%*s' $(( cols - 2 )) ''; rule=${rule// /─}
        pill=$'\e[30;46m BRANCHES \e[0m'
        printf ' %s%sgbr%s  %s⎇%s %s%s%s   %s   %s%d/%d%s\n' \
            "$B" "$CYN" "$R" "$D" "$R" "$B" "$current" "$R" "$pill" "$D" "$((cur+1))" "$n" "$R"
        printf ' %s%s%s\n' "$D" "$rule" "$R"

        end=$(( top + vis )); (( end > n )) && end=$n
        for (( i = top; i < end; i++ )); do
            local bg ptr box base
            bg=""; ptr=" "
            if [ $i -eq $cur ]; then bg=$BG; ptr="${CYN}▌"; fi
            box="${D}○"; [[ "${branches[$i]}" == "$current" ]] && box="${GRN}●"
            base=${branches[$i]}
            line="${bg} ${ptr}${R}${bg} ${box}${R}${bg}  ${B}${base}${R}${bg}"
            printf '%s\e[K%s\n' "$line" "$R"
        done
        for (( i = end - top; i < vis; i++ )); do echo; done

        printf ' %s↑↓%s move  %senter%s checkout  %sq%s quit%s\n' "$B" "$R" "$B" "$R" "$B" "$R"

        IFS= read -rsn1 k
        if [[ $k == $'\e' ]]; then
            read -rsn2 -t 0.05 k || true
            case $k in
                "[A") (( cur > 0 )) && (( cur-- )) ;;
                "[B") (( cur < n - 1 )) && (( cur++ )) ;;
            esac
        elif [[ $k == "" ]]; then
            break
        elif [[ $k == q || $k == $'\x03' ]]; then
            cur=-1; break
        fi
    done

    tput cnorm; tput rmcup; stty "$old"
    (( cur < 0 )) && return 0
    git checkout "${branches[$cur]}"
}

gsc() {
    git rev-parse --is-inside-work-tree &>/dev/null || { echo "not a git repo"; return 1; }

    local R=$'\e[0m' B=$'\e[1m' D=$'\e[2m' REV=$'\e[7m'
    local RED=$'\e[31m' GRN=$'\e[32m' YEL=$'\e[33m' BLU=$'\e[34m' CYN=$'\e[36m'
    local BG=$'\e[48;5;237m'

    local -a paths=() st=() sl=() sc=() checked=() staged=()
    local e x y l p _
    while IFS= read -r -d '' e; do
        x=${e:0:1}; y=${e:1:1}; p=${e:3}
        [[ $x == [RC] ]] && IFS= read -r -d '' _
        paths+=("$p"); st+=("${e:0:2}")
        l=$x; [[ $l == " " ]] && l=$y
        sl+=("$l")
        case $l in
            M) sc+=("$YEL") ;; A) sc+=("$GRN") ;; D) sc+=("$RED") ;;
            R|C) sc+=("$CYN") ;; *) sc+=("$BLU") ;;
        esac
        if [[ $x != " " && $x != "?" ]]; then staged+=(1); checked+=(1)
        else staged+=(0); checked+=(0); fi
    done < <(git -c core.quotePath=false status --porcelain -z)

    local n=${#paths[@]}
    (( n == 0 )) && { echo "nothing to commit"; return 0; }

    local cur=0 top=0 mode=nav msg="" pos=0 note="" go=0
    local k rest i c cols rows vis end ch box bg ptr dir base maxw rule fill txt pill v old branch line
    branch=$(git branch --show-current)
    old=$(stty -g); stty -echo -isig
    tput smcup; tput civis

    while true; do
        cols=$(tput cols); rows=$(tput lines)
        vis=$(( rows - 9 )); (( vis < 3 )) && vis=3
        (( cur < top )) && top=$cur
        (( cur >= top + vis )) && top=$(( cur - vis + 1 ))
        c=0; for i in "${checked[@]}"; do (( c += i )); done
        end=$(( top + vis )); (( end > n )) && end=$n
        printf -v rule '%*s' $(( cols - 2 )) ''; rule=${rule// /─}

        printf '\e[H\e[J'
        if [[ $mode == nav ]]; then pill=$'\e[30;46m FILES \e[0m'; else pill=$'\e[30;45m MESSAGE \e[0m'; fi
        printf ' %s%sgsc%s  %s⎇%s %s%s%s   %s   %s%d/%d selected%s\n' \
            "$B" "$CYN" "$R" "$D" "$R" "$B" "$branch" "$R" "$pill" "$D" "$c" "$n" "$R"
        printf ' %s%s%s\n' "$D" "$rule" "$R"

        maxw=$(( cols - 12 ))
        for (( i = top; i < end; i++ )); do
            bg=""; ptr=" "
            if [[ $mode == nav && $i -eq $cur ]]; then bg=$BG; ptr="${CYN}▌"; fi
            if (( checked[i] )); then box="${GRN}●"; else box="${D}○"; fi
            p=${paths[i]}; dir=""; base=$p
            if [[ $p == */* ]]; then dir=${p%/*}/; base=${p##*/}; fi
            if (( ${#dir} + ${#base} > maxw )); then
                v=$(( maxw - ${#base} - 1 )); (( v < 0 )) && v=0
                dir="…${dir: -v}"
            fi
            line="${bg} ${ptr}${R}${bg} ${box}${R}${bg}  ${sc[i]}${B}${sl[i]}${R}${bg}  ${D}${dir}${R}${bg}${base}"
            printf '%s\e[K%s\n' "$line" "$R"
        done
        for (( i = end - top; i < vis; i++ )); do echo; done

        txt=""
        (( top > 0 )) && txt+="↑ $top more  "
        (( end < n )) && txt+="↓ $(( n - end )) more"
        if [[ -n $txt ]]; then
            v=$(( cols - 6 - ${#txt} )); (( v < 0 )) && v=0
            printf -v fill '%*s' "$v" ''; fill=${fill// /─}
            printf ' %s── %s %s%s\n' "$D" "$txt" "$fill" "$R"
        else
            printf ' %s%s%s\n' "$D" "$rule" "$R"
        fi

        if [[ $mode == edit ]]; then
            ch=${msg:pos:1}
            printf ' %s%s✎ Message%s\n' "$B" "$CYN" "$R"
            printf '   %s%s%s%s%s\n' "${msg:0:pos}" "$REV" "${ch:- }" "$R" "${msg:pos+1}"
        else
            printf ' %s✎ Message%s\n' "$D" "$R"
            if [[ -n $msg ]]; then printf '   %s\n' "$msg"
            else printf '   %s(press tab to write)%s\n' "$D" "$R"; fi
        fi
        if [[ -n $note ]]; then printf ' %s⚠ %s%s\n' "$YEL" "$note" "$R"; else echo; fi

        if [[ $mode == nav ]]; then
            printf ' %s↑↓%s%s move%s  %sspace%s%s toggle%s  %sa%s%s all%s  %sd%s%s diff%s  %stab%s%s message%s  %senter%s%s push%s  %sq%s%s quit%s' \
                "$B" "$R" "$D" "$R" "$B" "$R" "$D" "$R" "$B" "$R" "$D" "$R" "$B" "$R" "$D" "$R" \
                "$B" "$R" "$D" "$R" "$B" "$R" "$D" "$R" "$B" "$R" "$D" "$R"
        else
            printf ' %s←→%s%s cursor%s  %stab%s%s files%s  %senter%s%s push%s  %sesc%s%s files%s' \
                "$B" "$R" "$D" "$R" "$B" "$R" "$D" "$R" "$B" "$R" "$D" "$R" "$B" "$R" "$D" "$R"
        fi

        IFS= read -rsn1 k
        note=""
        if [[ $k == $'\e' ]]; then
            rest=""; IFS= read -rsn2 -t 0.05 rest
            case $rest in
                "[3")        IFS= read -rsn1 -t 0.05 _; k=DEL ;;
                "[1"|"[7")   IFS= read -rsn1 -t 0.05 _; k=HOME ;;
                "[4"|"[8")   IFS= read -rsn1 -t 0.05 _; k=END ;;
                "[A") k=UP ;; "[B") k=DOWN ;; "[C") k=RIGHT ;; "[D") k=LEFT ;;
                "[H") k=HOME ;; "[F") k=END ;;
                "") k=ESC ;;
                *) k=IGN ;;
            esac
        fi

        case $k in
            $'\x03') break ;;
            $'\t')
                if [[ $mode == nav ]]; then mode=edit; pos=${#msg}; else mode=nav; fi
                continue ;;
            "")
                if (( c == 0 )); then note="no file checked"; continue; fi
                if [[ -z $msg ]]; then note="empty commit message"; mode=edit; pos=${#msg}; continue; fi
                tput cup $(( rows - 1 )) 0; tput el
                printf ' \e[30;43m PUSH \e[0m Commit %d file(s) and push? %s(y/n)%s ' "$c" "$B" "$R"
                IFS= read -rsn1 k
                [[ $k == [yYoO] ]] && { go=1; break; }
                continue ;;
        esac

        if [[ $mode == nav ]]; then
            case $k in
                UP|k)   (( cur > 0 )) && (( cur-- )) ;;
                DOWN|j) (( cur < n - 1 )) && (( cur++ )) ;;
                " ")    checked[cur]=$(( 1 - checked[cur] )) ;;
                a)      v=1; (( c == n )) && v=0
                        for (( i = 0; i < n; i++ )); do checked[i]=$v; done ;;
                d)      if [[ ${st[cur]} == "??" ]]; then less -R -- "${paths[cur]}"
                        else git diff HEAD --color=always -- "${paths[cur]}" | less -R; fi
                        tput civis ;;
                q|ESC)  break ;;
            esac
        else
            case $k in
                ESC)   mode=nav ;;
                LEFT)  (( pos > 0 )) && (( pos-- )) ;;
                RIGHT) (( pos < ${#msg} )) && (( pos++ )) ;;
                HOME)  pos=0 ;;
                END)   pos=${#msg} ;;
                DEL)   msg=${msg:0:pos}${msg:pos+1} ;;
                $'\x7f'|$'\b') (( pos > 0 )) && { msg=${msg:0:pos-1}${msg:pos}; (( pos-- )); } ;;
                UP|DOWN|IGN) ;;
                *) if (( ${#k} == 1 )) && [[ $k != [[:cntrl:]] ]]; then
                       msg=${msg:0:pos}$k${msg:pos}; (( pos++ ))
                   fi ;;
            esac
        fi
    done

    tput cnorm; tput rmcup; stty "$old"
    (( go )) || return 0

    for (( i = 0; i < n; i++ )); do
        if (( checked[i] )); then git add -- "${paths[i]}"
        elif (( staged[i] )); then git reset -q -- "${paths[i]}"; fi
    done
    git commit -m "$msg" || return 1
    if git rev-parse --abbrev-ref '@{u}' &>/dev/null; then git push; else git push -u origin HEAD; fi
}
