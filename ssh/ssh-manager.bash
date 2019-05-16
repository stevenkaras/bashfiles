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
	local action="$1"
	shift

	case "$1" in
	-s|--seq|--sequential)
		shift
		local do_with="xargs -I {}"
		;;
	*)
		local do_with="parallel --no-notice -j0"
		;;
	esac

	if [[ $# -eq 0 ]]; then
		enumerate_servers "$action" | $do_with "$0" "push_$action" {}
	else
		echo "$@" | $do_with "$0" "push_$action" {}
	fi
}

function push_all() {
	# push out the managed configurations/authorized keys
	distribute authorized_keys "$@"
	distribute config "$@"
}

function compile_file() {
	local source_file="$1"
	[[ ! -f "$source_file" ]] && return 1

	local TMPFILE
	TMPFILE="$(mktemp)"
	pushd "$(dirname "$source_file")" >/dev/null 2>&1
	m4 <"$(basename "$source_file")" >"$TMPFILE"
	popd >/dev/null 2>&1
	echo "$TMPFILE"
	return 0
}

function push_config() {
	local compiled_config
	compiled_config="$(compile_file "$PWD/config/$1")"
	# shellcheck disable=SC2181
	[[ $? -ne 0 ]] && return $?
	# echo "about to push config to $1"

	if [[ "${1##*@}" == "localhost" && "${1%@*}" == "$USER" ]]; then
		cp "$compiled_config" "$HOME/.ssh/config"
	else
		scp -o ClearAllForwardings=yes "$compiled_config" "$1:.ssh/config"
	fi
	rm "$compiled_config"
}

function _check_authorization() {
	local authorized_keys_file="$1"
	local target="$2"

	local identity_file
	identity_file="$(ssh -G "$target" -T | grep -o -P -e '(?<=^identityfile ).*$')"
	# ssh will try to offer up all identity files in ~/.ssh, so check those in addition to the configured one
	for candidate_identity in "${identity_file}" ~/.ssh/*.pub; do
		if [[ "$candidate_identity" = *.pub ]]; then
			candidate_identity="${candidate_identity%.pub}"
		fi
		if [[ -f "$candidate_identity.pub" ]]; then
			# echo "checking validity of $candidate_identity.pub"
			local public_key
			public_key="$(cut -d' ' -f2 "$candidate_identity.pub")"
			# echo "searching for $public_key"
			# grep -v -P -e '^\s*#' "$authorized_keys_file" | grep -o -P -e 'ssh-\S+ \S+'
			grep -v -P -e '^\s*#' "$authorized_keys_file" | grep -o -P -e 'ssh-\S+ \S+' | grep -F -e "$public_key" -q && return 0
		fi
		if [[ -f "$candidate_identity-cert.pub" ]]; then
			# due to a limitation in ssh-keygen, we can only check the fingerprint, not the full key
			# echo "checking validity of $candidate_identity-cert.pub"
			local ca_fingerprint
			ca_fingerprint="$(ssh-keygen -L -f "$candidate_identity-cert.pub" | grep -o -e 'Signing CA: .*$' | cut -d' ' -f4-)"
			# echo "searching for $ca_fingerprint"
			# grep -v -P -e '^\s*#' "$authorized_keys_file" | grep -o -P -e 'ssh-\S+ \S+' | xargs -I % bash -c 'ssh-keygen -l -f <(echo "%")'
			grep -v -P -e '^\s*#' "$authorized_keys_file" | grep -o -P -e 'ssh-\S+ \S+' | xargs -I % bash -c 'ssh-keygen -l -f <(echo "%")' 2>/dev/null | grep -F -e "$ca_fingerprint" -q && return 0
		fi
	done

	return 1
}

function push_authorized_keys() {
	local compiled_authorized_keys
	compiled_authorized_keys="$(compile_file "$PWD/authorized_keys/$1")"
	# shellcheck disable=SC2181
	[[ $? -ne 0 ]] && return $?
	# echo "about to push authorized_keys to $1"

	if [[ "${1##*@}" == "localhost" && "${1%@*}" == "$USER" ]]; then
		cp "$compiled_authorized_keys" "$HOME/.ssh/authorized_keys"
	else
		# VALIDATION: ensure we don't lose access
		if ! _check_authorization "$compiled_authorized_keys" "$1"; then
			echo "WARNING! Refusing to push authorized_keys that would not allow future access to $1"
			return 2
		fi

		expected_size="$(stat -c %s "$compiled_authorized_keys")"
		# shellcheck disable=SC2002
		cat "$compiled_authorized_keys" | ssh -o ClearAllForwardings=yes "$1" bash -c 'cat > ~/.ssh/temp_authorized_keys && [[ -f .ssh/temp_authorized_keys ]] && (( $(stat -c %s ~/.ssh/temp_authorized_keys) == '"$expected_size"' )) && chmod 0600 ~/.ssh/temp_authorized_keys && mv ~/.ssh/temp_authorized_keys ~/.ssh/authorized_keys'
	fi
	rm "$compiled_authorized_keys"
}

function show_usage() {
	local prog
	prog="$(basename "$0")"
	cat <<-HELPMESSAGE
		  $prog init                            # setup a managed set of servers
		  $prog push [-s] [SERVER, ...]         # push the configuration and authorized keys to all configured servers
		  $prog compile_config SERVER           # compile the ssh_config for the given server
		  $prog push_config SERVER              # push the ssh_config to the given server
		  $prog compile_authorized_keys SERVER  # compile the authorized_keys for the given server
		  $prog push_authorized_keys SERVER     # push the authorized_keys to the given server
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
		compile_config)
			local compiled_config
			local success
			compiled_config="$(compile_file "$PWD/config/$1")"
			success=$?
			if [[ $success -ne 0 ]]; then
				exit $success
			fi
			cat "$compiled_config"
			rm "$compiled_config"
			exit 0
			;;
		compile_authorized_keys)
			local compiled_authorized_keys
			local success
			compiled_authorized_keys="$(compile_file "$PWD/authorized_keys/$1")"
			success=$?
			if [[ $success -ne 0 ]]; then
				exit $success
			fi
			cat "$compiled_authorized_keys"
			rm "$compiled_authorized_keys"
			exit 0
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
