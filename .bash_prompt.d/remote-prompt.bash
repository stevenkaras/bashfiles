# show the user and hostname if we're running on a remote server

# conditionally show the hostname if we're running in an ssh connection

function __remote_host() {
	local show_host=""
	# if we're running on ssh, we want to show the hostname
	if [[ -n "$SSH_CLIENT" ]]; then
		show_host="yes"
	fi

	# check if we're running ubuntu-server, if so, always show the host
	if type -t dpkg >/dev/null 2>&1; then
		if dpkg -s ubuntu-desktop >/dev/null 2>&1; then
			show_host="yes"
		fi
	fi

	if [[ -n "$show_host" ]]; then
		echo "$USER@$HOSTNAME "
	fi
}
