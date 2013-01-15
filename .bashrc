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

## include all the prompt libraries ##
######################################
for prompt_lib in `ls ~/.bash_prompt.d`; do
	. ~/.bash_prompt.d/$prompt_lib
done

# set up the prompt itself
PS1="\[\e[33m\]"

# add the project ps1
PS1="${PS1}\$(project_ps1)"

# add git to the prompt
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWSTASHSTATE=true
# GIT_PS1_SHOWUPSTREAM="false"
GIT_PS1_SHOWUNTRACKEDFILES=true
PS1="${PS1}\[\e[91m\]\$(__git_ps1 ' (%s) ')"

# add svn to the prompt
# SVN_PS1_SHOWDIRTYSTATE=
# SVN_PS1_SHOWREVISION=
# PS1="${PS1}\[\e[91m\]\$(__svn_ps1 ' (%s) ')"

export PS1="${PS1}\[\e[33m\]\$ \[\e[m\]"

# Change the terminal title when switching directories #
########################################################
function project_set_title() {
	set_title $PROJECT_NAME
}
CHDIR_COMMAND="${CHDIR_COMMAND}project_set_title;"
