# This file is meant to determine color display capabilities and optionally set up some handy shortcuts

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
else
    color_prompt=
fi

setup_bash_colors=
if [[ -n $setup_bash_colors ]]; then
    CSI="\033["
    COLOR_BLACK="${CSI}30m"
    COLOR_RED="${CSI}31m"
    COLOR_GREEN="${CSI}32m"
    COLOR_YELLOW="${CSI}33m"
    COLOR_BLUE="${CSI}34m"
    COLOR_PURPLE="${CSI}35m"
    COLOR_CYAN="${CSI}36m"
    COLOR_WHITE="${CSI}37m"
    COLOR_GREY="${CSI}90m"
    COLOR_LIGHT_RED="${CSI}91m"
    COLOR_LIGHT_GREEN="${CSI}92m"
    COLOR_LIGHT_YELLOW="${CSI}93m"
    COLOR_LIGHT_BLUE="${CSI}94m"
    COLOR_LIGHT_PURPLE="${CSI}95m"
    COLOR_LIGHT_CYAN="${CSI}96m"
    COLOR_LIGHT_GREY="${CSI}97m"
    COLOR_RESET="${CSI}39m"
fi
unset setup_bash_colors
