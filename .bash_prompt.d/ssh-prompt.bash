# conditionally show the hostname if we're running in an ssh connection

function __ssh_host() {
	if [[ -n "$SSH_CLIENT" ]]; then
		echo "$USER@$HOSTNAME "
	fi
}
