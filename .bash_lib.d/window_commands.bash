
# Makes a best effort to set the title for the current terminal container
#
# This could be a window, tab, etc.
#
# Arguments:
#  1 - the title to set
function set_title() {
	case $TERM in
	screen*|tmux*)
		printf "\033k%s\033\\" "$1"
		;;
	xterm*)
		printf "\033]0;%s\a" "$1"
		;;
	*)
		;;
	esac
}
