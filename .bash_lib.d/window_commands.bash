
# Makes a best effort to set the title for the current terminal container
#
# This could be a window, tab, etc.
#
# Arguments:
#  1 - the title to set
function set_title() {
    case $TERM in
    xterm*)
        echo -ne "\033]0;$1\a"
        ;;
    *)
        ;;
    esac
}
