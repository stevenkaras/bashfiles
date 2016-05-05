# show the user and hostname if we're running on a remote server

# conditionally show the hostname if we're running in an ssh connection

function __remote_host() {
	local show_host=""
	# if we're running on ssh, we want to show the hostname
	if [[ -n "$SSH_CLIENT" ]]; then
		show_host="yes"
	fi

	# check if we're running ubuntu-server, if so, always show the host
	if [ type dpkg >/dev/null 2>&1 ]; then
		if [ dpkg -s ubuntu-desktop >/dev/null 2>&1 ]; then
			show_host="yes"
		fi
	fi

	if [[ -n "$PREFERRED_COLOR" ]]; then
		echo "\[\e[${PREFERRED_COLOR}m\]"
	elif [ type python >/dev/null 2>&1 ]; then
		# determine the color based on the user and hostname
		python -c 'import binascii,getpass,socket;id="%s@%s" % (getpass.getuser(), socket.gethostname(),);hsh=binascii.crc32(id);idx=(hsh % (38-31)) + 31;print("\\[\\e[%sm\\]" % (idx,))'
	else
		echo "\[\e[33m\]"
	fi

	if [[ -n "$show_host" ]]; then
		echo "$USER@$HOSTNAME "
	fi
}
