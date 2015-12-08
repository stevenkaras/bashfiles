#!/usr/bin/env bash

function rotate_ssh_key() {
    local username="${1%@*}"
    if [[ "$username" == "$1" ]]; then
        username="$(whoami)"
    fi
    local server="${1##*@}"
    local port="${server##*:}"
    if [[ "$port" == "$server" ]]; then
        port="${2:-22}"
    else
        server="${server%:*}"
    fi
    echo "Rotating key on $username@$server:$port"

    local id_file="$username@$server.id_rsa"
    local key_to_revoke="$(ssh-keygen -l -f "$HOME/.ssh/$id_file" | cut -d ' ' -f2)"
    mkdir -p "$HOME/.ssh/archive"
    local archive_id_file="$(date +%Y%m%d-%H%M%S)-$id_file"
    mv "$HOME/.ssh/$id_file" "$HOME/.ssh/archive/$archive_id_file"
    mv "$HOME/.ssh/$id_file.pub" "$HOME/.ssh/archive/$archive_id_file.pub"
    # ssh into the server and revoke the specific key we're rotating
    ssh-keygen -t rsa -b 4096 -C "$(hostname)@$server <$USER_EMAIL>" -f "$HOME/.ssh/$id_file"
    local new_key="$(cat $HOME/.ssh/$id_file.pub)"
    ssh -p $port -i "$HOME/.ssh/archive/$archive_id_file" $username@$server "tee -a \$HOME/.ssh/authorized_keys <<<\"$new_key\" >/dev/null; $(typeset -f revoke_key); revoke_key $key_to_revoke"
    ssh-add "$HOME/.ssh/$id_file"
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
    done < "$authorized_keys" > "$authorized_keys.new"
    mkdir -p "$HOME/.ssh/archive"
    cp "$authorized_keys" "$HOME/.ssh/archive/$(date +%Y%m%d-%H%M%S)-authorized_keys"
    mv "$authorized_keys.new" "$authorized_keys"
}

rotate_ssh_key "$@"
