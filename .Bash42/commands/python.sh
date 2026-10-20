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
