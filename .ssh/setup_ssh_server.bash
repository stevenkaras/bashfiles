#!/usr/bin/env bash

function setup_ssh_server() {
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
    echo "Setting up $username@$server:$port"

    tee -a $HOME/.ssh/config <<SSH_CONFIG >/dev/null

Host $server
    HostName $server
    Port $port
    User $username
SSH_CONFIG
    local id_file="$username@$server.id_rsa"
    ssh-keygen -t rsa -b 4096 -C "$(hostname)@$server <$USER_EMAIL>" -f $HOME/.ssh/$id_file
    ssh-copy-id -i "$HOME/.ssh/$id_file.pub" -p $port $server
}

setup_ssh_server $@
