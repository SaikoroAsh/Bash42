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
        "CIDR" "Mask" "Hex" "Wildcard" "Hosts" 10 ""
    _nl_sep
    local c m_int wc_int hosts
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
        "CIDR" "Mask" "Hex" "Wildcard" "Hosts" 10 ""
    _nl_sep
    local c m_int wc_int hosts
    for c in $(seq 1 32); do
        m_int=$(_nl_cidr_to_maskint "$c")
        wc_int=$(( (~m_int) & 0xFFFFFFFF ))
        if (( c >= 31 )); then hosts=$(( c==32 ? 1 : 2 )); else hosts=$(( (1<<(32-c))-2 )); fi
        printf "${_nl_cyan}|${_nl_reset} %-6s %-17s %-12s %-16s %-14s%*s${_nl_cyan}|${_nl_reset}\n" \
            "/$c" "$(_nl_int_to_ip "$m_int")" "$(_nl_int_to_hex "$m_int" | sed 's/0x//')" \
            "$(_nl_int_to_ip "$wc_int")" "$hosts" 10 ""
    done
    _nl_bot
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
        "CIDR" "Mask" "Hex" "Wildcard" "Hosts" 10 ""
    _nl_sep
    local c m_int wc_int hosts
    for c in $(seq 1 32); do
        m_int=$(_nl_cidr_to_maskint "$c")
        wc_int=$(( (~m_int) & 0xFFFFFFFF ))
        if (( c >= 31 )); then hosts=$(( c==32 ? 1 : 2 )); else hosts=$(( (1<<(32-c))-2 )); fi
        printf "${_nl_cyan}|${_nl_reset} %-6s %-17s %-12s %-16s %-14s%*s${_nl_cyan}|${_nl_reset}\n" \
            "/$c" "$(_nl_int_to_ip "$m_int")" "$(_nl_int_to_hex "$m_int" | sed 's/0x//')" \
            "$(_nl_int_to_ip "$wc_int")" "$hosts" 10 ""
    done
    _nl_bot
}

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
        "CIDR" "Mask" "Hex" "Wildcard" "Hosts" 10 ""
    _nl_sep
    local c m_int wc_int hosts
    for c in $(seq 1 32); do
        m_int=$(_nl_cidr_to_maskint "$c")
        wc_int=$(( (~m_int) & 0xFFFFFFFF ))
        if (( c >= 31 )); then hosts=$(( c==32 ? 1 : 2 )); else hosts=$(( (1<<(32-c))-2 )); fi
        printf "${_nl_cyan}|${_nl_reset} %-6s %-17s %-12s %-16s %-14s%*s${_nl_cyan}|${_nl_reset}\n" \
            "/$c" "$(_nl_int_to_ip "$m_int")" "$(_nl_int_to_hex "$m_int" | sed 's/0x//')" \
            "$(_nl_int_to_ip "$wc_int")" "$hosts" 10 ""
    done
    _nl_bot
}

    for c in $(seq 1 32); do
        m_int=$(_nl_cidr_to_maskint "$c")
        wc_int=$(( (~m_int) & 0xFFFFFFFF ))
        if (( c >= 31 )); then hosts=$(( c==32 ? 1 : 2 )); else hosts=$(( (1<<(32-c))-2 )); fi
        printf "${_nl_cyan}|${_nl_reset} %-6s %-17s %-12s %-16s %-14s%*s${_nl_cyan}|${_nl_reset}\n" \
            "/$c" "$(_nl_int_to_ip "$m_int")" "$(_nl_int_to_hex "$m_int" | sed 's/0x//')" \
            "$(_nl_int_to_ip "$wc_int")" "$hosts" 10 ""
    done
    _nl_bot
}

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
        "CIDR" "Mask" "Hex" "Wildcard" "Hosts" 10 ""
    _nl_sep
    local c m_int wc_int hosts
    for c in $(seq 1 32); do
        m_int=$(_nl_cidr_to_maskint "$c")
        wc_int=$(( (~m_int) & 0xFFFFFFFF ))
        if (( c >= 31 )); then hosts=$(( c==32 ? 1 : 2 )); else hosts=$(( (1<<(32-c))-2 )); fi
        printf "${_nl_cyan}|${_nl_reset} %-6s %-17s %-12s %-16s %-14s%*s${_nl_cyan}|${_nl_reset}\n" \
            "/$c" "$(_nl_int_to_ip "$m_int")" "$(_nl_int_to_hex "$m_int" | sed 's/0x//')" \
            "$(_nl_int_to_ip "$wc_int")" "$hosts" 10 ""
    done
    _nl_bot
}
