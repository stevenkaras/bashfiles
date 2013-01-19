
# determine the root of the project
function project_root() {
  local result

  local gitdir=$(__gitdir)
  if [ ! -z "$gitdir" ]; then
    result=$(dirname $gitdir)
  else
    local svnroot=$(__svnroot)
    if [ ! -z "$svnroot" ]; then
      result=$svnroot
    fi
  fi

  if [ "$result" = "." ]; then
    result="$PWD"
  fi

  if [ ! -z "$result" ]; then
    echo $result
  fi
}

# determine the relative path within the project
function project_path() {
  local project_root=$(project_root)
  if [ -d "$project_root" ]; then
    echo ${PWD##$project_root}
  fi
}

# determine the project name
function project_name() {
  local project_root="$(project_root)"
  if [ -d "$project_root" ]; then
    echo $(basename "$project_root")
  fi
}

function project_ps1() {
  local project_name="$(project_name)"
  if [ ! -z "$project_name" ]; then
    local project_path="$(project_path)"
    echo "[${project_name}]${project_path}"
  else
    if [ "$PWD" = "$HOME" ]; then
      echo "~"
    else
      echo "$(basename "$PWD")"
    fi
  fi
}

function project_update_name() {
  PROJECT_NAME=$(project_name)
  PROJECT_PATH=$(project_path)
  PROJECT_ROOT=$(project_root)
}
CHDIR_COMMAND="project_update_name;${CHDIR_COMMAND}"
