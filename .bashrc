# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# Alias definitions
if [ -f ~/.bash_aliases ]; then
	. ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
set completion-ignore-case on

## include the bash standard library ##
#######################################
if [ -f ~/bash_standard_library.bash ]; then
	. ~/bash_standard_library
fi

## set up bash completion ##
############################
for prog in `ls ~/.bash_completion.d`; do
	. ~/.bash_completion.d/$prog
done

if [ -f ~/.bash_prompt ]; then
    . ~/.bash_prompt
fi
