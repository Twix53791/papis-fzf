#!/bin/bash
#===============================================
# Problem : if the script close, the access to the content copied if lost
# So it paste straight away : xte 'keydown Control_L' 'key v' 'keyup Control_L'
# A small sleep is needed after xte command
# $1 = 1 if format name contains the $richtext string set in the config file
#===============================================

tocite="$2"

if [[ $1 == 1 ]]; then
   tocite="${tocite}"
   echo -en "$tocite" | pandoc -f markdown+smart | xclip -t text/html -selection clipboard
   window=$(bspc query -N -n focused)
   #bspc node $window -g hidden=on
   #bspc node $window -g locked=on
   xte 'keydown Control_L' 'key v' 'keyup Control_L'
   sleep .5
else
   echo -en "$tocite" | xclip -selection clipboard
   #bspc node $window -g hidden=on
   #bspc node $window -g locked=on
   xte 'keydown Control_L' 'key v' 'keyup Control_L'
   sleep .5
fi
