
# Execute the passed command inside a critical section
function bashlock() {
	if [[ "$#" -eq 0 ]]; then
		echo 'usage: bashlock LOCKNAME COMMAND...' 1>&2
		return 2
	fi
	local LOCKFILE="$1"
	shift

	bashlock_acquire "$LOCKFILE"

	# execute the command
	"$@"
	local exit_status="$?"

	bashlock_release "$LOCKFILE"

	return "$exit_status"
}

function bashlock_acquire() {
	local LOCKFILE="$1"

	echo "$$" >"$LOCKFILE.$$"
	while ! ln "$LOCKFILE.$$" "$LOCKFILE" 2>/dev/null; do
		if [[ ! -s "$LOCKFILE" ]]; then
			rm -f "$LOCKFILE"
		else
			local PID="$(head -1 "$LOCKFILE")"
			if kill -0 "$PID" 2>/dev/null; then
				# sleep 100ms between locking attempts
				sleep 0.1
			else
				rm -f "$LOCKFILE"
			fi
		fi
	done
}

function bashlock_release() {
	local LOCKFILE="$1"

	rm -f "$LOCKFILE"
	rm -f "$LOCKFILE.$$"
}
