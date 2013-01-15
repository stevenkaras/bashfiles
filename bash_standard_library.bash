
## set up chdir hook ##
#######################
function on_chdir() {
    if [ "$PWD" != "$ONCHDIR_OLDPWD" ]; then
        ONCHDIR_OLDPWD="$PWD"
        $CHDIR_COMMAND
    fi
}
PROMPT_COMMAND="${PROMPT_COMMAND}on_chdir;"

function set_tab_title() {
    case $TERM in
    xterm)
        echo -ne "\033]0;$1\a"
        ;;
    *)
        ;;
    esac

    # local project_name=$(__project_name)
    # if [[ -n "$project_name" ]]; then
    #     echo -ne "\033]0;$(__project_name)\a"
    # fi
}

# expands the path of the given parameter
function expand_path {
    if [[ -e "$1" ]]; then
        if [[ "$1" == "." ]]; then
            echo "$(pwd)"
        elif [[ "$(basename "$1")" == ".." ]]; then
            pushd "$1" >/dev/null
            echo "$(pwd)"
            popd >/dev/null
        else
            pushd "$(dirname "$1")" >/dev/null
            echo "$(pwd)/$(basename "$1")"
            popd >/dev/null
        fi
    else
        echo "$(expand_path $(dirname "$1"))/$(basename "$1")"
    fi
}

# expands the path of any non-options in the given args
function expand_args {
    ARGS=""
    for arg in $@; do
        if [[ "-" == "${arg:0:1}" ]]; then
            ARG=$arg
        else
            ARG=$(expand_path $arg)
        fi
        ARGS="$ARGS $ARG"
    done
    echo $ARGS
}
