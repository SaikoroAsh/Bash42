### Terminal ###

nav() {
	# ── Charte graphique : cyan/blanc-gras (style welcome42) ─────
	local C_RESET="\033[0m"
	local C_DIR="\033[1;37m"          # blanc gras  — dossiers
	local C_FILE="\033[0;36m"         # cyan        — fichiers
	local C_SEL="\033[1;30;46m"       # bg cyan, texte noir gras — sélection
	local C_PATH="\033[1;37m"         # blanc gras  — chemin courant
	local C_HINT="\033[2;36m"         # cyan dim    — hints
	local C_EMPTY="\033[2;31m"        # rouge dim   — vide
	local C_SCROLL="\033[0;36m"       # cyan        — compteur scroll
	local C_SEP="\033[0;36m"          # cyan        — séparateurs ╔╗╚╝║═
	# Preview — même palette mais dim
	local C_PRE_DIR="\033[2;37m"      # blanc dim
	local C_PRE_FILE="\033[2;36m"     # cyan dim
	local C_PRE_TITLE="\033[1;36m"    # cyan gras
	local C_PRE_EMPTY="\033[2;31m"    # rouge dim
	local C_PRE_SEP="\033[2;36m"      # cyan dim

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
				find "$dir" -maxdepth 1 -mindepth 1 -type d | sort
				find "$dir" -maxdepth 1 -mindepth 1 ! -type d | sort
			}
		)
	}

	# ── Preview : retourne les lignes de contenu d'un dossier ─────
	# Chaque ligne est terminée par \0 pour supporter les caractères spéciaux
	_nav_preview_lines() {
		local dir="$1"
		local col_w="$2"     # largeur VISUELLE disponible (sans le │)
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

		# Titre
		local title_raw=" ${dir##*/}/"
		local max_title=$(( col_w - 2 ))
		[[ ${#title_raw} -gt $max_title ]] && title_raw="${title_raw:0:$max_title}…"
		plines+=("${C_PRE_TITLE}${title_raw}${C_RESET}")

		# Séparateur ----- (ASCII, toujours 1 colonne)
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
				local ilabel icolor
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

		# Au lieu de tput clear (efface tout l'écran → flash visible),
		# on replace juste le curseur en haut à gauche, puis chaque ligne
		# est effacée (tput el) avant d'être réécrite. tput ed à la toute
		# fin nettoie un éventuel résidu si le nouveau contenu est plus
		# court que l'ancien (ex: moins de fichiers, preview fermée).
		tput cup 0 0
		local EL
		EL="$(tput el)"   # erase to end of line, capturé une seule fois

		# ── Dimensions ───────────────────────────────────────────
		local term_cols term_lines
		term_cols="$(tput cols)"
		term_lines="$(tput lines)"

		# Layout exact par ligne :
		#   "  " (2) + left_content (left_w) + " " (1) + "│" (1) + right_content (right_w)
		#   = left_w + right_w + 4 = term_cols
		# Donc :
		#   left_w  = term_cols/2 - 3   (│ tombe pile à term_cols/2)
		#   right_w = term_cols - left_w - 4
		local left_w=$(( term_cols / 2 - 3 ))
		[[ "$left_w" -lt 10 ]] && left_w=10
		local right_w=$(( term_cols - left_w - 4 ))
		[[ "$right_w" -lt 5 ]] && right_w=5

		# ── En-tête ──────────────────────────────────────────────
		# On évite les chars box-drawing double-trait (═║╔╗╠╣) qui ont
		# east_asian_width=Ambiguous et peuvent occuper 2 colonnes sur
		# certains terminaux (macOS iTerm2, Terminal.app).
		# On utilise à la place des tirets ASCII simples et |, garantis 1 col.
		#
		# Layout bordure : "  +" (3) + border_w×"-" + "+" (1) = term_cols
		#   → border_w = term_cols - 4
		# Layout ligne ║  : "  |  " (5) + content_w + "  |" (3) = term_cols
		#   → content_w = term_cols - 8
		local border_w=$(( term_cols - 4 ))
		local content_w=$(( term_cols - 8 ))
		[[ "$content_w" -lt 1 ]] && content_w=1

		local border_line
		border_line=$(printf '%*s' "$border_w" '' | tr ' ' '-')
		printf "${C_SEP}  +%s+${C_RESET}${EL}\n" "$border_line"

		# Chemin : tronquer par la gauche si nécessaire (garde la fin du path)
		local dir_display="$dir"
		if [[ ${#dir_display} -gt $content_w ]]; then
			dir_display="~${dir_display:$(( ${#dir_display} - content_w + 1 ))}"
		fi
		# Pad manuel pour éviter que printf %-*s compte les bytes ANSI comme des colonnes
		local dir_pad=$(( content_w - ${#dir_display} ))
		local dir_spaces
		dir_spaces=$(printf '%*s' "$dir_pad" '')
		printf "${C_SEP}  |${C_RESET}  ${C_PATH}%s${dir_spaces}${C_RESET}  ${C_SEP}|${C_RESET}${EL}\n" \
			"$dir_display"

		# Hints : tronquer si terminal trop étroit
		local hint="[↵] Cd here  [c] VSCode  [x] Execute  [h] Show Hidden  [q] Quit"
		if [[ ${#hint} -gt $content_w ]]; then
			hint="${hint:0:$(( content_w - 1 ))}~"
		fi
		local hint_pad=$(( content_w - ${#hint} ))
		local hint_spaces
		hint_spaces=$(printf '%*s' "$hint_pad" '')
		printf "${C_SEP}  |${C_RESET}  ${C_HINT}%s${hint_spaces}${C_RESET}  ${C_SEP}|${C_RESET}${EL}\n" \
			"$hint"
		printf "${C_SEP}  +%s+${C_RESET}${EL}\n" "$border_line"
		printf "${EL}\n"

		if [[ "$count" -eq 0 ]]; then
			printf "  ${C_EMPTY}(répertoire vide)${C_RESET}${EL}\n"
			tput ed
			return
		fi

		# ── Preview active ? ─────────────────────────────────────
		local preview_active=0
		local preview_dir=""
		if [[ "$count" -gt 0 && -d "${entries[$sel]}" ]]; then
			preview_active=1
			preview_dir="${entries[$sel]}"
		fi

		# ── Lignes gauche ─────────────────────────────────────────
		# Chaque entrée = 1 chaîne déjà formatée (avec codes ANSI)
		# On stocke la chaîne finale prête à printf %b
		local -a left_rendered=()
		local i name base label
		local end=$(( viewport_start + viewport_size ))
		[[ "$end" -gt "$count" ]] && end="$count"

		for (( i=viewport_start; i<end; i++ )); do
			name="${entries[$i]}"
			base="${name##*/}"

			if [[ -d "$name" ]]; then
				label="${base}/"
			else
				label="${base}"
			fi

			# Tronquer au besoin (longueur visuelle = longueur brute ici, pas d'ANSI dans label)
			if [[ ${#label} -gt $left_w ]]; then
				label="${label:0:$(( left_w - 1 ))}…"
			fi

			local pad=$(( left_w - ${#label} ))
			local spaces=""
			local s; for (( s=0; s<pad; s++ )); do spaces+=" "; done

			if [[ "$i" -eq "$sel" ]]; then
				# Highlight sur le texte uniquement, pas le padding
				left_rendered+=("${C_SEL}${label}${C_RESET}${spaces}")
			elif [[ -d "$name" ]]; then
				left_rendered+=("${C_DIR}${label}${C_RESET}${spaces}")
			else
				left_rendered+=("${C_FILE}${label}${C_RESET}${spaces}")
			fi
		done

		# ── Lignes droite (preview) ───────────────────────────────
		local -a right_lines=()
		if [[ "$preview_active" -eq 1 ]]; then
			local raw_preview
			while IFS= read -r -d $'\0' raw_preview; do
				right_lines+=("$raw_preview")
			done < <(_nav_preview_lines "$preview_dir" "$right_w" "$viewport_size")
		fi

		# ── Affichage côte à côte ─────────────────────────────────
		local n_left="${#left_rendered[@]}"
		local n_right="${#right_lines[@]}"
		# n_rows = max des deux, mais plafonné à viewport_size pour ne jamais déborder
		local n_rows=$(( n_left > n_right ? n_left : n_right ))
		[[ "$n_rows" -gt "$viewport_size" ]] && n_rows="$viewport_size"

		local r
		for (( r=0; r<n_rows; r++ )); do
			# Colonne gauche : "  " + left_w chars + " " = left_w+3 avant le |
			if [[ "$r" -lt "$n_left" ]]; then
				printf "  %b " "${left_rendered[$r]}"
			else
				printf "%$(( left_w + 3 ))s" ""
			fi

			# Séparateur | uniquement si la preview est active
			# ET qu'il y a du contenu à afficher dans l'une ou l'autre colonne
			if [[ "$preview_active" -eq 1 ]]; then
				printf "${C_PRE_SEP}|${C_RESET}"
				# Contenu droite — seulement s'il existe pour cette ligne
				if [[ "$r" -lt "$n_right" ]]; then
					printf "%b" "${right_lines[$r]}"
				fi
			fi

			printf "${EL}\n"
		done

		# ── Compteur scroll ───────────────────────────────────────
		if [[ "$count" -gt "$viewport_size" ]]; then
			printf "\n  ${C_SCROLL}[ %d / %d ]${C_RESET}${EL}\n" "$(( sel + 1 ))" "$count"
		fi

		# Nettoie tout résidu sous le curseur si le contenu précédent
		# était plus long (ex: on a quitté un dossier avec preview vers
		# un dossier vide, ou la fenêtre a été redimensionnée plus petite)
		tput ed
	}

	local -a entries
	local key esc_seq
	local viewport_start=0

	# ── Cache d'état : on ne redessine que si quelque chose a changé ──
	local cache_dir=""
	local cache_selected=-1
	local cache_viewport=-1
	local cache_cols=-1
	local cache_lines=-1
	local need_relist=1

	while true; do
		# Relire le dossier seulement si le dossier a changé
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

		# Redessiner seulement si l'état visible a changé
		if [[ "$current_dir"    != "$cache_dir"       ||
		      "$selected"       -ne "$cache_selected"  ||
		      "$viewport_start" -ne "$cache_viewport"  ||
		      "$term_cols_now"  -ne "$cache_cols"      ||
		      "$term_lines"     -ne "$cache_lines"     ]]; then

			_nav_draw "$current_dir" "$selected" "$count" \
				"$viewport_start" "$viewport_size" "${entries[@]}"

			cache_dir="$current_dir"
			cache_selected="$selected"
			cache_viewport="$viewport_start"
			cache_cols="$term_cols_now"
			cache_lines="$term_lines"
		fi

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
							local came_from="${current_dir##*/}"
							current_dir="$parent"
							selected=0
							viewport_start=0

							# On charge la liste du parent ici (nécessaire pour trouver
							# la position du dossier d'où on vient)
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
				need_relist=1
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
						cmd="python3 \"$target\""
					else
						cmd="\"$target\""
					fi
					tput rmcup
					tput cnorm
					printf "Exécuter : %s " "$cmd"
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
