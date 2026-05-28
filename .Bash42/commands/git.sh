### Git ###

alias gg="find . -name '*.c' -exec git add {} ';' && git commit"


alias gu="git add -u"


alias gs="git status"


alias gpom="git push origin main"


alias gp="git push"


alias gc="git clone"


rv()
{
	git status &>/dev/null
	if [[ $? != 0 ]]; then
		echo "This is not a git repository."
	else
		echo -n "Checking norme..."
		out=$(norminette . | grep Error! | cut -d':' -f 1 | xargs -I{} echo -e "\xe2\x9d\x8c Norminette failed on \e[1;31m"{}"\e[0m")
		echo -ne "\r                 \r"
		if [[ -n $out ]]; then
			echo "$out"
		else
			echo -e "\xe2\x9c\x85 Norminette OK."
		fi
		out=$(find . -type f -not -path '*/.git*' -not -name '*.h' -not -name '*.c' -exec echo -e '\xe2\x9a\xa0\xef\xb8\x8f  Found a file that is not .c or .h: \e[1;31m'{}'\e[0m' \;)
		if [[ -n $out ]]; then
			echo "$out"
		else
			echo -e "\xe2\x9c\x85 No files other than .c and .h"
		fi
		out=$(git ls-files . --exclude-standard --others --modified | xargs -I{} echo -e "\xe2\x9a\xa0\xef\xb8\x8f  File is not committed: \e[1;31m"{}"\e[0m")
		if [[ -n $out ]]; then
			echo -e "$out"
		else
			echo -e "\xe2\x9c\x85 All files already committed. Be sure to check on github.com if you have pushed on the correct repo."
		fi
		echo "Current repository is located at https://github.com/"$(git config --get remote.origin.url | cut -d: -f 2)
	fi
}


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
