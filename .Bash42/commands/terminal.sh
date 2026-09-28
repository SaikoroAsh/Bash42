### Terminal ###

alias vsc="code ."

cln() {
    local rm_venv=0
    if [ "$1" = "-v" ] || [ "$1" = "venv" ]; then
        rm_venv=1
    fi

    local names='-name "a.out" -o -type d \( -name "__pycache__" -o -name ".mypy_cache" \)'
    if [ "$rm_venv" -eq 1 ]; then
        f=$(find . \( -name "a.out" -o -type d \( -name "__pycache__" -o -name ".mypy_cache" -o -name ".venv" \) \) 2>/dev/null)
    else
        f=$(find . \( -name "a.out" -o -type d \( -name "__pycache__" -o -name ".mypy_cache" \) \) 2>/dev/null)
    fi

    if [ -z "$f" ]; then
        echo "Nothing to clean"
    else
        echo "Deleted:"
        echo "$f"
        find . -name "a.out" -type f -delete
        if [ "$rm_venv" -eq 1 ]; then
            find . -type d \( -name "__pycache__" -o -name ".mypy_cache" -o -name ".venv" \) -exec rm -rf {} +
        else
            find . -type d \( -name "__pycache__" -o -name ".mypy_cache" \) -exec rm -rf {} +
        fi
    fi
}
fm() {
    local target="${1:-$PWD}"
    case "$(uname -s)" in
        Linux*)
            if command -v nautilus &>/dev/null; then
                nautilus --new-window "$target" > /dev/null 2>&1 & disown
            elif command -v dolphin &>/dev/null; then
                dolphin --new-window "$target" > /dev/null 2>&1 & disown
            elif command -v thunar &>/dev/null; then
                thunar --new-window "$target" > /dev/null 2>&1 & disown
            elif command -v xdg-open &>/dev/null; then
                xdg-open "$target" > /dev/null 2>&1 & disown
            else
                echo "No known file manager found."
            fi
            ;;
        Darwin*)
            open -n "$target"
            ;;
        *)
            echo "Unsupported OS: $(uname -s)"
            ;;
    esac
}

