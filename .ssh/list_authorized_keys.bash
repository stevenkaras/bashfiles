#!/usr/bin/env bash

function list_authorized_keys() {
    local authorized_keys="${1:-$HOME/.ssh/authorized_keys}"
    if [[ ! -f "$authorized_keys" ]]; then
        echo "USAGE: list_authorized_keys [FILE]"
        return 1
    fi
    echo "listing keys from $authorized_keys:"

    local -a keys
    mapfile keys < $authorized_keys
    local comment=""
    local fingerprint=""
    local key=""
    for i in ${!keys[@]}; do
        key="${keys[$i]}"
        if [[ -n "$key" && ${key###} = "$key" ]]; then
            ssh-keygen -l -f /dev/stdin <<<"$key"
        fi
    done
}

list_authorized_keys "$@"
