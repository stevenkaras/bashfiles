#!/usr/bin/env bash

function _platform() {
	local kernel
	kernel="$(uname -s)"
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
	local ROOTDIR
	ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	local IPYTHON_PROFILE_DIR
	IPYTHON_PROFILE_DIR="$(ipython locate profile)"
	# shellcheck disable=SC2181
	if [[ $? != 0 ]]; then
		return
	fi

	for ipython_config_file in "$ROOTDIR/.ipython/"*; do
		ln -s -n "$ipython_config_file" "$IPYTHON_PROFILE_DIR/$(basename "$ipython_config_file")" 2>/dev/null
	done
}

function do_tmux_install() {
	# determine the folder this script is in
	local ROOTDIR
	ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	# discover the tmux version
	local tmux_version_string
	tmux_version_string="$(tmux -V)"
	local tmux_version_config
	case "$tmux_version_string" in
		"tmux 1.8")
			# 1.8 is the version packaged for Ubuntu 14.04
			tmux_version_config="$ROOTDIR/.config/tmux/tmux.conf.1.8"
			;;
		"tmux 2.1")
			# 2.1 is the version packaged for Ubuntu 16.04
			tmux_version_config="$ROOTDIR/.config/tmux/tmux.conf.2.1"
			;;
		"tmux 2.6")
			# 2.6 is the version packaged for Ubuntu 18.04
			tmux_version_config="$ROOTDIR/.config/tmux/tmux.conf.2.6"
			;;
		*)
			tmux_version_config="$ROOTDIR/.config/tmux/tmux.conf.modern"
			;;
	esac

	# we may want to overwrite the symlink if it points to one of our files, but the version of tmux has changed
	local tmux_config="$HOME/.tmux.conf"
	if [[ -h "$tmux_config" ]]; then
		local symlink_target
		symlink_target="$(readlink -n "$file")"
		[[ "$symlink_target" = "$ROOTDIR"/* ]] && rm "$tmux_config"
	fi
	ln -s -n "$tmux_version_config" "$tmux_config" 2>/dev/null
}

function remove_broken_symlinks() {
	local ROOTDIR
	ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	local target="$1"

	shopt -s dotglob
	for file in "$target/"*; do
		if [[ -h "$file" && ! -e "$file" ]]; then
			local symlink_target
			symlink_target="$(readlink -n "$file")"
			[[ "$symlink_target" = "$ROOTDIR"/* ]] && rm "$file"
		fi
	done
}

function do_install() {
	# if we're being piped into bash, then clone
	if [[ ! -t 0 && "$0" == "bash" && -z "${BASH_SOURCE[0]}" ]]; then
		if [[ -e "$HOME/bashfiles" ]]; then
			echo "$HOME/bashfiles already exists. Perhaps you meant to run $HOME/bashfiles/install_bashfiles.bash?"
			return 1
		fi
		git clone https://github.com/stevenkaras/bashfiles.git "$HOME/bashfiles" && return $?
		"$HOME"/bashfiles/install_bashfiles.bash
		return $?
	fi

	# determine the folder this script is in
	local ROOTDIR
	ROOTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	remove_broken_symlinks "$HOME"
	for bashfile in "$ROOTDIR"/.bash*; do
		local bashfilename
		bashfilename="$(basename "$bashfile")"
		# don't accidentally create recursive symlinks
		if [[ ! -h "$bashfile" ]]; then
			ln -s -n "$bashfile" "$HOME/$bashfilename" 2>/dev/null
		fi
	done
	local platform
	platform=$(_platform)
	# inject the bashfiles
	if ! grep -E "$HOME/.bashrc" -e "(\\.|source)\\s+('|\")?($HOME|\\\$HOME)/.bashlib" >/dev/null; then
		cat <<-BASH >> "$HOME/.bashrc"
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
	for ssh_binary in "$ROOTDIR"/ssh/*.bash; do
		ln -s -n "$ssh_binary" "$HOME/bin/$(basename "${ssh_binary%%.bash}")" 2>/dev/null
	done

	# other files to symlink
	for otherfile in .agignore .tmux_profile .vim .irbrc .psqlrc .lessfilter .inputrc; do
		ln -s -n "$ROOTDIR/$otherfile" "$HOME/$otherfile" 2>/dev/null
	done

	# ipython config installation
	if type -t ipython >/dev/null; then
		do_ipython_install
	fi

	# Migrate over some stuff to XDG style
	[[ -z "$XDG_CONFIG_HOME" ]] && export XDG_CONFIG_HOME="$HOME/.config"

	# git: To be removed no earlier than 20190601
	mkdir -p "$XDG_CONFIG_HOME/git"
	[[ -e "$HOME/.gitconfig" ]] && mv "$HOME/.gitconfig" "$XDG_CONFIG_HOME/git/config"
	# shellcheck disable=SC2088
	[[ ! -e "$HOME/.gitignore_global" && "$(git config --global core.excludesfile)" == "~/.gitignore_global" ]] && git config --global --unset core.excludesfile

	# symlink XDG configs
	mkdir -p "$XDG_CONFIG_HOME/git"
	remove_broken_symlinks "$XDG_CONFIG_HOME/git"
	ln -s -n "$ROOTDIR/.config/git/attributes" "$XDG_CONFIG_HOME/git/attributes" 2>/dev/null
	ln -s -n "$ROOTDIR/.config/git/ignore" "$XDG_CONFIG_HOME/git/ignore" 2>/dev/null

	# copy over templates
	[[ ! -e "$HOME/.bash_features" ]] && cp "$ROOTDIR/templates/.bash_features" "$HOME/.bash_features"
	ln -s -n "$HOME/.bash_features" "$ROOTDIR/.bash_features" 2>/dev/null # convenience symlink
	[[ ! -e "$XDG_CONFIG_HOME/git/config" ]] && cp "$ROOTDIR/templates/.config/git/config" "$XDG_CONFIG_HOME/git/config"
	ln -s -n "$XDG_CONFIG_HOME/git/config" "$ROOTDIR/.config/git/config" 2>/dev/null # convenience symlink

	# link the tmux configuration
	if type -t tmux >/dev/null; then
		do_tmux_install
	fi

	# symlink the local profile files into the repo for convenience
	[[ -f "$HOME/.profile" ]] && ln -s -n "$HOME/.profile" "$ROOTDIR/.profile" 2>/dev/null
	[[ -f "$HOME/.bash_profile" ]] && ln -s -n "$HOME/.bash_profile" "$ROOTDIR/.bash_profile" 2>/dev/null
	[[ -f "$HOME/.bashrc" ]] && ln -s -n "$HOME/.bashrc" "$ROOTDIR/.bashrc" 2>/dev/null
	[[ -f "$HOME/.bash_features" ]] && ln -s -n "$HOME/.bash_features" "$ROOTDIR/.bash_features" 2>/dev/null

	return 0
}

do_install "$@"
