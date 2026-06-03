### Terminal ###

nav() {
	# ── Colors & styles ──────────────────────────────────────────
	local C_RESET="\033[0m"
	local C_DIR="\033[1;36m"      # Bold cyan  → directories
	local C_FILE="\033[0;37m"     # Light grey → regular files
	local C_SEL="\033[7;36m"      # Reverse cyan → selected item
	local C_PATH="\033[1;33m"     # Yellow → breadcrumb
	local C_HINT="\033[2;37m"     # Dim grey → keybinds hint
	local C_EMPTY="\033[2;31m"    # Dim red → empty dir message
	local C_SCROLL="\033[2;36m"   # Dim cyan → scroll indicator

	# ── State ────────────────────────────────────────────────────
	local current_dir
	current_dir="$(pwd)"
	local selected=0
	local show_hidden=0

	# ── Cleanup: always restore cursor & terminal on exit ────────
	_nav_cleanup() {
		tput cnorm
		tput rmcup
		stty echo 2>/dev/null
	}
	trap '_nav_cleanup' EXIT INT TERM
	trap '' INT

	# ── Init alternate screen ────────────────────────────────────
	tput smcup
	tput civis

	# ── Helper: build entry list ──────────────────────────────────
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

	# ── Helper: draw UI with viewport ────────────────────────────
	_nav_draw() {
		local dir="$1"
		local sel="$2"
		local count="$3"
		local viewport_start="$4"
		local viewport_size="$5"
		shift 5
		local -a entries=("$@")

		tput clear

		# — Header (3 lines) —
		printf "${C_PATH}  %s${C_RESET}\n" "$dir"
		printf "${C_HINT}  [↑↓: Navigate]  [→: Enter dir]  [←: Parent]  [Enter: Cd here]  [h: Show hidden]  [q: Quit]${C_RESET}\n"
		echo ""

		# — Empty dir —
		if [[ "$count" -eq 0 ]]; then
			printf "  ${C_EMPTY}(empty directory)${C_RESET}\n"
			return
		fi

		# — Visible entries —
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

		# — Scroll indicator (bottom) —
		if [[ "$count" -gt "$viewport_size" ]]; then
			printf "\n  ${C_SCROLL}[ %d / %d ]${C_RESET}\n" "$(( sel + 1 ))" "$count"
		fi
	}

	# ── Main loop ─────────────────────────────────────────────────
	local -a entries
	local key esc_seq
	local viewport_start=0

	while true; do
		mapfile -t entries < <(_nav_list "$current_dir")
		local count="${#entries[@]}"

		# Clamp selection
		[[ "$count" -eq 0 ]] && selected=0
		[[ "$selected" -ge "$count" && "$count" -gt 0 ]] && selected=$(( count - 1 ))

		# Compute viewport
		# Header = 3 lines, scroll indicator = 2 lines → reserve 5
		local term_lines
		term_lines="$(tput lines)"
		local viewport_size=$(( term_lines - 5 ))
		[[ "$viewport_size" -lt 1 ]] && viewport_size=1

		# Scroll viewport to follow selection
		if [[ "$selected" -lt "$viewport_start" ]]; then
			viewport_start="$selected"
		elif [[ "$selected" -ge $(( viewport_start + viewport_size )) ]]; then
			viewport_start=$(( selected - viewport_size + 1 ))
		fi

		_nav_draw "$current_dir" "$selected" "$count" \
			"$viewport_start" "$viewport_size" "${entries[@]}"

		# Read keypress
		IFS= read -r -s -n1 key

		if [[ "$key" == $'\x1b' ]]; then
			IFS= read -r -s -n1 -t 0.1 esc_seq
			if [[ "$esc_seq" == '[' ]]; then
				IFS= read -r -s -n1 -t 0.1 esc_seq
				case "$esc_seq" in
					A)  # ↑
						[[ "$selected" -gt 0 ]] && (( selected-- ))
						continue
						;;
					B)  # ↓
						[[ "$count" -gt 0 && "$selected" -lt $(( count - 1 )) ]] && (( selected++ ))
						continue
						;;
					C)  # → enter dir
						if [[ "$count" -gt 0 && -d "${entries[$selected]}" ]]; then
							current_dir="${entries[$selected]}"
							selected=0
							viewport_start=0
						fi
						continue
						;;
					D)  # ← parent
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
				# ESC → quit
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
					_nav_cleanup
					trap - EXIT INT TERM
					vim "$target"
					cd "$current_dir" || return
					return 0
				fi
				;;
		esac
	done
}
