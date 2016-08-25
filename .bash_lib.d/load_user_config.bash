# this loads a well known bashrc based on the REMOTE_USER env variable
# the recommended use of this is to serve as a dispatching script on shared servers
#
# the expected location is .bash_users.d/$REMOTE_USER.bash
#
# To set the REMOTE_USER envvar, you need to turn on PermitUserEnvironment in your sshd,
# and add `environment="REMOTE_USER=steven"` before the related key in ~/.ssh/authorized_keys

if [[ -n "$REMOTE_USER" ]]; then
	if [[ -f "$HOME/.bash_users.d/$REMOTE_USER.bash" ]]; then
		. "$HOME/.bash_users.d/$REMOTE_USER.bash"
	fi
fi
