# show the user and hostname if we're running on a remote server

# conditionally show the hostname if we're running in an ssh connection

function __remote_host() {
	local show_host=""

	if is_remote; then
		echo "$USER@$HOSTNAME "
	fi
}
