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

## version control ##
#####################

# some git aliases
function ui_process() {
    if [ $# -eq 0 ]; then
        echo "USAGE: ui_process COMMAND [ARGS...]"
        return 1
    fi
    (eval "$@" 2>&1 &) >/dev/null
}

alias gg='ui_process "git gui"'
alias gk='ui_process "gitk"'

function loc() {
    echo "   lines   words   chars filename"
    find . -type f -name $1 | xargs wc
}

function gitstat() {
    git log --author=$1 --pretty=tformat: --numstat | awk '{ adds += $1; subs += $2; loc += $1 - $2 } END { printf "added: %s removed: %s total: %s\n",adds,subs,loc }' -
}

## shell commands ##
####################

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
    open $url
}

alias fucking='sudo'
alias va='$VISUAL ~/.bash_aliases'
alias sa='. ~/.bash_aliases'
alias h?='history | grep'
alias sync_history='history -a; history -c; history -r'
function mkcd() {
    mkdir -p $@ && cd $@
}
function anywait() {
    for pid in "$@"; do
        while kill -0 "$pid"; do
            sleep 0.5
        done
    done
}

## Service Development aliases ##
#################################

function jsoncurl() {
    curl -H "Accept: application/json" -H "Content-Type: application/json" $@
    echo
}

alias blog_serve='bundle exec jekyll serve -D -w --config _config_development.yml &'
alias prc='RAILS_ENV=production RACK_ENV=production rails c'
alias myip='curl http://httpbin.org/ip 2>/dev/null | jq -r .origin'
alias deploy='git push heroku && git push origin && heroku run rake db:migrate && notify deployed'
