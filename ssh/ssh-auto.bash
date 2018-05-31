#!/usr/bin/env bash

#TODO: think about this
#TODO: what type of syntax do I want? HOST -> ACME, or ACME -> HOSTS
#TODO: wildcards? patterns? enterprise? multi-home?
function load_config() {
	declare -A servers
	local current_host=""
	while IFS="" read -r line; do
		line="${line###}"
		case "$line" in
		"#"*) ;;
		"ACME "*)
			default_acme="${line#*ACME }"
			current_host=""
			;;
		"Host "*)
			current_host="${line#*Host }"
			;;
		*"ACME"*)
			;;
		esac
	done
}

function get_acme_cert() {
	local acme_server="$1"
	local cert_file="$2"
	ssh "$acme_server" : > "$cert_file"
	# TODO: verify that we got a certificate
}

function is_cert_valid() {
	local validity_line="$(ssh-keygen -L -f "$1" | grep -e 'Valid:' | cut -d: -f2-)"
	if [[ "$validity_line" == *forever ]]; then
		return 0
	fi
	local validity_period="$(echo "$validity_line" | awk '{print $2 ">" $4}')"
	local from="${validity_period%>*}"
	local to="${validity_period#*>}"
	local now="$(date +%FT%T)"
	echo "valid from $from until $to"
	[[ "$from" < "$now" ]] && [[ "$now" < "$to" ]]
}

# function load_config() {
# 	# TODO: either load from omnibus file (~/.ssh/configfile)
# 	# TODO: or read from file in config dir (~/.ssh/configdir/servername)
# }

# is_cert_valid "$@" && echo "cert is valid" || echo "cert is not currently valid"

load_config
echo "${servers["$1"]:-$default_acme}"
