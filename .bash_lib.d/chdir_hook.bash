
# Change directory hook
#
# When the directory is changed, this function will run the CHDIR_COMMAND environment variable
# You should assume that whatever is already in this command is fully delimited, including semicolons
function on_chdir() {
    if [ "$PWD" != "$ONCHDIR_OLDPWD" ]; then
        ONCHDIR_OLDPWD="$PWD"
        eval $CHDIR_COMMAND
    fi
}
if [[ ! "$PROMPT_COMMAND" == *"on_chdir"* ]]; then
	PROMPT_COMMAND="on_chdir${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi
