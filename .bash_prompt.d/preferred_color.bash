#!/usr/bin/env bash

if [[ -z "$PREFERRED_COLOR" ]]; then
	if type -t python >/dev/null 2>&1; then
		# determine the color based on the user and hostname
		export PREFERRED_COLOR
		PREFERRED_COLOR="$(python -c 'import binascii,getpass,socket;id="%s@%s" % (getpass.getuser(), socket.gethostname(),);hsh=binascii.crc32(id);idx=(hsh % (38-31)) + 31;print(idx)')"
	fi
fi
