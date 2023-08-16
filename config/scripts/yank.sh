#!/bin/bash
# Just yank the entries to the clipboard
# fzf run 'execute-silent($yankscript {})' on the key press
# $@ = fzf entry text
#
# Edit this script to adapt the yank command
#  to your clipboard manager

echo -en "$@" | xclip -selection clipboard
