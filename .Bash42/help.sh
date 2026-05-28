#!/bin/bash

# Colors
WHITEB='\033[1;37m'
CYAN='\033[0;36m'
CYANB='\033[1;36m'
RED='\033[0;31m'
WHITE='\033[0;37m'
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════════════════════════════════════╗"
echo -e "  ║                                ${WHITEB}[HELP 42]${CYAN}                                 ║"
echo "  ╚══════════════════════════════════════════════════════════════════════════╝"
echo "  ╔══════════════════════════════════════════════════════════════════════════╗"
echo "  ║                                                                          ║"

echo -e "  ║   ${WHITEB}[Editor & Compilation:]${CYAN}                                                ║"
echo "  ║                                                                          ║"

echo -e "  ║   ${CYANB} ccw :${WHITE} Compile with all moulinette flags${CYAN}                               ║"
echo -e "  ║   ${CYANB} ff  :${WHITE} Run the norminette ${CYAN}                                             ║"
echo -e "  ║   ${CYANB} v   :${WHITE} Open vim ${CYAN}                                                       ║"
echo -e "  ║   ${CYANB} vh  :${WHITE} Open vim with header 42 ${CYAN}                                        ║"
echo -e "  ║   ${CYANB} a   :${WHITE} Execute the a.out file${CYAN}                                          ║"
echo -e "  ║   ${CYANB} p   :${WHITE} Execute with python3${CYAN}                                            ║"
echo -e "  ║   ${CYANB} ffp :${WHITE} Check .py with mypy and flake8${CYAN}                                  ║"
echo "  ║                                                                          ║"
echo -e "  ║   ${WHITEB}[Git:]${CYAN}                                                                 ║"
echo "  ║                                                                          ║"
echo -e "  ║   ${CYANB} gg  :${WHITE} Add all the .c file of your directory and sub-directories ${CYAN}      ║"
echo -e "  ║         ${WHITE}     to git and open a commit message window ${CYAN}                    ║"
echo -e "  ║   ${CYANB} gu  :${WHITE} Add all modified files${CYAN}                                          ║"
echo -e "  ║   ${CYANB} gs  :${WHITE} Run git status${CYAN}                                                  ║"
echo -e "  ║   ${CYANB} gpom:${WHITE} Run git push on the main branch${CYAN}                                 ║"
echo -e "  ║   ${CYANB} gp  :${WHITE} Run git push on the actual branch${CYAN}                               ║"
echo -e "  ║   ${CYANB} gc  :${WHITE} Run git clone${CYAN}                                                   ║"
echo -e "  ║   ${CYANB} rv  :${WHITE} Checks multiple things to prepare for a review${CYAN}                  ║"
echo -e "  ║   ${CYANB} gcd :${WHITE} Git clone and go to the directory created${CYAN}                       ║"
echo -e "  ║   ${CYANB} gd  :${WHITE} Commit to your git repo and pushes it directly${CYAN}                  ║"
echo -e "  ║   ${CYANB} gre :${WHITE} Relink your local repo to a a new remote${CYAN}                        ║"
echo -e "  ║                                                                          ║"
echo -e "  ║   ${WHITEB}[Bash42:]${CYAN}                                                              ║"
echo "  ║                                                                          ║"
echo -e "  ║   ${CYANB} help42:${WHITE} Shows this help page${CYAN}                                          ║"
echo -e "  ║   ${CYANB} b42   :${WHITE} Update to the latest version${CYAN}                                  ║"
echo -e "  ║   ${CYANB} sl    :${WHITE} Same as ls but if you're not so good with your keyboard${CYAN}       ║"
echo "  ║                                                                          ║"
echo "  ╚══════════════════════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