nav() {
	# ── Charte graphique : cyan/blanc-gras (style welcome42) ─────
	local C_RESET="\033[0m"
	local C_DIR="\033[1;37m"
	local C_FILE="\033[0;36m"
	local C_SEL="\033[1;30;46m"
	local C_PATH="\033[1;37m"
	local C_HINT="\033[2;36m"
	local C_EMPTY="\033[2;31m"
	local C_SCROLL="\033[0;36m"
	local C_SEP="\033[0;36m"
	local C_PRE_DIR="\033[2;37m"
	local C_PRE_FILE="\033[2;36m"
	local C_PRE_TITLE="\033[1;36m"
	local C_PRE_EMPTY="\033[2;31m"
	local C_PRE_SEP="\033[2;36m"

	local current_dir
	current_dir="$(pwd)"
	local selected=0
	local show_hidden=0
	local help_visible=0
	local status_msg=""
	local -A marked=()
	local -a marked_order=()
	local -a clipboard_paths=()
	local -a entries=()

	_nav_cleanup() {
		tput cnorm
		tput rmcup
		stty sane 2>/dev/null
		stty echo 2>/dev/null
	}
	trap '_nav_cleanup' EXIT INT TERM
	trap '' INT

	_nav_read_key() {
		local __out_name="$1"
		local ch seq
		IFS= read -r -s -n1 ch
		if [[ -z "$ch" ]]; then
			printf -v "$__out_name" '%s' ""
			return
		fi
		if [[ "$ch" == $'\e' ]]; then
			seq="$ch"
			while IFS= read -r -s -n1 ch; do
				seq+="$ch"
				case "$ch" in
					[A-Za-z~]|$'\n'|$'\r')
						break
						;;
				esac
			done
			printf -v "$__out_name" '%s' "$seq"
			return
		fi
		printf -v "$__out_name" '%s' "$ch"
	}

	_nav_open() {
		local file="$1"
		local ext="${file##*.}"
		case "$ext" in
			sh|bash|zsh|py|js|ts|json|yaml|yml|toml|conf|cfg|ini|			txt|md|rst|csv|log|env|gitignore|dockerfile)
				vim "$file"
				;;
			*)
				xdg-open "$file" &>/dev/null &
				;;
		esac
	}

	_nav_is_shift_enter() {
		local seq="$1"
		[[ "$seq" == *";2"* && "$seq" == *"13"* ]] && return 0
		[[ "$seq" == *"13;2"* ]] && return 0
		[[ "$seq" == *"27;2"* && "$seq" == *"13"* ]] && return 0
		return 1
	}

	tput smcup
	tput civis
	stty -echo -icanon -isig -ixon -ixoff min 1 time 0 2>/dev/null || {
		tput rmcup
		tput cnorm
		stty sane 2>/dev/null
		return 1
	}

	_nav_list() {
		local dir="$1"
		local f
		while IFS= read -r f; do
			[[ "$show_hidden" -eq 0 && "${f##*/}" == .* ]] && continue
			printf '%s\n' "$f"
		done < <(
			{
				find "$dir" -maxdepth 1 -mindepth 1 -type d | sort
				find "$dir" -maxdepth 1 -mindepth 1 ! -type d | sort
			}
		)
	}

	_nav_preview_lines() {
		local dir="$1"
		local col_w="$2"
		local max_lines="$3"
		local -a plines=()
		local -a items=()
		local f
		while IFS= read -r f; do
			[[ "$show_hidden" -eq 0 && "${f##*/}" == .* ]] && continue
			items+=("$f")
		done < <(
			{
				find "$dir" -maxdepth 1 -mindepth 1 -type d | sort
				find "$dir" -maxdepth 1 -mindepth 1 ! -type d | sort
			}
		)

		local item_count="${#items[@]}"
		local title_raw=" ${dir##*/}/"
		local max_title=$(( col_w - 2 ))
		[[ ${#title_raw} -gt $max_title ]] && title_raw="${title_raw:0:$max_title}…"
		plines+=("${C_PRE_TITLE}${title_raw}${C_RESET}")

		local sep
		sep=$(printf '%*s' "$col_w" '' | tr ' ' '-')
		plines+=("${C_PRE_SEP}${sep}${C_RESET}")

		if [[ "$item_count" -eq 0 ]]; then
			plines+=("${C_PRE_EMPTY} (vide)${C_RESET}")
		else
			local shown=$(( max_lines - 3 ))
			[[ "$shown" -lt 1 ]] && shown=1
			local display=$(( item_count < shown ? item_count : shown ))
			local j
			for (( j=0; j<display; j++ )); do
				local iname="${items[$j]}"
				local ibase="${iname##*/}"
				local ilabel="${ibase}"
				local icolor
				if [[ -d "$iname" ]]; then
					ilabel=" ${ibase}/"
					icolor="$C_PRE_DIR"
				else
					ilabel=" ${ibase}"
					icolor="$C_PRE_FILE"
				fi
				local max_l=$(( col_w - 1 ))
				[[ ${#ilabel} -gt $max_l ]] && ilabel="${ilabel:0:$max_l}…"
				plines+=("${icolor}${ilabel}${C_RESET}")
			done
			if [[ "$item_count" -gt "$display" ]]; then
				local remaining=$(( item_count - display ))
				plines+=("${C_PRE_SEP} … +${remaining} élément(s)${C_RESET}")
			fi
		fi

		local pl
		for pl in "${plines[@]}"; do
			printf '%s\0' "$pl"
		done
	}

	_nav_draw() {
		local dir="$1"
		local sel="$2"
		local count="$3"
		local viewport_start="$4"
		local viewport_size="$5"
		shift 5
		local -a entries=("$@")

		tput cup 0 0
		local EL
		EL="$(tput el)"

		local term_cols term_lines
		term_cols="$(tput cols)"
		term_lines="$(tput lines)"

		local left_w=$(( term_cols / 2 - 3 ))
		[[ "$left_w" -lt 10 ]] && left_w=10
		local right_w=$(( term_cols - left_w - 4 ))
		[[ "$right_w" -lt 5 ]] && right_w=5

		local border_w=$(( term_cols - 4 ))
		local content_w=$(( term_cols - 8 ))
		[[ "$content_w" -lt 1 ]] && content_w=1
		local border_line
		border_line=$(printf '%*s' "$border_w" '' | tr ' ' '-')
		printf "${C_SEP}  +%s+${C_RESET}${EL}\n" "$border_line"

		local dir_display="$dir"
		if [[ ${#dir_display} -gt $content_w ]]; then
			dir_display="~${dir_display:$(( ${#dir_display} - content_w + 1 ))}"
		fi
		local dir_pad=$(( content_w - ${#dir_display} ))
		local dir_spaces
		dir_spaces=$(printf '%*s' "$dir_pad" '')
		printf "${C_SEP}  |${C_RESET}  ${C_PATH}%s${dir_spaces}${C_RESET}  ${C_SEP}|${C_RESET}${EL}\n" 			"$dir_display"

		local hint="[↵] Enter  [⇧↵] Parent  [R] Del  [^C/^V] Copy/Paste  [?] Help  [q] Quit"
		if [[ -n "$status_msg" ]]; then
			hint="$status_msg"
		fi
		if [[ ${#hint} -gt $content_w ]]; then
			hint="${hint:0:$(( content_w - 1 ))}~"
		fi
		local hint_pad=$(( content_w - ${#hint} ))
		local hint_spaces
		hint_spaces=$(printf '%*s' "$hint_pad" '')
		printf "${C_SEP}  |${C_RESET}  ${C_HINT}%s${hint_spaces}${C_RESET}  ${C_SEP}|${C_RESET}${EL}\n" 			"$hint"
		printf "${C_SEP}  +%s+${C_RESET}${EL}\n" "$border_line"
		printf "${EL}\n"

		if [[ "$count" -eq 0 ]]; then
			printf "  ${C_EMPTY}(répertoire vide)${C_RESET}${EL}\n"
			tput ed
			return
		fi

		local preview_active=0
		local preview_dir=""
		if [[ "$help_visible" -eq 1 ]]; then
			preview_active=1
			preview_dir="$current_dir"
		elif [[ "$count" -gt 0 && -d "${entries[$sel]}" ]]; then
			preview_active=1
			preview_dir="${entries[$sel]}"
		fi

		local -a left_rendered=()
		local i name base label
		local end=$(( viewport_start + viewport_size ))
		[[ "$end" -gt "$count" ]] && end="$count"

		for (( i=viewport_start; i<end; i++ )); do
			name="${entries[$i]}"
			base="${name##*/}"
			label="$base"
			if [[ -d "$name" ]]; then
				label="${base}/"
			fi
			if [[ -n "${marked[$i]+x}" ]]; then
				label="* ${label}"
			fi
			if [[ ${#label} -gt $left_w ]]; then
				label="${label:0:$(( left_w - 1 ))}…"
			fi
			local pad=$(( left_w - ${#label} ))
			local spaces=""
			local s
			for (( s=0; s<pad; s++ )); do spaces+=" "; done
			if [[ "$i" -eq "$sel" ]]; then
				left_rendered+=("${C_SEL}${label}${C_RESET}${spaces}")
			elif [[ -d "$name" ]]; then
				left_rendered+=("${C_DIR}${label}${C_RESET}${spaces}")
			else
				left_rendered+=("${C_FILE}${label}${C_RESET}${spaces}")
			fi
		done

		local -a right_lines=()
		if [[ "$help_visible" -eq 1 ]]; then
			right_lines+=("${C_PRE_TITLE} Nav keys${C_RESET}")
			right_lines+=("${C_PRE_SEP}--------------------------------${C_RESET}")
			right_lines+=(" ${C_PRE_DIR}[Enter]${C_RESET} open/enter")
			right_lines+=(" ${C_PRE_DIR}[⇧↵]${C_RESET} cd current dir")
			right_lines+=(" ${C_PRE_DIR}[R]${C_RESET} delete selected")
			right_lines+=(" ${C_PRE_DIR}[^C]${C_RESET} copy selected")
			right_lines+=(" ${C_PRE_DIR}[^V]${C_RESET} paste here")
			right_lines+=(" ${C_PRE_DIR}[Space/S]${C_RESET} select item")
			right_lines+=(" ${C_PRE_DIR}[h]${C_RESET} show hidden")
			right_lines+=(" ${C_PRE_DIR}[?]${C_RESET} toggle help")
			right_lines+=(" ${C_PRE_DIR}[q]${C_RESET} quit")
		elif [[ "$preview_active" -eq 1 ]]; then
			local raw_preview
			while IFS= read -r -d $'\0' raw_preview; do
				right_lines+=("$raw_preview")
			done < <(_nav_preview_lines "$preview_dir" "$right_w" "$viewport_size")
		fi

		local n_left="${#left_rendered[@]}"
		local n_right="${#right_lines[@]}"
		local n_rows=$(( n_left > n_right ? n_left : n_right ))
		[[ "$n_rows" -gt "$viewport_size" ]] && n_rows="$viewport_size"

		local r
		for (( r=0; r<n_rows; r++ )); do
			if [[ "$r" -lt "$n_left" ]]; then
				printf "  %b " "${left_rendered[$r]}"
			else
				printf "%$(( left_w + 3 ))s" ""
			fi
			if [[ "$preview_active" -eq 1 || "$help_visible" -eq 1 ]]; then
				printf "${C_PRE_SEP}|${C_RESET}"
				if [[ "$r" -lt "$n_right" ]]; then
					printf "%b" "${right_lines[$r]}"
				fi
			fi
			printf "${EL}\n"
		done

		if [[ "$count" -gt "$viewport_size" ]]; then
			printf "  ${C_SCROLL}[ %d / %d ]${C_RESET}${EL}\n" "$(( sel + 1 ))" "$count"
		else
			printf "${EL}\n"
		fi
		tput ed
	}

	local key seq ch
	local viewport_start=0
	local cache_dir=""
	local cache_selected=-1
	local cache_viewport=-1
	local cache_cols=-1
	local cache_lines=-1
	local need_relist=1

	while true; do
		if [[ "$need_relist" -eq 1 || "$current_dir" != "$cache_dir" ]]; then
			mapfile -t entries < <(_nav_list "$current_dir")
			need_relist=0
		fi
		local count="${#entries[@]}"
		[[ "$count" -eq 0 ]] && selected=0
		[[ "$selected" -ge "$count" && "$count" -gt 0 ]] && selected=$(( count - 1 ))

		local term_lines term_cols_now
		term_lines="$(tput lines)"
		term_cols_now="$(tput cols)"
		local viewport_size=$(( term_lines - 7 ))
		[[ "$viewport_size" -lt 1 ]] && viewport_size=1

		if [[ "$selected" -lt "$viewport_start" ]]; then
			viewport_start="$selected"
		elif [[ "$selected" -ge $(( viewport_start + viewport_size )) ]]; then
			viewport_start=$(( selected - viewport_size + 1 ))
		fi

		if [[ "$current_dir" != "$cache_dir" || "$selected" -ne "$cache_selected" || "$viewport_start" -ne "$cache_viewport" || "$term_cols_now" -ne "$cache_cols" || "$term_lines" -ne "$cache_lines" ]]; then
			_nav_draw "$current_dir" "$selected" "$count" "$viewport_start" "$viewport_size" "${entries[@]}"
			cache_dir="$current_dir"
			cache_selected="$selected"
			cache_viewport="$viewport_start"
			cache_cols="$term_cols_now"
			cache_lines="$term_lines"
		fi

		_nav_read_key key
		if [[ "$key" == $'\003' ]]; then
			if [[ "$count" -eq 0 ]]; then
				status_msg="Nothing to copy"
				continue
			fi
			clipboard_paths=()
			if [[ ${#marked_order[@]} -gt 0 ]]; then
				for idx in "${marked_order[@]}"; do
					clipboard_paths+=("${entries[$idx]}")
				done
			else
				clipboard_paths+=("${entries[$selected]}")
			fi
			status_msg="Copied ${#clipboard_paths[@]} item(s)"
			continue
		fi
		if [[ "$key" == $'\x16' ]]; then
			if [[ ${#clipboard_paths[@]} -eq 0 ]]; then
				status_msg="Clipboard empty"
				continue
			fi
			local paste_ok=1
			local source dest_name dest_path suffix
			for source in "${clipboard_paths[@]}"; do
				dest_name="${source##*/}"
				dest_path="$current_dir/$dest_name"
				suffix=1
				while [[ -e "$dest_path" || -L "$dest_path" ]]; do
					dest_path="$current_dir/${dest_name}-copy-$suffix"
					(( suffix++ ))
				done
				cp -a -- "$source" "$dest_path" 2>/dev/null || { paste_ok=0; status_msg="Copy failed: ${source##*/}"; break; }
			done
			if [[ "$paste_ok" -eq 1 ]]; then
				status_msg="Pasted ${#clipboard_paths[@]} item(s) to $current_dir"
				need_relist=1
				selected=0
				viewport_start=0
				marked=()
				marked_order=()
			fi
			continue
		fi
		if [[ "$key" == $'\e' ]]; then
			_nav_cleanup
			trap - EXIT INT TERM
			return 0
		fi
		if [[ "$key" == $'\e['* || "$key" == $'\eO'* ]]; then
			if [[ "$key" == *"13"* && "$key" == *"2"* ]] || [[ "$key" == *"13;2"* ]] || [[ "$key" == *"27;2"* ]] || [[ "$key" == *"1;2A"* ]] || [[ "$key" == *"1;2B"* ]] || [[ "$key" == *"1;2C"* ]] || [[ "$key" == *"1;2D"* ]]; then
				_nav_cleanup
				trap - EXIT INT TERM
				cd "$current_dir" || return
				return 0
			fi
			case "$key" in
				$'\e[A'|$'\e[1;2A')
					[[ "$selected" -gt 0 ]] && (( selected-- ))
					continue
					;;
				$'\e[B'|$'\e[1;2B')
					[[ "$count" -gt 0 && "$selected" -lt $(( count - 1 )) ]] && (( selected++ ))
					continue
					;;
				$'\e[C'|$'\e[1;2C')
					if [[ "$count" -gt 0 && -d "${entries[$selected]}" ]]; then
						current_dir="${entries[$selected]}"
						selected=0
						viewport_start=0
						marked=()
						marked_order=()
						status_msg=""
					fi
					continue
					;;
				$'\e[D'|$'\e[1;2D')
					local parent
					parent="$(dirname "$current_dir")"
					if [[ "$parent" != "$current_dir" ]]; then
						local came_from="${current_dir##*/}"
						current_dir="$parent"
						selected=0
						viewport_start=0
						marked=()
						marked_order=()
						status_msg=""
						mapfile -t entries < <(_nav_list "$current_dir")
						need_relist=0
						local pi
						for (( pi=0; pi<${#entries[@]}; pi++ )); do
							if [[ "${entries[$pi]##*/}" == "$came_from" ]]; then
								selected="$pi"
								break
							fi
						done
						local pterm_lines
						pterm_lines="$(tput lines)"
						local pvp_size=$(( pterm_lines - 7 ))
						[[ "$pvp_size" -lt 1 ]] && pvp_size=1
						viewport_start=0
						if [[ "$selected" -ge "$pvp_size" ]]; then
							viewport_start=$(( selected - pvp_size + 1 ))
						fi
					fi
					continue
					;;
				*)
					;;
				esac
		fi

		case "$key" in
			q|Q)
				_nav_cleanup
				trap - EXIT INT TERM
				return 0
				;;
			h|H)
				show_hidden=$(( 1 - show_hidden ))
				selected=0
				viewport_start=0
				marked=()
				marked_order=()
				status_msg="Hidden files: $([[ "$show_hidden" -eq 1 ]] && printf 'on' || printf 'off')"
				need_relist=1
				continue
				;;
			c|C)
				if [[ "$count" -gt 0 ]]; then
					local open_path
					if [[ -d "${entries[$selected]}" ]]; then
						open_path="${entries[$selected]}"
					else
						open_path="$current_dir"
					fi
					_nav_cleanup
					trap - EXIT INT TERM
					code "$open_path" &>/dev/null &
				fi
				return 0
				;;
			x|X)
				if [[ "$count" -gt 0 && ! -d "${entries[$selected]}" ]]; then
					local target="${entries[$selected]}"
					local ext="${target##*.}"
					local cmd
					if [[ "$ext" == "py" ]]; then
						cmd="python3 "$target""
					else
						cmd=""$target""
					fi
					tput rmcup
					tput cnorm
					printf "Exécuter : %s " "$cmd"
					local extra_args
					IFS= read -r extra_args
					eval "$cmd $extra_args"
					printf "\n[Terminé — appuie sur Entrée]"
					read -r
					stty echo 2>/dev/null
					tput smcup
					tput civis
					need_relist=1
					cache_dir=""
					cache_selected=-1
					cache_viewport=-1
					cache_cols=-1
					cache_lines=-1
				fi
				;;
			'?')
				help_visible=$(( 1 - help_visible ))
				status_msg=""
				if [[ "$help_visible" -eq 1 ]]; then
					status_msg="Help visible"
				fi
				need_relist=1
				continue
				;;
			' ')
				if [[ "$count" -gt 0 ]]; then
					if [[ -n "${marked[$selected]+x}" ]]; then
						unset 'marked[$selected]'
						for idx in "${!marked_order[@]}"; do
							if [[ "${marked_order[$idx]}" == "$selected" ]]; then
								unset 'marked_order[$idx]'
								break
							fi
						done
						status_msg="Selection cleared"
					else
						marked["$selected"]=1
						marked_order+=("$selected")
						status_msg="Selected ${#marked_order[@]} item(s)"
					fi
					need_relist=1
				fi
				continue
				;;
			s|S)
				if [[ "$count" -gt 0 ]]; then
					if [[ -n "${marked[$selected]+x}" ]]; then
						unset 'marked[$selected]'
						for idx in "${!marked_order[@]}"; do
							if [[ "${marked_order[$idx]}" == "$selected" ]]; then
								unset 'marked_order[$idx]'
								break
							fi
						done
						status_msg="Selection cleared"
					else
						marked["$selected"]=1
						marked_order+=("$selected")
						status_msg="Selected ${#marked_order[@]} item(s)"
					fi
					need_relist=1
				fi
				continue
				;;
			r|R)
				if [[ "$count" -eq 0 ]]; then
					status_msg="Nothing to remove"
					continue
				fi
				local -a remove_targets=()
				if [[ ${#marked_order[@]} -gt 0 ]]; then
					for idx in "${marked_order[@]}"; do
						remove_targets+=("${entries[$idx]}")
					done
				else
					remove_targets+=("${entries[$selected]}")
				fi
				local valid=1
				local target
				for target in "${remove_targets[@]}"; do
					if [[ ! -e "$target" && ! -L "$target" ]]; then
						status_msg="Missing target: ${target##*/}"
						valid=0
						break
					fi
					if [[ -d "$target" ]]; then
						local files=()
						while IFS= read -r -d '' f; do files+=("$f"); done < <(find "$target" -mindepth 1 -maxdepth 1 -print0)
						if [[ ${#files[@]} -gt 0 ]]; then
							status_msg="Cannot remove non-empty directory: ${target##*/}"
							valid=0
							break
						fi
					fi
				done
				if [[ "$valid" -eq 0 ]]; then
					continue
				fi
				printf "Delete %d item(s)? [y/N] " "${#remove_targets[@]}" >&2
				local answer
				IFS= read -r -n1 answer
				while IFS= read -r -s -n1 -t 0.05 extra; do :; done
				printf '\n' >&2
				if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
					for target in "${remove_targets[@]}"; do
						rm -rf -- "$target" 2>/dev/null || status_msg="Failed to delete: ${target##*/}"
					done
					marked=()
					marked_order=()
					selected=0
					viewport_start=0
					status_msg="Deleted ${#remove_targets[@]} item(s)"
					need_relist=1
				else
					status_msg="Deletion cancelled"
				fi
				;;
			$'\003')
				if [[ "$count" -eq 0 ]]; then
					status_msg="Nothing to copy"
					continue
				fi
				clipboard_paths=()
				if [[ ${#marked_order[@]} -gt 0 ]]; then
					for idx in "${marked_order[@]}"; do
						clipboard_paths+=("${entries[$idx]}")
					done
				else
					clipboard_paths+=("${entries[$selected]}")
				fi
				status_msg="Copied ${#clipboard_paths[@]} item(s)"
				;;
			$'\x16')
				if [[ ${#clipboard_paths[@]} -eq 0 ]]; then
					status_msg="Clipboard empty"
					continue
				fi
				local paste_ok=1
				local source dest_name dest_path suffix
				for source in "${clipboard_paths[@]}"; do
					dest_name="${source##*/}"
					dest_path="$current_dir/$dest_name"
					suffix=1
					while [[ -e "$dest_path" || -L "$dest_path" ]]; do
						dest_path="$current_dir/${dest_name}-copy-$suffix"
						(( suffix++ ))
					done
					cp -a -- "$source" "$dest_path" 2>/dev/null || { paste_ok=0; status_msg="Copy failed: ${source##*/}"; break; }
				done
				if [[ "$paste_ok" -eq 1 ]]; then
					status_msg="Pasted ${#clipboard_paths[@]} item(s) to $current_dir"
					need_relist=1
					selected=0
					viewport_start=0
					marked=()
					marked_order=()
				fi
				;;
			$'\n'|$'\r')
				if [[ "$count" -eq 0 ]]; then
					_nav_cleanup
					trap - EXIT INT TERM
					cd "$current_dir" || return
					return 0
				fi
				local target="${entries[$selected]}"
				if [[ -d "$target" ]]; then
					_nav_cleanup
					trap - EXIT INT TERM
					cd "$target" || return
					return 0
				else
					_nav_cleanup
					trap - EXIT INT TERM
					_nav_open "$target"
					cd "$current_dir" || return
					return 0
				fi
				;;
			*)
				status_msg=""
				;;
			esac
	done
}

cpal() {
	local selected_color=-1
	local key sequence sequence_part button x y row column color ansi_code copy_status
	local block_row block_column cube_row cube_column style_changed
	local style_flags=0 style_name="Default"
	local -a palette_order=()
	local -a green_slices=(0 3 1 4 2 5)

	_cpal_build_order() {
		local palette_color cube_row cube_column green_slice
		local -a green_slices=(0 3 1 4 2 5)

		for (( palette_color = 0; palette_color < 16; palette_color++ )); do
			palette_order+=("$palette_color")
		done
		for green_slice in "${green_slices[@]}"; do
			for (( cube_row = 0; cube_row < 6; cube_row++ )); do
				for (( cube_column = 0; cube_column < 6; cube_column++ )); do
					palette_order+=("$(( 16 + cube_row * 36 + green_slice * 6 + cube_column ))")
				done
			done
		done
		for (( palette_color = 232; palette_color < 256; palette_color++ )); do
			palette_order+=("$palette_color")
		done
	}

	_cpal_copy() {
		local value="$1"
		if command -v wl-copy >/dev/null 2>&1; then
			printf '%s' "$value" | wl-copy 2>/dev/null
		elif command -v xclip >/dev/null 2>&1; then
			printf '%s' "$value" | xclip -selection clipboard 2>/dev/null
		elif command -v xsel >/dev/null 2>&1; then
			printf '%s' "$value" | xsel --clipboard --input 2>/dev/null
		else
			return 1
		fi
	}

	_cpal_make_code() {
		local style_sequence=""
		[[ $(( style_flags & 2 )) -ne 0 ]] && style_sequence+='1;'
		[[ $(( style_flags & 1 )) -ne 0 ]] && style_sequence+='3;'
		[[ $(( style_flags & 4 )) -ne 0 ]] && style_sequence+='4;'
		[[ $(( style_flags & 8 )) -ne 0 ]] && style_sequence+='2;'
		[[ $(( style_flags & 16 )) -ne 0 ]] && style_sequence+='5;'
		[[ $(( style_flags & 32 )) -ne 0 ]] && style_sequence+='7;'
		[[ $(( style_flags & 64 )) -ne 0 ]] && style_sequence+='8;'
		[[ $(( style_flags & 128 )) -ne 0 ]] && style_sequence+='9;'
		[[ $(( style_flags & 256 )) -ne 0 ]] && style_sequence+='21;'
		[[ $(( style_flags & 512 )) -ne 0 ]] && style_sequence+='53;'
		if [[ -z "$style_sequence" ]]; then
			ansi_code="\\033[38;5;${selected_color}m"
		else
			ansi_code="\\033[${style_sequence}38;5;${selected_color}m"
		fi
	}

	_cpal_update_style_name() {
		style_name=""
		[[ $(( style_flags & 2 )) -ne 0 ]] && style_name="Bold"
		[[ $(( style_flags & 1 )) -ne 0 ]] && style_name="${style_name:+$style_name+}Italic"
		[[ $(( style_flags & 4 )) -ne 0 ]] && style_name="${style_name:+$style_name+}Underline"
		[[ $(( style_flags & 8 )) -ne 0 ]] && style_name="${style_name:+$style_name+}Dim"
		[[ $(( style_flags & 16 )) -ne 0 ]] && style_name="${style_name:+$style_name+}Blink"
		[[ $(( style_flags & 32 )) -ne 0 ]] && style_name="${style_name:+$style_name+}Reverse"
		[[ $(( style_flags & 64 )) -ne 0 ]] && style_name="${style_name:+$style_name+}Conceal"
		[[ $(( style_flags & 128 )) -ne 0 ]] && style_name="${style_name:+$style_name+}Strike"
		[[ $(( style_flags & 256 )) -ne 0 ]] && style_name="${style_name:+$style_name+}DoubleUnderline"
		[[ $(( style_flags & 512 )) -ne 0 ]] && style_name="${style_name:+$style_name+}Overline"
		[[ -z "$style_name" ]] && style_name="Default"
	}

	_cpal_cleanup() {
		printf '\033[?1000l\033[?1006l\033[?25h\033[0m\n'
		stty echo icanon 2>/dev/null
	}

	_cpal_draw() {
		local palette_color cube_row cube_column block_row block_column green_slice
		local -a green_slices=(0 3 1 4 2 5)
		local draw_swatch

		draw_swatch() {
			local swatch_color="$1"
			if [[ "$swatch_color" -eq "$selected_color" ]]; then
				printf '\033[48;5;%dm\033[4m   \033[0m' "$swatch_color"
			else
				printf '\033[48;5;%dm   \033[0m' "$swatch_color"
			fi
		}

		printf '\033[2J\033[H'
		printf 'ANSI 256 colors (click a color to copy its code, or press q to quit)\n\n'
		printf 'Standard: '
		for (( palette_color = 0; palette_color < 8; palette_color++ )); do draw_swatch "$palette_color"; done
		printf '\nIntense : '
		for (( palette_color = 8; palette_color < 16; palette_color++ )); do draw_swatch "$palette_color"; done
		printf '\n\n'

		for (( block_row = 0; block_row < 2; block_row++ )); do
			for (( cube_row = 0; cube_row < 6; cube_row++ )); do
				for (( block_column = 0; block_column < 3; block_column++ )); do
					green_slice="${green_slices[$(( block_row * 3 + block_column ))]}"
					for (( cube_column = 0; cube_column < 6; cube_column++ )); do
						palette_color=$(( 16 + cube_row * 36 + green_slice * 6 + cube_column ))
						draw_swatch "$palette_color"
					done
					[[ "$block_column" -lt 2 ]] && printf '   '
				done
				printf '\n'
			done
			[[ "$block_row" -eq 0 ]] && printf '\n'
		done
		printf '\n'
		printf 'Grays:  '
		for (( palette_color = 232; palette_color < 244; palette_color++ )); do draw_swatch "$palette_color"; done
		printf '\n        '
		for (( palette_color = 244; palette_color < 256; palette_color++ )); do draw_swatch "$palette_color"; done
		printf '\n'
		printf 'Style: [1 Default/reset]  [2 %s]  [3 %s]  [4 %s]\n' \
			"$([[ $(( style_flags & 1 )) -ne 0 ]] && printf '*Italic' || printf 'Italic')" \
			"$([[ $(( style_flags & 2 )) -ne 0 ]] && printf '*Bold' || printf 'Bold')" \
			"$([[ $(( style_flags & 4 )) -ne 0 ]] && printf '*Underline' || printf 'Underline')"
		printf '       [5 %s]  [6 %s]  [7 %s]  [8 %s]\n' \
			"$([[ $(( style_flags & 8 )) -ne 0 ]] && printf '*Dim' || printf 'Dim')" \
			"$([[ $(( style_flags & 16 )) -ne 0 ]] && printf '*Blink' || printf 'Blink')" \
			"$([[ $(( style_flags & 32 )) -ne 0 ]] && printf '*Reverse' || printf 'Reverse')" \
			"$([[ $(( style_flags & 64 )) -ne 0 ]] && printf '*Conceal' || printf 'Conceal')"
		printf '       [9 %s]  [0 %s]  [a %s]\n' \
			"$([[ $(( style_flags & 128 )) -ne 0 ]] && printf '*Strike' || printf 'Strike')" \
			"$([[ $(( style_flags & 256 )) -ne 0 ]] && printf '*DoubleUnderline' || printf 'DoubleUnderline')" \
			"$([[ $(( style_flags & 512 )) -ne 0 ]] && printf '*Overline' || printf 'Overline')"

		if [[ "$selected_color" -ge 0 ]]; then
			printf '\nSelected color: %d\n' "$selected_color"
			printf 'Style: %s\n' "$style_name"
			printf 'Copied: %s\n' "$ansi_code"
		else
			printf '\nClick a swatch to copy its selected style.\n'
		fi
	}

	_cpal_build_order
	trap '_cpal_cleanup' EXIT INT TERM
	stty -echo -icanon min 1 time 0 2>/dev/null || {
		trap - EXIT INT TERM
		return 1
	}
	printf '\033[?1000h\033[?1006h\033[?25l'

	while true; do
		_cpal_draw
		IFS= read -r -n1 key

		if [[ "$key" == $'\033' ]]; then
			IFS= read -r -n1 sequence
			if [[ "$sequence" == '[' ]]; then
				IFS= read -r -n1 sequence
				if [[ "$sequence" == '<' ]]; then
					sequence=''
					while IFS= read -r -n1 sequence_part; do
						sequence+="$sequence_part"
						[[ "$sequence_part" == 'M' || "$sequence_part" == 'm' ]] && break
					done
					IFS=';' read -r button x y <<< "${sequence%[Mm]}"
					if [[ "$button" == 0 && "$x" =~ ^[0-9]+$ && "$y" =~ ^[0-9]+$ ]]; then
						color=-1
						style_changed=0
						if [[ "$y" -eq 3 || "$y" -eq 4 ]]; then
							column=$(( (x - 11) / 3 ))
							if [[ "$x" -ge 11 && "$x" -lt 35 && "$column" -lt 8 ]]; then
								color=$(( column + (y - 3) * 8 ))
							fi
						elif [[ "$y" -ge 6 && "$y" -le 11 || "$y" -ge 13 && "$y" -le 18 ]]; then
							block_row=0
							[[ "$y" -ge 13 ]] && block_row=1
							cube_row=$(( y - 6 - block_row * 7 ))
							block_column=$(( (x - 1) / 21 ))
							cube_column=$(( (x - 1 - block_column * 21) / 3 ))
							if [[ "$x" -ge 1 && "$block_column" -lt 3 && "$cube_column" -lt 6 ]]; then
								color=$(( 16 + cube_row * 36 + ${green_slices[$(( block_row * 3 + block_column ))]} * 6 + cube_column ))
							fi
						elif [[ "$y" -eq 20 || "$y" -eq 21 ]]; then
							column=$(( (x - 9) / 3 ))
							if [[ "$x" -ge 9 && "$x" -lt 45 && "$column" -lt 12 ]]; then
								color=$(( 232 + column + (y - 20) * 12 ))
							fi
						elif [[ "$y" -eq 22 ]]; then
							if [[ "$x" -ge 8 && "$x" -lt 25 ]]; then
								style_flags=0
								style_changed=1
							elif [[ "$x" -ge 27 && "$x" -lt 39 ]]; then
								style_flags=$(( style_flags ^ 1 ))
								style_changed=1
							elif [[ "$x" -ge 41 && "$x" -lt 52 ]]; then
								style_flags=$(( style_flags ^ 2 ))
								style_changed=1
							elif [[ "$x" -ge 54 && "$x" -lt 70 ]]; then
								style_flags=$(( style_flags ^ 4 ))
								style_changed=1
							fi
						elif [[ "$y" -eq 23 ]]; then
							if [[ "$x" -ge 8 && "$x" -lt 17 ]]; then style_flags=$(( style_flags ^ 8 )); style_changed=1
							elif [[ "$x" -ge 19 && "$x" -lt 30 ]]; then style_flags=$(( style_flags ^ 16 )); style_changed=1
							elif [[ "$x" -ge 32 && "$x" -lt 45 ]]; then style_flags=$(( style_flags ^ 32 )); style_changed=1
							elif [[ "$x" -ge 47 && "$x" -lt 59 ]]; then style_flags=$(( style_flags ^ 64 )); style_changed=1
							fi
						elif [[ "$y" -eq 24 ]]; then
							if [[ "$x" -ge 8 && "$x" -lt 18 ]]; then style_flags=$(( style_flags ^ 128 )); style_changed=1
							elif [[ "$x" -ge 20 && "$x" -lt 38 ]]; then style_flags=$(( style_flags ^ 256 )); style_changed=1
							elif [[ "$x" -ge 40 && "$x" -lt 51 ]]; then style_flags=$(( style_flags ^ 512 )); style_changed=1
							fi
							_cpal_update_style_name
						fi
						if [[ "$color" -ge 0 ]]; then
							selected_color="$color"
							_cpal_make_code
							_cpal_copy "$ansi_code"
							copy_status="$?"
							_cpal_draw
							if [[ "$copy_status" -ne 0 ]]; then
								printf 'Clipboard unavailable; code: %s\n' "$ansi_code"
							fi
						elif [[ "$style_changed" -eq 1 && "$selected_color" -ge 0 ]]; then
							_cpal_make_code
							_cpal_copy "$ansi_code"
						fi
					fi
				fi
			else
				_cpal_cleanup
				trap - EXIT INT TERM
				return 0
			fi
		elif [[ "$key" == 'q' || "$key" == 'Q' ]]; then
			_cpal_cleanup
			trap - EXIT INT TERM
			return 0
		elif [[ "$key" == '1' || "$key" == '2' || "$key" == '3' || "$key" == '4' || "$key" == '5' || "$key" == '6' || "$key" == '7' || "$key" == '8' || "$key" == '9' || "$key" == '0' || "$key" == 'a' || "$key" == 'A' ]]; then
			case "$key" in
				1) style_flags=0 ;;
				2) style_flags=$(( style_flags ^ 1 )) ;;
				3) style_flags=$(( style_flags ^ 2 )) ;;
				4) style_flags=$(( style_flags ^ 4 )) ;;
				5) style_flags=$(( style_flags ^ 8 )) ;;
				6) style_flags=$(( style_flags ^ 16 )) ;;
				7) style_flags=$(( style_flags ^ 32 )) ;;
				8) style_flags=$(( style_flags ^ 64 )) ;;
				9) style_flags=$(( style_flags ^ 128 )) ;;
				0) style_flags=$(( style_flags ^ 256 )) ;;
				a|A) style_flags=$(( style_flags ^ 512 )) ;;
			esac
			_cpal_update_style_name
			if [[ "$selected_color" -ge 0 ]]; then
				_cpal_make_code
				_cpal_copy "$ansi_code"
			fi
		fi
	done
}


#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════
#  Subnet oracle for Bash42
#  Helps visualize host ranges, subnet masks and network calculations.
#  Usage:
#    iph 192.168.1.10/24              -> full analysis
#    iph 192.168.1.10 255.255.255.0   -> full analysis (IP + mask)
#    iph 255.255.255.0                -> mask info only
#    iph /24                          -> mask info only (CIDR)
#    iph 192.168.1.5/24 192.168.1.200 -> compare 2 IPs (same subnet?)
#    masktable                            -> subnet mask reference table
# ═══════════════════════════════════════════════════════════════════════════

# ─── Colors ──────────────────────────────────────────────────────────────
_nl_reset="\033[0m"; _nl_bold="\033[1m"; _nl_dim="\033[2m"
_nl_cyan="\033[36m"; _nl_green="\033[32m"; _nl_yellow="\033[33m"
_nl_magenta="\033[35m"; _nl_red="\033[31m"; _nl_blue="\033[34m"

_NL_WIDTH=77  # inner content width of the box

# ─── Conversion helpers ──────────────────────────────────────────────────
_nl_ip_to_int() {
    local IFS=.; local a b c d
    read -r a b c d <<< "$1"
    echo $(( (a<<24) + (b<<16) + (c<<8) + d ))
}

_nl_int_to_ip() {
    local ip=$1
    echo "$(( (ip>>24)&255 )).$(( (ip>>16)&255 )).$(( (ip>>8)&255 )).$(( ip&255 ))"
}

_nl_cidr_to_maskint() {
    local cidr=$1
    if [ "$cidr" -lt 0 ] || [ "$cidr" -gt 32 ]; then
        echo -e "${_nl_red}Invalid CIDR: /$cidr (must be between /0 and /32)${_nl_reset}" >&2
        return 1
    fi
    if [ "$cidr" -eq 0 ]; then echo 0; return; fi
    echo $(( (0xFFFFFFFF << (32-cidr)) & 0xFFFFFFFF ))
}

_nl_maskint_to_cidr() {
    local m=$1 cidr=0 i
    for ((i=31; i>=0; i--)); do
        if (( (m>>i)&1 )); then
            cidr=$((cidr+1))
        else
            break
        fi
    done
    echo "$cidr"
}

_nl_byte_to_bin() {
    local n=$1 bin="" i
    for ((i=7; i>=0; i--)); do bin+=$(( (n>>i)&1 )); done
    echo "$bin"
}

_nl_int_to_bin_dotted() {
    local int=$1 out="" s
    for s in 24 16 8 0; do
        out+="$(_nl_byte_to_bin $(( (int>>s)&255 ))).";
    done
    echo "${out%.}"
}

_nl_is_valid_mask() {
    local bin
    bin=$(_nl_int_to_bin_dotted "$1" | tr -d '.')
    [[ $bin =~ ^1*0*$ ]]
}

_nl_int_to_hex() {
    printf '0x%08X\n' "$1"
}

# ─── Historic "class" detection (informational only) ────────────────────
_nl_class_of() {
    local first=$(( ($1>>24)&255 ))
    if   (( first < 128 )); then echo "A"
    elif (( first < 192 )); then echo "B"
    elif (( first < 224 )); then echo "C"
    elif (( first < 240 )); then echo "D (multicast)"
    else echo "E (reserved)"
    fi
}

# ─── Box drawing (pure ASCII width, no wide chars -> reliable alignment) ─
_nl_top()  { printf "${_nl_cyan}+"; printf '%*s' "$_NL_WIDTH" '' | tr ' ' '='; printf "+${_nl_reset}\n"; }
_nl_bot()  { _nl_top; }
_nl_sep()  { _nl_top; }

_nl_title() {
    printf "${_nl_cyan}|${_nl_reset} ${_nl_bold}${_nl_magenta}%-*s${_nl_reset}${_nl_cyan}|${_nl_reset}\n" "$((_NL_WIDTH-1))" "$1"
}

_nl_kv() {
    # $1 label, $2 value, $3 value color (optional)
    local color=${3:-$_nl_green}
    printf "${_nl_cyan}|${_nl_reset} ${_nl_dim}%-22s${_nl_reset} ${color}%-*s${_nl_reset}${_nl_cyan}|${_nl_reset}\n" \
        "$1" "$((_NL_WIDTH-24))" "$2"
}

# ─── Mask-only display ────────────────────────────────────────────────────
_nl_show_mask_info() {
    local mask_int=$1
    local cidr dotted hex bin wildcard_int wildcard nb_hosts

    if ! _nl_is_valid_mask "$mask_int"; then
        printf "${_nl_red}Invalid mask (1-bits not contiguous)${_nl_reset}\n"
        return 1
    fi

    cidr=$(_nl_maskint_to_cidr "$mask_int")
    dotted=$(_nl_int_to_ip "$mask_int")
    hex=$(_nl_int_to_hex "$mask_int")
    bin=$(_nl_int_to_bin_dotted "$mask_int")
    wildcard_int=$(( (~mask_int) & 0xFFFFFFFF ))
    wildcard=$(_nl_int_to_ip "$wildcard_int")

    if (( cidr >= 31 )); then
        nb_hosts=$(( cidr == 32 ? 1 : 2 ))
    else
        nb_hosts=$(( (1 << (32-cidr)) - 2 ))
    fi

    _nl_top
    _nl_title "IPH - Subnet mask"
    _nl_sep
    _nl_kv "CIDR"           "/$cidr" "$_nl_yellow"
    _nl_kv "Dotted decimal" "$dotted"
    _nl_kv "Hexadecimal"    "$hex"
    _nl_kv "Binary"         "$bin"
    _nl_kv "Wildcard"       "$wildcard"
    _nl_kv "Usable hosts"   "$nb_hosts per network"
    _nl_bot
}

# ─── Full IP+mask analysis display ────────────────────────────────────────
_nl_show_full() {
    local ip_int=$1 mask_int=$2
    local cidr dotted_mask net_int bcast_int first_int last_int
    local nb_hosts class ip_bin mask_bin net_bin

    cidr=$(_nl_maskint_to_cidr "$mask_int")
    dotted_mask=$(_nl_int_to_ip "$mask_int")
    net_int=$(( ip_int & mask_int ))
    bcast_int=$(( net_int | ((~mask_int) & 0xFFFFFFFF) ))
    class=$(_nl_class_of "$ip_int")

    if (( cidr >= 31 )); then
        if (( cidr == 32 )); then
            first_int=$ip_int; last_int=$ip_int; nb_hosts=1
        else
            first_int=$net_int; last_int=$bcast_int; nb_hosts=2
        fi
    else
        first_int=$((net_int+1)); last_int=$((bcast_int-1))
        nb_hosts=$(( (1 << (32-cidr)) - 2 ))
    fi

    ip_bin=$(_nl_int_to_bin_dotted "$ip_int")
    mask_bin=$(_nl_int_to_bin_dotted "$mask_int")
    net_bin=$(_nl_int_to_bin_dotted "$net_int")

    _nl_top
    _nl_title "iph - Subnet analysis"
    _nl_sep
    _nl_kv "IP address"        "$(_nl_int_to_ip "$ip_int")" "$_nl_yellow"
    _nl_kv "Mask"               "$dotted_mask  (/$cidr)"
    _nl_kv "Class (info)"       "$class" "$_nl_dim"
    _nl_sep
    _nl_kv "Network address"    "$(_nl_int_to_ip "$net_int")" "$_nl_blue"
    _nl_kv "Broadcast"          "$(_nl_int_to_ip "$bcast_int")" "$_nl_blue"
    _nl_kv "Host range"         "$(_nl_int_to_ip "$first_int") -> $(_nl_int_to_ip "$last_int")" "$_nl_green"
    _nl_kv "Usable hosts"       "$nb_hosts"
    _nl_sep
    _nl_kv "IP (binary)"        "$ip_bin" "$_nl_dim"
    _nl_kv "Mask (binary)"      "$mask_bin" "$_nl_dim"
    _nl_kv "Network (binary)"   "$net_bin" "$_nl_dim"
    _nl_bot
}

# ─── Compare two IPs (same subnet?) ───────────────────────────────────────
_nl_compare() {
    local ip1_int=$1 mask_int=$2 ip2_int=$3

    local net1=$(( ip1_int & mask_int ))
    local net2=$(( ip2_int & mask_int ))
    _nl_sep
    if (( net1 == net2 )); then
        _nl_kv "Comparison" "OK - $(_nl_int_to_ip "$ip2_int") is in the same subnet" "$_nl_green"
    else
        _nl_kv "Comparison" "NO - $(_nl_int_to_ip "$ip2_int") is NOT in this subnet" "$_nl_red"
        _nl_kv "  -> network of IP 2" "$(_nl_int_to_ip "$net2")"
    fi
    _nl_bot
}

# ─── Main function ─────────────────────────────────────────────────────────
iph() {
    if [ $# -eq 0 ]; then
        echo -e "${_nl_yellow}Usage:${_nl_reset}"
        echo "  iph 192.168.1.10/24"
        echo "  iph 192.168.1.10 255.255.255.0"
        echo "  iph 255.255.255.0        # mask only"
        echo "  iph /24                  # mask only"
        echo "  iph 192.168.1.5/24 192.168.1.200   # compare 2 IPs"
        return 1
    fi

    local arg1=$1 arg2=$2
    local ip_int mask_int

    # Case: mask only, /24 form
    if [[ $arg1 =~ ^/([0-9]{1,2})$ ]] && [ $# -eq 1 ]; then
        mask_int=$(_nl_cidr_to_maskint "${BASH_REMATCH[1]}") || return 1
        _nl_show_mask_info "$mask_int"
        return
    fi

    # Case: IP/CIDR
    if [[ $arg1 =~ ^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/([0-9]{1,2})$ ]]; then
        ip_int=$(_nl_ip_to_int "${BASH_REMATCH[1]}")
        mask_int=$(_nl_cidr_to_maskint "${BASH_REMATCH[2]}") || return 1
        _nl_show_full "$ip_int" "$mask_int"
        if [ -n "$arg2" ] && [[ $arg2 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            _nl_compare "$ip_int" "$mask_int" "$(_nl_ip_to_int "$arg2")"
        fi
        return
    fi

    # Case: separate IP + mask
    if [[ $arg1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && [ -n "$arg2" ] \
       && [[ $arg2 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        ip_int=$(_nl_ip_to_int "$arg1")
        local maybe_mask_int
        maybe_mask_int=$(_nl_ip_to_int "$arg2")
        if _nl_is_valid_mask "$maybe_mask_int"; then
            _nl_show_full "$ip_int" "$maybe_mask_int"
        else
            echo -e "${_nl_red}'$arg2' is not a valid mask.${_nl_reset}"
            return 1
        fi
        return
    fi

    # Case: mask only, dotted decimal form
    if [[ $arg1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && [ -z "$arg2" ]; then
        mask_int=$(_nl_ip_to_int "$arg1")
        if _nl_is_valid_mask "$mask_int"; then
            _nl_show_mask_info "$mask_int"
        else
            echo -e "${_nl_yellow}'$arg1' looks like an IP, not a mask.${_nl_reset}"
            echo "  Specify a mask: iph $arg1/24  or  iph $arg1 255.255.255.0"
        fi
        return
    fi

    echo -e "${_nl_red}Unrecognized format.${_nl_reset} Run 'iph' with no argument for help."
    return 1
}

# ─── Mask reference table ──────────────────────────────────────────────────
mask() {
    _nl_top
    _nl_title "IPH - Subnet mask reference table"
    _nl_sep
	printf "${_nl_cyan}|${_nl_reset} ${_nl_bold}%-6s %-17s %-12s %-16s %-14s${_nl_reset}%*s${_nl_cyan}|${_nl_reset}\n" \
		"CIDR" "Mask" "Hex" "Wildcard" "Hosts" 7 ""
    _nl_sep
    local c m_int wc_int hosts
    for c in $(seq 1 32); do
        m_int=$(_nl_cidr_to_maskint "$c")
        wc_int=$(( (~m_int) & 0xFFFFFFFF ))
        if (( c >= 31 )); then hosts=$(( c==32 ? 1 : 2 )); else hosts=$(( (1<<(32-c))-2 )); fi
        printf "${_nl_cyan}|${_nl_reset} %-6s %-17s %-12s %-16s %-14s%*s${_nl_cyan}|${_nl_reset}\n" \
            "/$c" "$(_nl_int_to_ip "$m_int")" "$(_nl_int_to_hex "$m_int" | sed 's/0x//')" \
			"$(_nl_int_to_ip "$wc_int")" "$hosts" 7 ""
    done
    _nl_bot
}
