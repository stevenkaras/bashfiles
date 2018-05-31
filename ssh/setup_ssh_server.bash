#!/usr/bin/env bash

# create a new ssh keypair, setup the server in the ssh config,
# and push the new key into the authorized keys for that server
#
# Roughly equivalent to:
# ssh-keygen -t rsa -b 4096 -C "$(hostname)@server <$USER_EMAIL>" -f ~/.ssh/user@server.id_rsa
# cat ~/.ssh/user@server.id_rsa.pub | ssh user@server "cat >> \$HOME/.ssh/authorized_keys"

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

    tee -a "$HOME/.ssh/config" <<SSH_CONFIG >/dev/null

Host $server
    HostName $server
    Port $port
    User $username
SSH_CONFIG
    local id_file="$username@$server.id_rsa"
    ssh-keygen -t rsa -b 4096 -C "$(hostname)@$server <$USER_EMAIL>" -f "$HOME/.ssh/$id_file"
    local new_key="$(cat "$HOME/.ssh/$id_file.pub")"
    ssh -p $port -i "$HOME/.ssh/$id_file" "$username@$server" "tee -a \$HOME/.ssh/authorized_keys <<<\"$new_key\" >/dev/null"
}

setup_ssh_server "$@"
