#!/usr/bin/env bash

function autosign() {
	local tmpfile
	tmpfile="$(mktemp)" # for printing errors
	[[ $? != 0 ]] && return 1

	local key_to_sign="$1"
	local cert_path="${key_to_sign/%.pub/-cert.pub}"
	# remove any previous certificate
	[[ -e "$cert_path" ]] && rm "$cert_path"

	# clock drift happens, so sign certs to be valid 5 minutes in the past
	local validity_period="${2:--5m:+1w}"

	SSHCA_ROOT="$HOME/.ssh/ca" "$HOME/bin/ssh-ca" sign "$key_to_sign" -V "$validity_period" >"$tmpfile" 2>&1
	local exit_code="$?"
	if [[ "$exit_code" != 0 ]]; then
		cat "$tmpfile"
		rm "$tmpfile"
		return "$exit_code"
	fi
	rm "$tmpfile"

	cat "$cert_path"
}

function trust() {
	local ACME_ROOT="$SSHCA_ROOT/acme"
	mkdir -p "$SSHCA_ROOT/acme"
	cp "$1" "$ACME_ROOT"
	local key_path="$ACME_ROOT/${1##*/}"

	local fingerprint
	fingerprint="$(ssh-keygen -l -f "$key_path")"
	local exit_code="$?"
	if [[ "$exit_code" != 0 ]]; then
		echo "$1 is not a public SSH keyfile"
		rm "$key_path"
		return "$exit_code"
	fi

	local authorized_keys_prefix="command=\"env -i \$HOME/bin/ssh-acme autosign $key_path\""
	# the ssh-acme/ssh-ca scripts require a pty...so we can't set no-pty
	local authorized_keys_options=',no-agent-forwarding,no-port-forwarding,no-user-rc,no-X11-forwarding'
	local authorized_keys_stanza
	authorized_keys_stanza="${authorized_keys_prefix}${authorized_keys_options} $(cat "$key_path")"
	echo "$authorized_keys_stanza" >> "$HOME/.ssh/authorized_keys"
	echo "$(date -u +%FT%T%z):acme-trust: $fingerprint" >> "$SSHCA_ROOT/audit.log"
	echo "Trusted $fingerprint to be automatically issued certificates"
}

function revoke() {
	local tmpfile
	tmpfile="$(mktemp)"
	[[ $? != 0 ]] && return 1

	local ACME_ROOT="$SSHCA_ROOT/acme"
	mkdir -p "$SSHCA_ROOT/acme"
	local key_to_revoke="$1"
	local fingerprint="$1"
	if [[ -e "$key_to_revoke" ]]; then
		fingerprint="$(ssh-keygen -l -f "$key_to_revoke")"
		local exit_code="$?"
		if [[ "$exit_code" != 0 ]]; then
			echo "$key_to_revoke is not a public SSH keyfile"
			return "$exit_code"
		fi
		fingerprint="$(echo "$fingerprint" | cut -d' ' -f2)"
	fi

	# remove the key with the fingerprint from the authorized keys
	local authorized_keys="$HOME/.ssh/authorized_keys"
    local options
    local keytype
    local key
    local comment

	while read -r line; do
        if [[ "$line" = "#"* || -z "$line" ]]; then
            echo "$line"
            continue
        fi

        # parse the key line into [OPTIONS] KEYTYPE KEY COMMENT...
		key="$line"
        options="${key%% *}"
        key="${key#* }"
        case "$options" in
            # valid key types taken from man 8 sshd (AUTHORIZED_KEYS section)
            ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521|ssh-ed25519|ssh-dss|ssh-rsa)
                keytype="$options"
                options=""
                ;;
            *)
                keytype="${key%% *}"
                key="${key#* }"
                ;;
        esac
        comment="${key#* }"
        key="${key%% *}"

        # SSH requires the use of a file, and is incapable of working off stdin, so write to a tmpfile
        printf "%s %s %s" "$keytype" "$key" "$comment" > "$tmpfile"
        local stored_fingerprint
		stored_fingerprint="$(ssh-keygen -l -f "$tmpfile" | cut -d' ' -f2)"
		if [[ "$stored_fingerprint" != "$fingerprint" ]]; then
			echo "$line"
		fi
	done < "$authorized_keys" > "$authorized_keys.new"
	mv "$authorized_keys.new" "$authorized_keys"

	# delete the stored keyfile
	for stored_keyfile in "$ACME_ROOT/"*; do
		local stored_fingerprint
		stored_fingerprint="$(ssh-keygen -l -f "$stored_keyfile" | cut -d' ' -f2)"
		[[ "$stored_fingerprint" == "$fingerprint" ]] && rm "$stored_keyfile"
	done
	echo "$(date -u +%FT%T%z):acme-revoke: $fingerprint" >> "$SSHCA_ROOT/audit.log"
	echo "$fingerprint has been revoked and will not be issued any new certificates"
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

	echo "SSH CA not set up"
	return 1
}

function show_usage() {
	local prog="${0##*/}"
	cat <<-HELPMESSAGE
		  $prog trust KEYFILE                 # Trust a key to be issued certificates automatically
		  $prog trusthost KEYFILE             # Trust a key to be issued host certificates automatically
		  $prog revoke [KEYFILE|FINGERPRINT]  # Revoke a key, so it cannot be issued any more certificates
	HELPMESSAGE
	if [[ "$1" == "-v" || "$1" == "--verbose" ]]; then
		cat <<-VERBOSEHELP

		$prog, along with ssh-ca, allow you to automatically issue SSH certificates
		VERBOSEHELP
	fi
}

function main() {
	local subcommand="$1"
	shift
	case "$subcommand" in
		autosign)
			find_ca_root || exit $?
			autosign "$@"
			exit $?
			;;
		trust)
			find_ca_root || exit $?
			trust "$@"
			exit $?
			;;
		revoke)
			find_ca_root || exit $?
			revoke "$@"
			exit $?
			;;
		-?|-h|--help|help|"")
			>&2 show_usage "$@"
			exit $?
			;;
		*)
			echo "Unknown command: $subcommand"
			echo ""
			>&2 show_usage
			exit 2
			;;
	esac
}

main "$@"
