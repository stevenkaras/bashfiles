#!/usr/bin/env bash

# USAGE: __transcend_root SPECIAL_DIR
#
# Transcends the current path, checking for the existence of the given "special" dir
function __transcend_root() {
  local current=""
  local parent="$PWD"

  until [[ "$current" == "$parent" ]]; do
    if [[ -e "$parent/$1" ]]; then
      printf "%s" "$parent"
      return 0
    fi

    current="$parent"
    parent=$(dirname "$parent")
  done
}

# resolve symlinks to find the apparent project root
#
# USAGE: __project_resolve_symlinks PROJECT_ROOT [APPARENT_PWD]
function __project_resolve_symlinks() {
  local previous=""
  local current="${2:-$PWD}"

  until [[ "$previous" == "$current" ]]; do
    if [[ "$current" -ef "$1" ]]; then
      printf "%s" "$current"
      return 0
    fi

    previous="$current"
    current=$(dirname "$current")
  done

  return 1
}

# determine the root of the project
function project_root() {
  local result

  local gitroot
  gitroot="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [[ ! -z "$gitroot" ]]; then
    result="$(__project_resolve_symlinks "$gitroot" "$PWD")"
  # else
    # disabled because I don't use SVN, and it creates a ton of extra process calls
    # local svnroot=$(__transcend_root .svn)
    # if [ ! -z "$svnroot" ]; then
    #   result=$svnroot
    # fi
  fi

  if [[ "$result" = "." ]]; then
    result="$PWD"
  fi

  if [[ ! -z "$result" ]]; then
    printf "%s" "$result"
  fi
}

function project_ps1() {
  if [[ ! -z "$PROJECT_NAME" ]]; then
    printf "%s" "[${PROJECT_NAME}]${PROJECT_PATH}"
  else
    if [[ "$PWD" == "$HOME" ]]; then
      printf "%s" "~"
    else
      printf "%s" "${PWD##*/}"
    fi
  fi
}

function _project_update_name() {
  PROJECT_ROOT="$(project_root)"
  if [[ -d "$PROJECT_ROOT" ]]; then
    PROJECT_NAME="$(basename "$PROJECT_ROOT")"
    PROJECT_PATH="${PWD##$PROJECT_ROOT}"
  else
    PROJECT_NAME=""
    PROJECT_PATH=""
  fi
}

if [[ ! "$CHDIR_COMMAND" == *"_project_update_name"* ]]; then
  CHDIR_COMMAND="_project_update_name${CHDIR_COMMAND:+;$CHDIR_COMMAND}"
fi
