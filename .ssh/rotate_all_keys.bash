#!/usr/bin/env bash

function rotate_all_keys() {
    for pubkey in $HOME/.ssh/*.id_rsa.pub; do
        local keyfile="${pubkey##*/}"
        local keyname="${keyfile%*.id_rsa.pub}"
        local username="${keyname%@*}"
        local remote_host="${keyname#*@}"
        # skip known problematic keys (github, etc)
        case "$remote_host" in
            github.com )
                continue
                ;;
        esac
        rotate_ssh_key "$username@$remote_host"
    done
}

rotate_all_keys "$@"
