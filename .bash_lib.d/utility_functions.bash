
# expands the path of the given parameter
function expand_path {
    if [[ -e "$1" ]]; then
        if [[ "$1" == "." ]]; then
            echo "$PWD"
        elif [[ "$(basename "$1")" == ".." ]]; then
            pushd "$1" >/dev/null
            echo "$PWD"
            popd >/dev/null
        else
            pushd "$(dirname "$1")" >/dev/null
            echo "$PWD/$(basename "$1")"
            popd >/dev/null
        fi
    else
        echo "$(expand_path "$(dirname "$1")")/$(basename "$1")"
    fi
}

# expands the path of any non-options in the given args
function expand_args {
    ARGS=""
    for arg in "$@"; do
        if [[ "-" == "${arg:0:1}" ]]; then
            ARG=$arg
        else
            ARG=$(expand_path "$arg")
        fi
        ARGS="$ARGS $ARG"
    done
    echo "$ARGS"
}

# Cache an expensive, volatile command, caching the result for the specified number of seconds
#
# Arguments:
#  1 - the path to the cache file
#  2 - the command to generate the words for the cache
#  3 - number of seconds to cache the results for (defaults to 10 seconds)
function cache_command() {
    local gen_cache=
    local stat_options=
    local cache_period=${3:-10}
    case $(uname) in
        Darwin*) stat_options="-f%m" ;;
        *) stat_options="-c%Y" ;;
    esac
    if [[ ! -r "$1" ]]; then
        gen_cache=true
    elif (($(date +%s) - $(stat $stat_options "$1") > cache_period)); then
        gen_cache=true
    fi
    if [[ $gen_cache ]]; then
        eval "$2" > "$1"
    fi
    cat "$1"
}
