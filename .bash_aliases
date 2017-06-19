#!/bin/bash

## directory aliases ##
#######################

# directory traversal
alias up='cd ..'
alias cd..='cd ..'

# directory listing
alias ll='ls -AhlF'
alias la='ls -AF'
alias l.='ls -d .*'
alias l='ls -CF'

## shell commands ##
####################
function ui_process() {
    if [ $# -eq 0 ]; then
        echo "USAGE: ui_process COMMAND [ARGS...]"
        return 1
    fi
    (eval "$@" 2>&1 &) >/dev/null
}

function faketty { script -qfc "$(printf "%q " "$@")"; }

function exitcode() {
    local code="${1:-0}"
    return "$code"
}

# Launch explain shell website for a commnad
function explain {
    # base url with first command already injected
    # $ explain tar
    #   => http://explainshel.com/explain/tar?args=
    url="http://explainshell.com/explain/$1?args="

    # removes $1 (tar) from arguments ($@)
    shift;

    # iterates over remaining args and adds builds the rest of the url
    for i in "$@"; do
      url=$url"$i""+"
    done

    # opens url in browser
    open "$url"
}

function sshmux() {
    ssh -t "$@" tmux new -A -s "$USER"
}
alias mux='tmuxinator'
alias va='$VISUAL ~/.bash_aliases'
alias sa='. ~/.bash_aliases'
alias h\?='history | grep'
function sync_history() {
    if [[ -f "$1" ]]; then
        local OLD_HISTFILE="$HISTFILE"
        HISTFILE="$1"
        history -r
        HISTFILE="$OLD_HISTFILE"
    fi
    history -a
    history -c
    history -r
}
alias frequent_history='history | cut -c30- | sort | uniq -c | sort -nr | head' # for finding common commands to ignore
alias htmlmail='python -c '"'"'import cgi,sys; print("<pre>" + cgi.escape(sys.stdin.read()).encode("ascii","xmlcharrefreplace") + "</pre>")'"'"' | mail -E -a "Content-Type: text/html" '
alias bashquote='python -c "import sys,pipes; print pipes.quote(sys.stdin.readline().strip())"'

function cat() {
    # test if STDOUT is a tty, and preemptively truncate output
    if [[ -t 1 ]]; then
        local output="$(tail -n $LINES -q -- "$@")"
        local trimmed="$(tail -n $((LINES - 1)) -q <<<"$output")"
        if [[ "$trimmed" != "$output" ]]; then
            echo "--- snipped. use less or grep ---"
        fi
        command cat <<<"$trimmed"
    else
        command cat "$@"
    fi
}

function mkcd() {
    mkdir -p "$@" && cd "$@" || return 1
}

function anywait() {
    for pid in "$@"; do
        while kill -0 "$pid"; do
            sleep 0.5
        done
    done
}

function track() {
    date
    command time -v "$@"
    date
    notify "completed $*"
}

## version control ##
#####################

# some git aliases
alias gg='ui_process "git gui"'
alias gk='ui_process "gitk"'

function loc() {
    local target="${1:-*}"
    echo "   lines   words   chars filename"
    find . -type f -name "$target" -exec wc {} +
}

function gitstat() {
    git log --author="$1" --pretty=tformat: --numstat | awk '{ adds += $1; subs += $2; loc += $1 - $2 } END { printf "added: %s removed: %s total: %s\n",adds,subs,loc }' -
}

function git-fetch-mirror() {
    local remote="$1"
    git ls-remote "$remote" origin/* | cut -d/ -f3- | sed 's/\(.*\)/\1:\1/' | grep -v -e 'HEAD' | xargs git fetch "$remote"
}

alias trim_trailing_spaces='sed -i -e '"'"'s/[ \t]*$//'"'"''
alias rm_conflicts="find . \( -name '*.orig' \) -delete"

## Service Development aliases ##
#################################

function jsoncurl() {
    curl -H "Accept: application/json" -H "Content-Type: application/json" "$@"
    echo
}

alias blog_serve='bundle exec jekyll serve -D -w --config _config_development.yml &'
alias prc='RAILS_ENV=production RACK_ENV=production rails c'
alias myip='curl http://httpbin.org/ip 2>/dev/null | jq -r .origin'
alias deploy='git push heroku && git push origin && heroku run rake db:migrate && notify deployed'
alias extractip4='grep -o -E -e '"'"'[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'"'"''
alias dockerip='ip -4 addr show docker0 | extractip4'
alias dockergc='docker images -f dangling=true | tail -n+2 | cut -c41-52 | xargs -I {} docker rmi {}'
alias ipy='ipython'

function docker-ssh-push() {
    docker save "$2" | bzip2 | pv | ssh "$1" 'bunzip2 | docker load'
}

alias json2bson='ruby -rjson -rbson -n -e "puts JSON.parse(\$_).to_bson.to_s"'
alias bson2json='ruby -rjson -rbson -n -e "puts Hash.from_bson(BSON::ByteBuffer.new(\$_)).to_json"'

## Silliness ##
###############
alias fucking='sudo'

function xkcd() {
    local open_command=""
    # prefer xdg-open
    if type -f xdg-open >/dev/null 2>&1; then
        open_command="xdg-open"
    elif type -f open >/dev/null 2>&1; then
        open_command="open"
    fi

    case "$@" in
        ''|*[!0-9]*)
            #"$open_command" "http://www.explainxkcd.com/wiki/index.php?go=Go&title=Special%3ASearch&search=$@"
            "$open_command" "https://relevant-xkcd.github.io/?q=$@"
            ;;
        *)
            "$open_command" "https://xkcd.com/$(($1))"
            ;;
    esac
}
