### C ###

alias a="./a.out"


alias ccw="cc -Wall -Werror -Wextra"


alias ff="norminette"



### Vim ###

alias v="vim"


alias vh="vim +Stdheader"


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
		# Turn git@host:user/repo.git, ssh://git@host/user/repo or https://host/user/repo.git into a web link
		local url=$(git config --get remote.origin.url)
		url=${url%.git}
		case $url in
			git@*:*) url=${url#git@}; url="https://${url/://}" ;;
			ssh://*) url=${url#ssh://}; url="https://${url#*@}" ;;
			https://*@*) url="https://${url#*@}" ;;
		esac
		echo "Current repository is located at $url"
	fi
}
