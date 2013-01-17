
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

# Cache an expensive, volatile command, caching the result for 10 seconds
#
# Arguments:
#  1 - the path to the cache file
#  2 - the command to generate the words for the cache
function cache_command() {
    local gen_cache=
    local stat_options="-c%Y"
    case $(uname) in
        Darwin*)
            stat_options="-f%m"
            ;;
    esac
    if [[ ! -r "$1" ]]; then
        gen_cache=true
    elif (($(date +%s) - $(stat $stat_options "$1") > 10)); then
        gen_cache=true
    fi
    if [[ $gen_cache ]]; then
        eval $2 > "$1"
    fi
    echo $(cat "$1")
}
