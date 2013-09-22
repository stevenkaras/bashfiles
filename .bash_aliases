#!/bin/bash

## directory aliases ##
#######################

# directory traversal
alias up='cd ..'

# directory listing
alias ll='ls -AhlF'
alias la='ls -AF'
alias l='ls -CF'

alias fucking='sudo'
alias va='vi ~/.bash_aliases'
alias sa='. ~/.bash_aliases'

## version control ##
#####################

# some git aliases
alias gitk='gitk 2>/dev/null &'
alias gitgui='git gui &'
function loc() {
    echo "   lines   words   chars filename"
    wc `find . -type f -name $1 | tr '\n' ' '`
}
function gitstat() {
	git log --author=$1 --pretty=tformat: --numstat | awk '{ adds += $1; subs += $2; loc += $1 - $2 } END { printf "added: %s removed: %s total: %s\n",adds,subs,loc }' -
}

