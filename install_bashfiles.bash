#!/usr/bin/env bash

# TODO: automatically gitclone my bashfiles if this script is being piped into bash

function _platform() {
	local kernel="$(uname -s)"
	case "$kernel" in
		Linux)
			echo "ubuntu"
			;;
		Darwin)
			echo "macos"
			;;
	esac
}

function do_install() {
	# determine the folder this script is in
	local ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	for bashfile in "$ROOTDIR"/.bash*; do
		ln -s "$bashfile" "~/$(basename "$bashfile")"
	done
	local platform=$(_platform)
	# inject the bashfiles
	cat <<-BASH > $HOME/.bashrc
		if [ -f "$HOME/.bashrc_$platform" ]; then
		    . "$HOME/.bashrc_$platform"
		fi

		if [ -f "$HOME/.bashlib" ]; then
		    . "$HOME/.bashlib"
		fi
	BASH

	# Setup binary links
	mkdir -p ~/bin
	for binary in "$ROOTDIR"/bin/*; do
		ln -s "$binary" "~/bin/$(basename "$binary")"
	done
	for ssh_binary in "$ROOTDIR"/.ssh/*.bash; do
		ln -s "$ssh_binary" "~/bin/$(basename "${ssh_binary%%.bash}")"
	done
}

do_install "$@"
