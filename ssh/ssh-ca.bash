#!/usr/bin/env bash

function setup_ca() {
	local target="${1:-$HOME/.ssh/ca}"
	if [[ -e "$target" ]]; then
		if [[ -d "$target" && -z "$(ls -A "$target")" ]]; then
			# target is an empty directory
			:
		else
			>&2 echo "$target already exists. not setting up SSH CA"
			return 1
		fi
	fi
	mkdir -p "$target"
	chmod 755 "$target"
	mkdir -p "$target/private"
	chmod 700 "$target/private"
	mkdir -p "$target/certs"
	touch "$target/audit.log"
	chmod 644 "$target/audit.log"
	echo "1" > "$target/next_cert_id"
	chmod 644 "$target/next_cert_id"
	echo "1" > "$target/next_krl_id"
	chmod 644 "$target/next_krl_id"
	ssh-keygen -t rsa -b 4096 -f "$target/private/ca_key" -C "CA by $USER_EMAIL" || return $?
	cp "$target/private/ca_key.pub" "$target/ca.pub"
	touch "$target/krl.source"
	ssh-keygen -s "$target/private/ca_key" -z 0 -k -f "$target/krl"
}

function _save_key_from_stdin() {
	local tmpdir
	tmpdir="$(mktemp -d)"
	# shellcheck disable=SC2181
	if [[ $? != 0 ]]; then
		>&2 echo "Failed to create temporary directory for stdin input"
	fi
	cat > "$tmpdir/ssh_id.pub"
	echo "$tmpdir/ssh_id.pub"
}

function _cleanup_key_from_stdin() {
	local key_to_sign="$1"
	local cert_path="${key_to_sign/%.pub/-cert.pub}"
	cat "$cert_path"
	rm "$cert_path" "$key_to_sign"
	rmdir "$(dirname "$cert_path")"
}

function sign_key() {
	local cert_id
	cert_id="$(cat "$SSHCA_ROOT/next_cert_id")"
	local key_to_sign="$1"
	local saved_key_from_stdin=""
	shift
	if [[ -z "$key_to_sign" || "$key_to_sign" == "-" ]]; then
		key_to_sign="$(_save_key_from_stdin)"
		saved_key_from_stdin=true
	fi
	if [[ ! -f "$key_to_sign" ]]; then
		>&2 echo "$key_to_sign does not exist"
		return 1
	fi
	if [[ "$key_to_sign" != *.pub ]]; then
		if [[ -f "$key_to_sign.pub" ]]; then
			key_to_sign="$key_to_sign.pub"
		else
			>&2 echo "refusing to sign non-key $key_to_sign"
			return 1
		fi
	fi
	local key_identity
	key_identity="$(ssh-keygen -l -f "$key_to_sign")"
	# local key_comment
	# key_comment="$(echo "$key_identity" | cut -d' ' -f4-)"
	local cert_path="${key_to_sign/%.pub/-cert.pub}"
	local cert_name
	cert_name="$(basename "$cert_path")"
	ssh-keygen -s "$SSHCA_ROOT/private/ca_key" -I "$cert_id-$USER_EMAIL" -z "$cert_id" "$@" "$key_to_sign" || return $?
	echo $((cert_id + 1)) > "$SSHCA_ROOT/next_cert_id"
	echo "$(date -u +%FT%T%z):sign:$cert_id: $key_identity" >> "$SSHCA_ROOT/audit.log"
	cp "$cert_path" "$SSHCA_ROOT/certs/${cert_id}-${cert_name}"
	if [[ -n "$saved_key_from_stdin" ]]; then
		_cleanup_key_from_stdin "$key_to_sign"
	fi
}

function sign_host_keys() {
	while IFS= read -r line; do
		$line
	done < <(:)
	key_to_sign="$(_save_key_from_stdin)"
	_sign_host_key "$key_to_sign" "$@"
	_cleanup_key_from_stdin "$key_to_sign"
}

