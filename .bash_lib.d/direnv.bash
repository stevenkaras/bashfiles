#!/usr/bin/env bash

# Loads environment variables from all the .env files from the PWD to the root
#
# Intended for use as a way to push environment variables into files that are scoped
# to a project. Note that if you overwrite a variable, it will not be unset.

function _direnv_load_envfile() {
	local envfile="$1"
	local key
	local value
	# read in key value pairs, ignoring comments

	while IFS="=" read -r key value; do
		case "$key" in
			"#*") ;;
			*) eval "export $key='$value'" ;;
		esac
	done < "$envfile"
}

function _direnv_unload_envfile() {
	local envfile="$1"
	local key
	local value
	# read in key value pairs, ignoring comments

	while IFS="=" read -r key value; do
		case "$key" in
			"#*") ;;
			*) [[ "${!key}" == "$value" ]] && eval "unset -v $key" ;;
		esac
	done < "$envfile"
}

function _direnv_do_with_envfiles() {
	local curdir="$1"
	shift
	local parentdir
	local -a files=()
	while :; do
		parentdir="$(dirname "$curdir")"
		if [[ -f "$curdir"/.env ]]; then
			files+=("$curdir"/.env)
		fi
		[[ "$parentdir" == "$curdir" ]] && break
		curdir="$parentdir"
	done
	local idx
	for (( idx=${#files[@]}-1 ; idx>=0 ; idx-- )) ; do
		"$@" "${files[idx]}"
	done
}

function _direnv_on_chdir() {
	_direnv_do_with_envfiles "$ONCHDIR_OLDPWD" _direnv_unload_envfile
	_direnv_do_with_envfiles "$PWD" _direnv_load_envfile
}

if [[ "$BASHFEATURE_DIRENV_ENABLED" == "true" && ! "$CHDIR_COMMAND" == *"_direnv_on_chdir"* ]]; then
	export CHDIR_COMMAND="_direnv_on_chdir${CHDIR_COMMAND:+;$CHDIR_COMMAND}"
	_direnv_on_chdir
fi
