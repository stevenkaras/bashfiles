
# check if the current BASH session is a "remote" session
function is_remote() {
	# if we're running on ssh, it's remote
	if [[ -n "$SSH_CLIENT" ]]; then
		return 0
	fi

	# check if we're running ubuntu-server, if so, always consider it to be "remote"
	if type -t dpkg >/dev/null 2>&1; then
		if ! dpkg -s ubuntu-desktop >/dev/null 2>&1; then
			return 0
		fi
	fi

	return 1
}
