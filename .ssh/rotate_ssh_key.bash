#!/usr/bin/env bash

function rotate_ssh_key() {
    local username="${1%@*}"
    if [[ "$username" == "$1" ]]; then
        username="$(whoami)"
    fi
    local server="${1##*@}"
    local port="${1##*:}"
    if [[ "$port" == "$server" ]]; then
        port="${2:-22}"
    else
        server="${server%:*}"
    fi
    echo "Rotating key on $username@$server:$port"

    local id_file="$username@$server.id_rsa"
    local key_to_revoke="$(ssh-keygen -l -f "$HOME/.ssh/$id_file" | cut -d ' ' -f2)"
    mkdir -p "$HOME/.ssh/old_keys"
    mv "$HOME/.ssh/$id_file" "$HOME/.ssh/archives/$(date +%Y%m%d-%H%M%S)"
    # ssh into the server and revoke the specific key we're rotating
    setup_ssh_key "$username@$server:$port"
    ssh $username@$server "$(typeset -f revoke_key); revoke_key $key_to_revoke"
}

function revoke_key() {
    local key_to_revoke="$1"

    # revokes the key with the given fingerprint from the authorized_keys file
    local authorized_keys="$HOME/.ssh/authorized_keys"

    while read -r line; do
        if [[ -n "$line" && ${line###} == "$line" ]]; then
            local fingerprint="$(ssh-keygen -l -f /dev/stdin <<<"$line" | cut -d ' ' -f2)"
            if [[ "$fingerprint" != "$key_to_revoke" ]]; then
                echo "$line"
            fi
        else
            echo "$line"
        fi
    done < $authorized_keys > $authorized_keys.new
    mv $authorized_keys.new $authorized_keys
}

rotate_ssh_key $@
