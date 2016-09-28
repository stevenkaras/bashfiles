#!/usr/bin/env bash

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

function do_ipython_install() {
	# determine the folder this script is in
	local ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	local IPYTHON_PROFILE_DIR="$(ipython locate profile)"
	if [[ $? != 0 ]]; then
		return
	fi

	for ipython_config_file in "$ROOTDIR/.ipython/"*; do
		ln -s -n "$ipython_config_file" "$IPYTHON_PROFILE_DIR/$(basename "$ipython_config_file")" 2>/dev/null
	done
}

function remove_broken_symlinks() {
  local ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  local target="$1"

  for file in "$target/"*; do
    if [[ -h "$file" && ! -e "$file" ]]; then
      local symlink_target="$(readlink -n "$file")"
      [[ "$symlink_target" = "$ROOTDIR"/* ]] && rm "$file"
    fi
  done
}

function do_install() {
	# if we're being piped into bash, then clone
	if [[ ! -t 0 && "$0" == "bash" && -z "$BASH_SOURCE" ]]; then
		if [[ -e "$HOME/bashfiles" ]]; then
			echo "$HOME/bashfiles already exists. Perhaps you meant to run $HOME/bashfiles/install_bashfiles.bash?"
			return 1
		fi
		git clone https://github.com/stevenkaras/bashfiles.git "$HOME/bashfiles"
		[[ $? != 0 ]] && return $?
		~/bashfiles/install_bashfiles.bash
		return $?
	fi

	# determine the folder this script is in
	local ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	remove_broken_symlinks "$HOME"
	for bashfile in "$ROOTDIR"/.bash*; do
		ln -s -n "$bashfile" "$HOME/$(basename "$bashfile")" 2>/dev/null
	done
	local platform=$(_platform)
	# inject the bashfiles
	if ! egrep ~/.bashrc -e "(\.|source)\s+('|\")?($HOME|\\\$HOME)/.bashlib" >/dev/null; then
		cat <<-BASH >> $HOME/.bashrc
			if [[ -f "\$HOME/.bashrc_$platform" ]]; then
			    . "\$HOME/.bashrc_$platform"
			fi

			if [[ -f "\$HOME/.bashlib" ]]; then
			    . "\$HOME/.bashlib"
			fi
			
		BASH
	fi

	# warn about problematic history declarations in .bashrc, /etc/bash.bashrc, etc
	for bashfile in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bashrc" "/etc/bash.bashrc" "/etc/bashrc"; do
		if [[ -f "$bashfile" ]]; then
			if grep -e '^[^#]*HISTSIZE=[0-9]' "$bashfile"; then
				echo "WARNING: $bashfile sets HISTSIZE. This is known to truncate history files even though we set it to unlimited"
			fi
		fi
	done

	# Setup binary links
	mkdir -p "$HOME/bin"
	remove_broken_symlinks "$HOME/bin"
	for binary in "$ROOTDIR"/bin/*; do
		ln -s -n "$binary" "$HOME/bin/$(basename "$binary")" 2>/dev/null
	done
	for ssh_binary in "$ROOTDIR"/.ssh/*.bash; do
		ln -s -n "$ssh_binary" "$HOME/bin/$(basename "${ssh_binary%%.bash}")" 2>/dev/null
	done

	# other files to symlink
	for otherfile in .tmux.conf .gitignore_global .vim .irbrc .psqlrc .lessfilter .inputrc; do
		ln -s -n "$ROOTDIR/$otherfile" "$HOME/$otherfile" 2>/dev/null
	done

	# ipython config installation
	if type -t ipython >/dev/null; then
		do_ipython_install
	fi

	# copy the gitconfig in as a file, not symlinked (because it is expected to change)
	[[ ! -e "$HOME/.gitconfig" ]] && cp "$ROOTDIR/.gitconfig" "$HOME/.gitconfig"
	return 0
}

do_install "$@"