function sign_host_key() {
	local key_to_sign="$1"
	shift
	if [[ -f "$key_to_sign" ]]; then
		_sign_host_key "$key_to_sign" "$@"
	elif [[ -z "$key_to_sign" || "$key_to_sign" == "-" ]]; then
		key_to_sign="$(_save_key_from_stdin)"
		_sign_host_key "$key_to_sign" "$@"
		_cleanup_key_from_stdin "$key_to_sign"
	else
		# assume it's a server
	    local server="$key_to_sign"
		local port="${server##*:}"
		if [[ "$port" == "$server" ]]; then
			port="22"
		else
			server="${server%:*}"
		fi
		local scan_result
		scan_result="$(ssh-keyscan -p "$port" "$server" 2>/dev/null | grep -v -e '^#' | head -n 1)"
	    local scan_key="${scan_result#* }"
		if [[ -z "$scan_key" ]]; then
			>&2 echo "$key_to_sign is not a public key file, and ssh-keyscan failed"
			return 1
		fi
		key_to_sign="$(echo "$scan_key" | _save_key_from_stdin)"
		_sign_host_key "$key_to_sign" "$@"
		_cleanup_key_from_stdin "$key_to_sign"
	fi
}

function _sign_host_key() {
	local key_to_sign="$1"
	local cert_path="${key_to_sign/%.pub/-cert.pub}"
	local cert_file="${cert_path##*/}"
	shift
	if sign_key "$key_to_sign" -h "$@"; then
		>&2 echo "Signed key for $server in $cert_file"
		>&2 echo "For your sshd to use the certificate, run this on the server:"
		>&2 echo "printf 'HostCertificate /etc/ssh/$cert_file' | sudo tee -a /etc/ssh/sshd_config >/dev/null"
	else
		>&2 echo "failed to sign $key_type from $server"
		return 1
	fi
}

function revoke() {
	local krl_id
	krl_id="$(cat "$SSHCA_ROOT/next_krl_id")"
	# first, build the KRL actions
	for arg in "$@"; do
		if [[ -f "$arg" ]]; then
			cat "$arg" >> "$SSHCA_ROOT/krl.source"
		else
			echo "$arg" >> "$SSHCA_ROOT/krl.source"
		fi
		echo "$(date -u +%FT%T%z):revoke: $arg" >> "$SSHCA_ROOT/audit.log"
	done
	ssh-keygen -s "$SSHCA_ROOT/private/ca_key" -z "$krl_id" -k -u -f "$SSHCA_ROOT/krl" "$SSHCA_ROOT/krl.source" || return $?
	echo $((krl_id + 1)) > "$SSHCA_ROOT/next_krl_id"
	echo "$(date -u +%FT%T%z):revoke: updated krl to revision $krl_id" >> "$SSHCA_ROOT/audit.log"
}

function trust_ca() {
    local username="${1%@*}"
    if [[ "$username" == "$1" ]]; then
        username="$USER"
    fi
    local server="${1##*@}"
	local port="${server##*:}"
	if [[ "$port" == "$server" ]]; then
		port="22"
	else
		server="${server%:*}"
	fi
	shift

	case "$server" in
		localhost|--local|"")
			_knownhosts_ca_stanza "$@" >> "$HOME/.ssh/known_hosts"
			;;
		*)
			>&2 echo "Setting CA as authorized for $username@$server:$port"
			# shellcheck disable=SC2029
			ssh -p $port "$username@$server" "tee -a \$HOME/.ssh/authorized_keys <<<\"$(_authorized_key_ca_stanza "$@")\" >/dev/null"
			;;
	esac
}

function _authorized_key_ca_stanza() {
	local IFS=","
	local principals="$*"
	unset IFS
	if [[ -n "$principals" ]]; then
		principals=" principals=\"$principals\""
	fi
	local ca_pub
	ca_pub="$(cat "$SSHCA_ROOT/ca.pub")"
	echo "cert-authority$principals $ca_pub"
}

