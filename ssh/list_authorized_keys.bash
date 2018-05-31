#!/usr/bin/env bash

function list_authorized_keys() {
    local authorized_keys="${1:-$HOME/.ssh/authorized_keys}"
    if [[ ! -f "$authorized_keys" ]]; then
        echo "USAGE: list_authorized_keys [FILE]"
        return 1
    fi
    echo "listing keys from $authorized_keys:"

    local -a keys
    mapfile keys < "$authorized_keys"
    local options
    local keytype
    local key
    local comment
    local is_ca_key
    local tmpfile="$(mktemp)"

    for key in "${keys[@]}"; do
        key="${key:0:-1}"
        if [[ "$key" = "#"* || -z "$key" ]]; then
            continue
        fi

        # parse the key line into [OPTIONS] KEYTYPE KEY COMMENT...
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

        #TODO: improve options parsing (this may pick up the content of a ENVVAR or command)
        if [[ "$options" = *cert-authority* ]]; then
            is_ca_key="true"
        else
            is_ca_key=""
        fi

        # SSH requires the use of a file, and is incapable of working off stdin, so write to a tmpfile
        printf "%s %s %s" "$keytype" "$key" "$comment" > "$tmpfile"

        if [[ -n "$is_ca_key" ]]; then
            echo -n 'CA: '
        fi
        if [[ -n "$key" && ${key###} = "$key" ]]; then
            ssh-keygen -l -f "$tmpfile"
        fi
    done
    rm "$tmpfile"

    return 0
}

list_authorized_keys "$@"
