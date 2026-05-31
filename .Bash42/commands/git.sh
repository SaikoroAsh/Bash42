### Git ###

gce()
{
        if [[ $# == 0 ]]; then
                echo -e '\033[31mPlease specify a file extension like "c" "py"...\033[0m'
        else
                for arg in "$@"
                do
                        find . -name "*.$arg" -exec git add {} +
                done
                git commit
        fi
}


alias gu="git add -u"


alias gs="git status"


alias gpom="git push origin main"


alias gp="git push"


alias gc="git clone"

alias fdata='du -h /home/$USER | sort -hr | head -20'

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
