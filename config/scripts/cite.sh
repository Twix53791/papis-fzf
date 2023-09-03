#!/bin/bash

# Problem : if the script close, the access to the content copied if lost
# So it paste straight away : xte 'keydown Control_L' 'key v' 'keyup Control_L'
# A small sleep is needed after xte command
# $1 = 1 if format name contains the $richtext string set in the config file

mode="$1"
tocite="$2"

if [[ $mode == "rich" ]]; then
   tocite="${tocite}"
   cat "$tocite" | pandoc -f markdown+smart | xclip -t text/html -selection clipboard
else
   cat "$tocite" | xclip -selection clipboard
fi
