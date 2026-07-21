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


alias ga="git add"


alias gaa="git add ."


alias gb="git branch"


alias gbc="git checkout -b"


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

ggui() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "ggui: not a git repository" >&2
        return 1
    fi

    local C_RESET="\033[0m"
    local C_TITLE="\033[1;36m"
    local C_HINT="\033[2;36m"
    local C_SELECTED="\033[1;30;46m"
    local C_STAGED="\033[0;32m"
    local C_UNSTAGED="\033[0;31m"
    local C_UNTRACKED="\033[0;33m"
    local C_CONFLICT="\033[1;35m"
    local C_RENAMED="\033[0;34m"
    local C_IGNORED="\033[2;37m"
    local C_INFO="\033[1;37m"

    local selected=0
    local viewport_start=0
    local show_hidden=0
    local status_message=""

    local -a rows_xy=()
    local -a rows_path=()
    local -a rows_color=()
    local -a rows_note=()

    _ggui_cleanup() {
        tput cnorm
        tput rmcup
        stty echo 2>/dev/null
        trap - EXIT INT TERM
    }

    _ggui_note_for_xy() {
        local xy="$1"
        local x="${xy:0:1}"
        local y="${xy:1:1}"

        if [[ "$xy" == "??" ]]; then
            echo "Untracked file"
            return
        fi
        if [[ "$xy" == "!!" ]]; then
            echo "Ignored file"
            return
        fi
        if [[ "$x$y" =~ [U]{1}.{1}|.{1}[U]{1}|AA|DD ]]; then
            echo "Merge conflict"
            return
        fi

        local staged_note=""
        local worktree_note=""

        case "$x" in
            M) staged_note="staged: modified" ;;
            A) staged_note="staged: added" ;;
            D) staged_note="staged: deleted" ;;
            R) staged_note="staged: renamed" ;;
            C) staged_note="staged: copied" ;;
            esac

        case "$y" in
            M) worktree_note="unstaged: modified" ;;
            D) worktree_note="unstaged: deleted" ;;
            esac

        if [[ -n "$staged_note" && -n "$worktree_note" ]]; then
            echo "$staged_note, $worktree_note"
        elif [[ -n "$staged_note" ]]; then
            echo "$staged_note"
        elif [[ -n "$worktree_note" ]]; then
            echo "$worktree_note"
        else
            echo "tracked"
        fi
    }

    _ggui_color_for_xy() {
        local xy="$1"
        local x="${xy:0:1}"
        local y="${xy:1:1}"

        if [[ "$xy" == "??" ]]; then
            echo "$C_UNTRACKED"
            return
        fi
        if [[ "$xy" == "!!" ]]; then
            echo "$C_IGNORED"
            return
        fi
        if [[ "$x$y" =~ [U]{1}.{1}|.{1}[U]{1}|AA|DD ]]; then
            echo "$C_CONFLICT"
            return
        fi
        if [[ "$x" == "R" ]]; then
            echo "$C_RENAMED"
            return
        fi
        if [[ "$x" != " " ]]; then
            echo "$C_STAGED"
            return
        fi
        if [[ "$y" != " " ]]; then
            echo "$C_UNSTAGED"
            return
        fi
        echo "$C_INFO"
    }

    _ggui_load_rows() {
        rows_xy=()
        rows_path=()
        rows_color=()
        rows_note=()

        local -a raw=()
        if [[ "$show_hidden" -eq 1 ]]; then
            mapfile -t raw < <(git status --porcelain=v1 --untracked-files=all --ignored=matching)
        else
            mapfile -t raw < <(git status --porcelain=v1 --untracked-files=all)
        fi

        local line xy raw_path path color note
        for line in "${raw[@]}"; do
            xy="${line:0:2}"
            raw_path="${line:3}"
            path="$raw_path"
            if [[ "$raw_path" == *" -> "* ]]; then
                path="${raw_path##* -> }"
            fi

            color="$(_ggui_color_for_xy "$xy")"
            note="$(_ggui_note_for_xy "$xy")"

            rows_xy+=("$xy")
            rows_path+=("$path")
            rows_color+=("$color")
            rows_note+=("$note")
        done

        local count="${#rows_path[@]}"
        if [[ "$count" -eq 0 ]]; then
            selected=0
            viewport_start=0
            return
        fi
        [[ "$selected" -ge "$count" ]] && selected=$((count - 1))
        [[ "$selected" -lt 0 ]] && selected=0
    }

    _ggui_draw() {
        local term_cols term_lines
        term_cols="$(tput cols)"
        term_lines="$(tput lines)"
        local viewport_size=$((term_lines - 7))
        [[ "$viewport_size" -lt 1 ]] && viewport_size=1

        local count="${#rows_path[@]}"
        if [[ "$count" -gt 0 ]]; then
            if [[ "$selected" -lt "$viewport_start" ]]; then
                viewport_start="$selected"
            elif [[ "$selected" -ge $((viewport_start + viewport_size)) ]]; then
                viewport_start=$((selected - viewport_size + 1))
            fi
        fi

        tput cup 0 0
        local EL
        EL="$(tput el)"

        printf "${C_TITLE}  Git GUI${C_RESET}${EL}\n"
        printf "${C_HINT}  [↑/↓] Move  [space] Stage/Unstage  [t] Track/Untrack  [h] Ignored  [Enter] Diff  [q] Quit${C_RESET}${EL}\n"
        printf "${C_HINT}  Hidden(ignored): %s${C_RESET}${EL}\n\n" "$([[ "$show_hidden" -eq 1 ]] && echo ON || echo OFF)"

        if [[ "$count" -eq 0 ]]; then
            printf "  ${C_INFO}No file changes found.${C_RESET}${EL}\n"
            printf "  ${C_HINT}%s${C_RESET}${EL}\n" "$status_message"
            tput ed
            return
        fi

        local max_name_width=$((term_cols - 16))
        [[ "$max_name_width" -lt 10 ]] && max_name_width=10

        local end=$((viewport_start + viewport_size))
        [[ "$end" -gt "$count" ]] && end="$count"

        local i row_prefix path short_path color xy
        for ((i = viewport_start; i < end; i++)); do
            xy="${rows_xy[$i]}"
            path="${rows_path[$i]}"
            color="${rows_color[$i]}"

            short_path="$path"
            if [[ ${#short_path} -gt "$max_name_width" ]]; then
                short_path="${short_path:0:$((max_name_width - 1))}~"
            fi

            if [[ "$i" -eq "$selected" ]]; then
                row_prefix=">"
                printf "  ${C_SELECTED}%s [%s] %-*s${C_RESET}${EL}\n" "$row_prefix" "$xy" "$max_name_width" "$short_path"
            else
                row_prefix=" "
                printf "  %s ${color}[%s] %-*s${C_RESET}${EL}\n" "$row_prefix" "$xy" "$max_name_width" "$short_path"
            fi
        done

        local selected_note="${rows_note[$selected]}"
        local selected_path="${rows_path[$selected]}"
        printf "${EL}\n"
        printf "  ${C_INFO}File:${C_RESET} %s${EL}\n" "$selected_path"
        printf "  ${C_INFO}Status:${C_RESET} %s${EL}\n" "$selected_note"
        printf "  ${C_HINT}%s${C_RESET}${EL}\n" "$status_message"
        printf "  ${C_HINT}[ %d / %d ]${C_RESET}${EL}\n" "$((selected + 1))" "$count"
        tput ed
    }

    _ggui_show_diff() {
        local idx="$1"
        local path="${rows_path[$idx]}"
        local xy="${rows_xy[$idx]}"

        tput rmcup
        tput cnorm
        stty echo 2>/dev/null

        echo "=== ggui diff: $path ==="
        git --no-pager status --short -- "$path"
        echo

        if [[ "$xy" == "??" || "$xy" == "!!" ]]; then
            echo "No diff available for this status."
        else
            git --no-pager diff -- "$path"
        fi

        echo
        printf "[Press Enter to go back] "
        read -r

        tput smcup
        tput civis
    }

    _ggui_toggle_stage() {
        local idx="$1"
        local path="${rows_path[$idx]}"
        local xy="${rows_xy[$idx]}"
        local x="${xy:0:1}"

        if [[ "$xy" == "!!" ]]; then
            status_message="Ignored file: cannot stage unless you force-add manually"
            return
        fi

        if [[ "$x" != " " && "$xy" != "??" ]]; then
            if git restore --staged -- "$path" 2>/dev/null; then
                status_message="Unstaged: $path"
            elif git reset HEAD -- "$path" &>/dev/null; then
                status_message="Unstaged: $path"
            else
                status_message="Failed to unstage: $path"
            fi
        else
            if git add -- "$path" &>/dev/null; then
                status_message="Staged: $path"
            else
                status_message="Failed to stage: $path"
            fi
        fi
    }

    _ggui_toggle_track() {
        local idx="$1"
        local path="${rows_path[$idx]}"
        local xy="${rows_xy[$idx]}"
        local answer

        if [[ "$xy" == "??" || "$xy" == "!!" ]]; then
            if git add -- "$path" &>/dev/null; then
                status_message="Now tracked: $path"
            else
                status_message="Failed to track: $path"
            fi
            return
        fi

        printf "\nRemove from index (keep file) '%s'? [y/N] " "$path"
        read -r answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            if git rm --cached -- "$path" &>/dev/null; then
                status_message="Untracked (removed from index): $path"
            else
                status_message="Failed to untrack: $path"
            fi
        else
            status_message="Canceled"
        fi
    }

    trap '_ggui_cleanup' EXIT INT TERM
    tput smcup
    tput civis
    stty -echo 2>/dev/null

    _ggui_load_rows
    _ggui_draw

    local key esc_seq
    while true; do
        IFS= read -r -s -n1 key
        local count="${#rows_path[@]}"

        if [[ "$key" == $'\x1b' ]]; then
            IFS= read -r -s -n1 -t 0.1 esc_seq
            if [[ "$esc_seq" == '[' ]]; then
                IFS= read -r -s -n1 -t 0.1 esc_seq
                case "$esc_seq" in
                    A) [[ "$selected" -gt 0 ]] && ((selected--)) ;;
                    B) [[ "$count" -gt 0 && "$selected" -lt $((count - 1)) ]] && ((selected++)) ;;
                esac
                _ggui_draw
                continue
            fi
        fi

        case "$key" in
            q|Q)
                _ggui_cleanup
                return 0
                ;;
            h|H)
                show_hidden=$((1 - show_hidden))
                selected=0
                viewport_start=0
                status_message=""
                _ggui_load_rows
                _ggui_draw
                ;;
            ' ')
                if [[ "$count" -gt 0 ]]; then
                    _ggui_toggle_stage "$selected"
                    _ggui_load_rows
                fi
                _ggui_draw
                ;;
            t|T)
                if [[ "$count" -gt 0 ]]; then
                    tput rmcup
                    tput cnorm
                    stty echo 2>/dev/null
                    _ggui_toggle_track "$selected"
                    tput smcup
                    tput civis
                    stty -echo 2>/dev/null
                    _ggui_load_rows
                fi
                _ggui_draw
                ;;
            '')
                if [[ "$count" -gt 0 ]]; then
                    _ggui_show_diff "$selected"
                    _ggui_load_rows
                    _ggui_draw
                fi
                ;;
            *)
                ;;
        esac
    done
}
