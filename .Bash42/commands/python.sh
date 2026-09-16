### Python ###

alias p="python3"


alias ffp='flake8 --max-line-length=79; mypy .'


alias off="deactivate"


on(){
	source "${1:-venv}/bin/activate"
}

cve(){
	python3 -m venv "${1:-venv}"
}

# Remove Python caches: __pycache__ and .mypy_cache
pcc(){
	# Usage: pcc [--dry-run|-n] [path]
	local dry=0
	local path="."
	if [ "${1:-}" = "-n" ] || [ "${1:-}" = "--dry-run" ]; then
		dry=1
		shift
	fi
	if [ -n "${1:-}" ]; then
		path="$1"
	fi
	if [ "$dry" -eq 1 ]; then
		find "$path" -type d \( -name "__pycache__" -o -name ".mypy_cache" \) -print
		return
	fi
	find "$path" -type d \( -name "__pycache__" -o -name ".mypy_cache" \) -print0 | xargs -0 -r rm -rf --
	echo "Removed Python cache directories under: $path"
}
