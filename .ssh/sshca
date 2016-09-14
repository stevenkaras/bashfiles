#!/usr/bin/env bash

function setup_ca() {
	local target="${1:-$HOME/.ssh/ca}"
	if [[ -e "$target" ]]; then
		if [[ -d "$target" && -z "$(ls -A "$target")" ]]; then
			# target is an empty directory
			:
		else
			echo "$target already exists. not setting up SSH CA"
			return 1
		fi
	fi
	mkdir -p "$target/private"
	mkdir -p "$target/certs"
	touch "$target/audit.log"
	echo "1" > "$target/next_cert_id"
	echo "1" > "$target/next_krl_id"
	ssh-keygen -t rsa -b 4096 -f "$target/private/ca_key" -C "CA by $USER_EMAIL"
	[[ $? != 0 ]] && return $?
	cp "$target/private/ca_key.pub" "$target/ca.pub"
	ssh-keygen -s "$target/private/ca_key" -z 0 -k -f "$target/krl"
}

function sign() {
	local cert_id="$(cat "$SSHCA_ROOT/next_cert_id")"
	local key_to_sign="$1"
	if [[ ! -f "$key_to_sign" ]]; then
		echo "$key_to_sign does not exist"
		return 1
	fi
	if [[ "$key_to_sign" != *.pub ]]; then
		if [[ -f "$key_to_sign.pub" ]]; then
			key_to_sign="$key_to_sign.pub"
		else
			echo "refusing to sign non-key $key_to_sign"
			return 1
		fi
	fi
	local key_identity="$(ssh-keygen -l -f "$key_to_sign")"
	local key_comment="$(echo "$key_identity" | cut -d' ' -f4-)"
	local cert_path="${1/%.pub/-cert.pub}"
	local cert_name="$(basename "$cert_path")"
	ssh-keygen -s "$SSHCA_ROOT/private/ca_key" -I "$cert_id-$USER_EMAIL" -z "$cert_id" "$key_to_sign"
	[[ $? != 0 ]] && return $?
	echo $(($cert_id + 1)) > "$SSHCA_ROOT/next_cert_id"
	echo "$(date -u -Isecond):sign:$cert_id: $key_identity" >> "$SSHCA_ROOT/audit.log"
	cp "$cert_path" "$SSHCA_ROOT/certs/${cert_id}-${cert_name}"
}

function revoke() {
	local krl_id="$(cat "$SSHCA_ROOT/next_krl_id")"
	# first, build the KRL actions
	truncate --size=0 "$SSHCA_ROOT/krl_actions"
	for arg in "$@"; do
		if [[ -f "$arg" ]]; then
			cat "$arg" >> "$SSHCA_ROOT/krl_actions"
		else
			echo "$arg" >> "$SSHCA_ROOT/krl_actions"
		fi
		echo "$(date -u -Isecond):revoke: $arg" >> "$SSHCA_ROOT/audit.log"
	done
	ssh-keygen -s "$SSHCA_ROOT/private/ca_key" -z "$krl_id" -k -u -f "$SSHCA_ROOT/krl" "$SSHCA_ROOT/krl_actions"
	[[ $? != 0 ]] && return $?
	echo $(($krl_id + 1)) > "$SSHCA_ROOT/next_krl_id"
	echo "$(date -u -Isecond):revoke: updated krl to revision $krl_id" >> "$SSHCA_ROOT/audit.log"
	rm "$SSHCA_ROOT/krl_actions"
}

function authorized_key_ca_stanza() {
	local IFS=","
	local principals="$@"
	unset IFS
	if [[ -n "$principals" ]]; then
		principals=" principals=\"$principals\""
	fi
	local ca_pub="$(cat "$SSHCA_ROOT/ca.pub")"
	echo "cert-authority$principals $ca_pub"
}

function install_on_server() {
	local server="$1"
	local port="${server##*:}"
	if [[ "$port" == "$server" ]]; then
		port="22"
	else
		server="${server%:*}"
	fi
	shift

	echo "Setting CA as authorized for $username@$server:$port"
	ssh -p $port "$username@$server" "tee -a \$HOME/.ssh/authorized_keys <<<\"$(authorized_key_ca_stanza "$@")\" >/dev/null"
}

function knownhosts_ca_stanza() {
	local hosts="$@"
	if [[ -z "$hosts" ]]; then
		hosts="*"
	fi
	local ca_pub="$(cat "$SSHCA_ROOT/ca.pub")"
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

	echo "SSH CA not set up. Run $(basename "$0") setup"
	return 1
}

function trustconfig() {
	authorized_key_ca_stanza "$1"
	shift
	knownhosts_ca_stanza "$1"
}

function show_usage() {
	local prog="$(basename "$0")"
	cat <<-HELPMESSAGE
		  $prog setup                                         # perform the initial setup to start acting as a SSH CA
		  $prog install [USER@]SERVER[:PORT] [PRINCIPALS...]  # install the CA certificate on the given server (limited to certs with the given principals)
		  $prog sign KEY [-n PRINCIPALS] [OPTIONS]            # sign the given KEY
		  $prog signhost KEY [OPTION]                         # sign the given host KEY
		  $prog revoke CERTS...                               # revoke a certificate
		  $prog trustconfig [PRINCIPALS [HOSTS]]              # print the config stanzas for trusting keys signed by the CA
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
			install_on_server "$@"
			exit $?
			;;
		revoke)
			find_ca_root || exit $?
			revoke "$@"
			exit $?
			;;
		sign)
			find_ca_root || exit $?
			sign "$@"
			exit $?
			;;
		signhost)
			find_ca_root || exit $?
			sign -h "$@"
			exit $?
			;;
		trustconfig)
			find_ca_root || exit $?
			trustconfig "$@"
			exit $?
			;;
		-?|-h|--help|help|"")
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
