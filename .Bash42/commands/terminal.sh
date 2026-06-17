### Terminal ###

nav() {
	local C_RESET="\033[0m"
	local C_DIR="\033[1;36m"
	local C_FILE="\033[0;37m"
	local C_SEL="\033[7;36m"
	local C_PATH="\033[1;33m"
	local C_HINT="\033[2;37m"
	local C_EMPTY="\033[2;31m"
	local C_SCROLL="\033[2;36m"

	local current_dir
	current_dir="$(pwd)"
	local selected=0
	local show_hidden=0

	_nav_cleanup() {
		tput cnorm
		tput rmcup
		stty echo 2>/dev/null
	}
	trap '_nav_cleanup' EXIT INT TERM
	trap '' INT

	# ── NOUVEAU : ouvre avec la bonne app ────────────────────────
	_nav_open() {
		local file="$1"
		local ext="${file##*.}"
		case "$ext" in
			sh|bash|zsh|py|js|ts|json|yaml|yml|toml|conf|cfg|ini|\
			txt|md|rst|csv|log|env|gitignore|dockerfile)
				vim "$file"
				;;
			*)
				xdg-open "$file" &>/dev/null &
				;;
		esac
	}

	tput smcup
	tput civis

	_nav_list() {
		local dir="$1"
		local f
		while IFS= read -r f; do
			[[ "$show_hidden" -eq 0 && "${f##*/}" == .* ]] && continue
			printf '%s\n' "$f"
		done < <(
			{
				find "$dir" -maxdepth 1 -mindepth 1 -type d | sort -n
				find "$dir" -maxdepth 1 -mindepth 1 ! -type d | sort -n
			}
		)
	}

	_nav_draw() {
		local dir="$1"
		local sel="$2"
		local count="$3"
		local viewport_start="$4"
		local viewport_size="$5"
		shift 5
		local -a entries=("$@")

		tput clear

		printf "${C_PATH}  %s${C_RESET}\n" "$dir"
		# ── NOUVEAU : hint mis à jour avec c et x ────────────────
		printf "${C_HINT}  [↑↓: Navigate]  [→: Enter dir]  [←: Parent]  [Enter: Cd here]  [c: VS Code]  [x: Exécuter]  [h: Hidden]  [q: Quit]${C_RESET}\n"
		echo ""

		if [[ "$count" -eq 0 ]]; then
			printf "  ${C_EMPTY}(empty directory)${C_RESET}\n"
			return
		fi

		local i name base label
		local end=$(( viewport_start + viewport_size ))
		[[ "$end" -gt "$count" ]] && end="$count"

		for (( i=viewport_start; i<end; i++ )); do
			name="${entries[$i]}"
			base="${name##*/}"

			if [[ -d "$name" ]]; then
				label="${base}/"
				if [[ "$i" -eq "$sel" ]]; then
					printf "  ${C_SEL} %-50s ${C_RESET}\n" "$label"
				else
					printf "  ${C_DIR}%-50s${C_RESET}\n" "$label"
				fi
			else
				label="$base"
				if [[ "$i" -eq "$sel" ]]; then
					printf "  ${C_SEL} %-50s ${C_RESET}\n" "$label"
				else
					printf "  ${C_FILE}%-50s${C_RESET}\n" "$label"
				fi
			fi
		done

		if [[ "$count" -gt "$viewport_size" ]]; then
			printf "\n  ${C_SCROLL}[ %d / %d ]${C_RESET}\n" "$(( sel + 1 ))" "$count"
		fi
	}

	local -a entries
	local key esc_seq
	local viewport_start=0

	while true; do
		mapfile -t entries < <(_nav_list "$current_dir")
		local count="${#entries[@]}"

		[[ "$count" -eq 0 ]] && selected=0
		[[ "$selected" -ge "$count" && "$count" -gt 0 ]] && selected=$(( count - 1 ))

		local term_lines
		term_lines="$(tput lines)"
		local viewport_size=$(( term_lines - 5 ))
		[[ "$viewport_size" -lt 1 ]] && viewport_size=1

		if [[ "$selected" -lt "$viewport_start" ]]; then
			viewport_start="$selected"
		elif [[ "$selected" -ge $(( viewport_start + viewport_size )) ]]; then
			viewport_start=$(( selected - viewport_size + 1 ))
		fi

		_nav_draw "$current_dir" "$selected" "$count" \
			"$viewport_start" "$viewport_size" "${entries[@]}"

		IFS= read -r -s -n1 key

		if [[ "$key" == $'\x1b' ]]; then
			IFS= read -r -s -n1 -t 0.1 esc_seq
			if [[ "$esc_seq" == '[' ]]; then
				IFS= read -r -s -n1 -t 0.1 esc_seq
				case "$esc_seq" in
					A)
						[[ "$selected" -gt 0 ]] && (( selected-- ))
						continue
						;;
					B)
						[[ "$count" -gt 0 && "$selected" -lt $(( count - 1 )) ]] && (( selected++ ))
						continue
						;;
					C)
						if [[ "$count" -gt 0 && -d "${entries[$selected]}" ]]; then
							current_dir="${entries[$selected]}"
							selected=0
							viewport_start=0
						fi
						continue
						;;
					D)
						local parent
						parent="$(dirname "$current_dir")"
						if [[ "$parent" != "$current_dir" ]]; then
							current_dir="$parent"
							selected=0
							viewport_start=0
						fi
						continue
						;;
				esac
			else
				_nav_cleanup
				trap - EXIT INT TERM
				return 0
			fi
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
				;;

			# ── NOUVEAU : touche c → VS Code ─────────────────────
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

			# ── NOUVEAU : touche x → exécuter ────────────────────
			x|X)
				if [[ "$count" -gt 0 && ! -d "${entries[$selected]}" ]]; then
					local target="${entries[$selected]}"
					local ext="${target##*.}"
					local cmd
					if [[ "$ext" == "py" ]]; then
						cmd="python3 \"$target\""
					else
						cmd="\"$target\""
					fi
					tput rmcup
					tput cnorm
					printf "Exécuter: %s " "$cmd"
					local extra_args
					IFS= read -r extra_args
					eval "$cmd $extra_args"
					printf "\n[Terminé — appuie sur Entrée]"
					read -r
					tput smcup
					tput civis
				fi
				;;

			'')  # Enter
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
					# ── MODIFIÉ : _nav_open au lieu de vim ───────
					_nav_cleanup
					trap - EXIT INT TERM
					_nav_open "$target"
					cd "$current_dir" || return
					return 0
				fi
				;;
		esac
	done
}
#