function _knownhosts_ca_stanza() {
	local hosts="$*"
	if [[ -z "$hosts" ]]; then
		hosts="*"
	fi
	local ca_pub
	ca_pub="$(cat "$SSHCA_ROOT/ca.pub")"
	echo "@cert-authority $hosts $ca_pub"
}

function find_ca_root() {
	if [[ -n "$SSHCA_ROOT" ]]; then
		return 0
	fi

	local default="$HOME/.ssh/ca"
	if [[ -d "$default" ]]; then
		export SSHCA_ROOT="$default"
		return 0
	fi

	>&2 echo "SSH CA not set up. Run $(basename "$0") setup"
	return 1
}

function trustconfig() {
	_authorized_key_ca_stanza "$1"
	shift
	_knownhosts_ca_stanza "$1"
}

function show_usage() {
	local prog
	prog="$(basename "$0")"
	cat <<-HELPMESSAGE
		  $prog setup                                         # perform the initial setup to start acting as a SSH CA
		  $prog install [USER@]SERVER[:PORT] [PRINCIPALS...]  # install the CA certificate on the given server (limited to certs with the given principals)
		  $prog sign KEY [-n PRINCIPALS] [OPTIONS]            # sign the given KEY
		  $prog signhost KEY [-n PRINCIPALS] [OPTIONS]        # sign the given host KEY
		  $prog signhosts [-n PRINCIPLES] [OPTIONS]           # sign host keys from STDIN (one per line)
		  $prog revoke CERTS...                               # revoke a certificate
		  $prog trustconfig [PRINCIPALS [HOSTS]]              # print the config stanzas for trusting keys signed by the CA
		  $prog implode                                       # delete the CA permanently
	HELPMESSAGE
	if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
		cat <<-VERBOSEHELP

		SSH can act as a certificate authority, allowing shorter authorized_keys and known_hosts files to be distributed as part of VM images. $prog has many shortcuts to make operating a CA for SSH much easier. First, set up the CA, generate the key you'd like to sign, and sign using this script, and use the signed certificate when connecting to the server. As a convenience, you can quickly install the relevant configuration stanza on a remote server.

		If your signed keys are compromised, you can revoke them using the syntax defined in KEY REVOCATION LIST section of the ssh-keygen manpage.
		VERBOSEHELP
	fi
}

function main() {
	local subcommand="$1"
	shift
	case "$subcommand" in
		setup)
			setup_ca "$@"
			exit $?
			;;
		install)
			find_ca_root || exit $?
			trust_ca "$@"
			exit $?
			;;
		revoke)
			find_ca_root || exit $?
			revoke "$@"
			exit $?
			;;
		sign)
			find_ca_root || exit $?
			sign_key "$@"
			exit $?
			;;
		signhosts)
			find_ca_root || exit $?
			sign_host_keys "$@"
			exit $?
			;;
		signhost)
			find_ca_root || exit $?
			sign_host_key "$@"
			exit $?
			;;
		trustconfig)
			find_ca_root || exit $?
			trustconfig "$@"
			exit $?
			;;
		selfdestruct|uninstall|implode)
			find_ca_root || exit $?
			read -r -p "About to delete $SSHCA_ROOT. Type yes to continue: "
			if [[ "$REPLY" == "yes" ]]; then
				local removal_command="rm"
				type -t srm >/dev/null 2>&1 && removal_command="srm"
				"$removal_command" -r "$SSHCA_ROOT"
			else
				>&2 echo "Not deleting $SSHCA_ROOT"
			fi
			exit $?
			;;
		-\?|-h|--help|help|"")
			>&2 show_usage "$@"
			exit $?
			;;
		*)
			>&2 echo "Unknown command: $subcommand"
			>&2 echo ""
			>&2 show_usage
			exit 2
			;;
	esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
