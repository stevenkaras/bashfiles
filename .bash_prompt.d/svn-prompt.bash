# this script adds a function to output the current branch/revision/other stuff
# for svn working copies

# determine the root of an svn working copy
function __svnroot() {
  local parent=""
  local grandparent="$PWD"

  while [ -d "$grandparent/.svn" ]; do
    parent=$grandparent
    grandparent=$(dirname $parent)
  done

  if [ ! -z "$parent" ]; then
    echo $parent
  fi
}

# outputs the location of the .svn directory
function __svn_dir() {
	if [ -z "${1-}" ]; then
		echo ".svn"
	else
		echo "$1/.svn"
	fi
}

# outputs the svn working copy information
__svn_ps1 ()
{
	if [ -d "$(__svnroot)" ]; then
		local revision=$(__svn_revision)
		local branch=$(__svn_branch)
		local flags=$(__svn_state)
		printf -- "${1:- (%s)}" "$branch:$revision$flags"
	fi
}

# outputs the state of a repo as a short set of flags
__svn_state ()
{
	local d=
	if [ -d "$(__svnroot)" ]; then
		if [ -n "${SVN_PS1_SHOWDIRTYSTATE-}" ]; then
			local changed=`svn status | grep '^\s*[?ACDMR?!]'`
			[ -z "$changed" ] && d=*
		fi
		echo $d
	fi
}

# outputs the current revision
__svn_revision ()
{
	local r=
	if [ -d "$(__svnroot)" ]; then
		if [ -n "${SVN_PS1_SHOWREVISION-}" ]; then
			r=`svn info | grep 'Revision' | awk '/Revision:/ {print $2}'`
		fi
		echo $r
	fi
}

# outputs the current svn branch
__svn_branch ()
{
	local url=
	if [ -d "$(__svnroot)" ]; then
		url=`svn info | awk '/URL:/ {print $2}'`
		if [[ $url =~ trunk ]]; then
			echo trunk
		elif [[ $url =~ /branches/ ]]; then
			echo $url | sed -e 's#^.*/\(branches/.*\)/.*$#\1#'
		elif [[ $url =~ /tags/ ]]; then
			echo $url | sed -e 's#^.*/\(tags/.*\)/.*$#\1#'
		fi
	fi
}
