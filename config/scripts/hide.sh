#!/bin/bash
##############################################
# If papis-fzf is run in a pop-up terminal window,
#  when the commands exit (letting the tasks complete in the background)
#  the terminal exit also and the tasks in the background are interrupted.
# To avoid that, the commands (add, browse...) use this script if
#  the global variable HIDE_ON_EXIT is set by the script launching papis-fzf
# $1 is the window id to hide
#
# Ex:
# Launcher script:
#   export HIDE_ON_EXIT=$$
#   kitty --name "papis-fzf" -e papis-fzf "$@"
##############################################

bspc node $1 -g hidden=on
bspc node $1 -g locked=on
