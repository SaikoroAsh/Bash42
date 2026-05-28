### Bash42 ###

. ~/.Bash42/commands/git.sh
. ~/.Bash42/commands/python.sh
. ~/.Bash42/utils/welcome.sh
. ~/.Bash42/utils/help.sh



## All commands below are used for this project, please do not touch them

b42()
{
    welcomebash42
	wget -q https://raw.githubusercontent.com/SaikoroAsh/Bash42/refs/heads/main/.bash42 -O ~/.bash42.tmp
	if [[ $? == 0 ]]; then
		dif=$(diff ~/.bash42 ~/.bash42.tmp | grep -B 1 '^> alias\|^> \S*(' | grep "^> #" | cut -c5- | sed -E 's/^(\S*):(.*)/New command: '$(echo -e '\033[1;31m')'\1'$(echo -e '\033[0m')':\2/')
		if [[ -n $dif ]]; then
			echo $dif
		else
			echo -e '\033[32mBash42 is already up to date\033[0m'
		fi
		mv ~/.bash42.tmp ~/.bash42 && source ~/.bash42
	fi
}


sl()
{
	qr https://github.com/SaikoroAsh/Bash42
	echo "It's always a good time to advertise :)"
	echo "Type better next time"
}
