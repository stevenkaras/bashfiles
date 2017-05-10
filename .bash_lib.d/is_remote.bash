
function _current_tty() {
	# tmux confounds this, since it's a multiplexer. We need to find the client tty with the latest activity
	if [[ -n "$TMUX" ]]; then
		tmux list-clients -F '#{client_activity}:#{client_tty}' | sort -n | tail -n 1 | cut -d ':' -f 2
		return 0
	fi

	tty
	return 0
}

function _is_tty_remote() {
	# check if the given tty is connected to a remote user
	local tty_name="${1##/dev/}"
	local from="$(w -h | tr -s ' ' | cut -d' ' -f2-3 | grep -e "^$tty_name" | cut -d' ' -f 2)"
	if [[ -z "$from" ]]; then
		# attempt to search for suffixes
		local extra_chomped="${tty_name##tty}"
		if [[ "$extra_chomped" != "$tty_name" ]]; then
			_is_tty_remote "$extra_chomped"
			local returnval=$?
			return $returnval
		fi
		# this can happen if we've su'd inside tmux, so just assume it's remote
		return 0
	elif [[ "$from" =~ :[[:digit:]]* ]]; then
		return 1
	elif [[ "$from" == "-" ]]; then
		return 1
	else
		return 0
	fi
}

function _proot() {
	# Based on a recursive version that depends on procfs I found on StackOverflow
	local pid="$$"
	local curpid=""
	local name=""

	while [[ "$pid" -ge 1 ]]; do
		read -r curpid pid name < <(ps -o pid= -o ppid= -o comm=  -p "$pid")
		if [[ "$name" == "${1:-sshd}"* ]]; then
			return 0
		fi
	done

	exit 1
}

# check if the current BASH session is a "remote" session
function is_remote() {
	# check if we're running ubuntu-server, if so, always consider it to be "remote"
	if type -t dpkg >/dev/null 2>&1; then
		if ! dpkg -s ubuntu-desktop >/dev/null 2>&1; then
			return 0
		fi
	fi

	# determine if the tty is associated with a remote connection
	local tty="$(_current_tty)"
	if _is_tty_remote "$tty"; then
		return 0
	fi

	return 1
}
