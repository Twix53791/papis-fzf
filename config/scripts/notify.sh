#!/bin/bash
#===============================================
# Edit this script to custom the notification
#  command
# Enable notification in the config
#===============================================

msg=$1; shift

notify-send -t 2000 "$msg" "$1" 2> /dev/null
