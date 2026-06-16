### Bash42 ###

dir="$(dirname ${BASH_SOURCE[0]})"
. "${dir}/commands/git.sh"
. "${dir}/commands/python.sh"
. "${dir}/utils/welcome.sh"
. "${dir}/utils/help.sh"



## All commands below are used for this project, please do not touch them

b42()
{
    welcomebash42
	python ~/.Bash42/py_commands/b42.py
}


sl()
{
	qr https://github.com/SaikoroAsh/Bash42
	echo "It's always a good time to advertise :)"
	echo "Type better next time"
}
