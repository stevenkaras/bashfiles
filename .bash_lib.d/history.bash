
## set up the bash history ##
#############################
# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignorespace

# append to the history file, don't overwrite it
shopt -s histappend
shopt -s cmdhist

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=
HISTFILESIZE=
HISTTIMEFORMAT="[%F %T] "
if [[ ! -d "$HOME/.bash_history.d" ]]; then
    mkdir "$HOME/.bash_history.d"
fi
HISTFILE="$HOME/.bash_history.d/$USER@$HOSTNAME.history"
HISTIGNORE="ll:ls:bg:fg:pwd:date"

if [[ ! "$PROMPT_COMMAND" == *"history -a"* ]]; then
	PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }history -a; history -c; history -r"
fi
