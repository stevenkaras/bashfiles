#!/usr/bin/env bash

function init_manager() {
	# setup a basic framework in the current directory
	mkdir -p authorized_keys
	cat <<-AUTHORIZED_KEYS >>authorized_keys/base
		# This file follows the standard sshd(8) authorized_keys format
	AUTHORIZED_KEYS
	if [[ -f "$HOME/.ssh/ca/ca.pub" ]]; then
		{ echo -n "cert-authority "; cat "$HOME/.ssh/ca/ca.pub"; } >> authorized_keys/base
	elif [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
		cat < "$HOME/.ssh/id_rsa.pub" >> authorized_keys/base
	fi

	mkdir -p config
	cat <<-SSHCONFIG >>config/base
		# This file follows the standard ssh_config(5) config format

		IdentityFile ~/.ssh/id_rsa
		IdentitiesOnly yes
		ServerAliveInterval 30
		UseRoaming no
		# Disable client side roaming, as per http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-0777 and http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2016-0778
	SSHCONFIG
}

function enumerate_servers() {
    find "$PWD"/"$1" -name '*@*' -exec basename {} \;
}

function distribute() {
	case "$1" in
	-s|--seq|--sequential)
		shift
		local do_with="xargs -I {}"
		;;
	*)
		local do_with="parallel -j0"
		;;
	esac

	if [[ $# -eq 1 ]]; then
		enumerate_servers "$1" | $do_with "$0" "push_$1" {}
	else
		echo "$@" | $do_with "$0" "push_$1" {}
	fi
}

function push_all() {
	# push out the managed configurations/authorized keys
	distribute "$@" authorized_keys
	distribute "$@" config
}

function compile_file() {
	local TMPFILE
	TMPFILE="$(mktemp)"
	local source_file="$1"
	pushd "$(dirname "$source_file")" >/dev/null 2>&1
	m4 <"$(basename "$source_file")" >"$TMPFILE"
	popd >/dev/null 2>&1
	echo "$TMPFILE"
}

function push_config() {
	local compiled_config
	compiled_config="$(compile_file "$PWD/config/$1")"
	if [[ "${1##*@}" == "localhost" && "${1%@*}" == "$USER" ]]; then
		cp "$compiled_config" "$HOME/.ssh/config"
	else
		scp "$compiled_config" "$1:.ssh/config"
	fi
	rm "$compiled_config"
}

function push_authorized_keys() {
	local compiled_authorized_keys
	compiled_authorized_keys="$(compile_file "$PWD/authorized_keys/$1")"
	if [[ "${1##*@}" == "localhost" && "${1%@*}" == "$USER" ]]; then
		cp "$compiled_authorized_keys" "$HOME/.ssh/authorized_keys"
	else
		scp "$compiled_authorized_keys" "$1:.ssh/authorized_keys"
	fi
	rm "$compiled_authorized_keys"
}

function show_usage() {
	local prog
	prog="$(basename "$0")"
	cat <<-HELPMESSAGE
		  $prog init                         # setup a managed set of servers
		  $prog push                         # push the configuration and authorized keys to all configured servers
		  $prog push_config SERVER           # push the ssh_config to the given server
		  $prog push_authorized_keys SERVER  # push the authorized_keys to the given server
	HELPMESSAGE
	if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
		cat <<-VERBOSEHELP

			SSH can be a pain to configure for multiple servers. This script makes the process of managing the authorized keys and client configuration much easier.

			The configuration files are placed as authorized_keys/user@host and config/user@host.

			Files are processed using m4, such that common sections can be shared using include(other_file) directives.
		VERBOSEHELP
	fi
}

function main() {
	local subcommand="$1"
	shift
	case "$subcommand" in
		setup|init)
			init_manager "$@"
			exit $?
			;;
		push)
			push_all "$@"
			exit $?
			;;
		push_config)
			push_config "$@"
			exit $?
			;;
		push_authorized_keys)
			push_authorized_keys "$@"
			exit $?
			;;
		-\?|-h|--help|help|"")
			show_usage "$@"
			exit $?
			;;
		*)
			echo "Unknown command: $subcommand"
			echo ""
			show_usage
			exit 2
			;;
	esac
}

main "$@"
