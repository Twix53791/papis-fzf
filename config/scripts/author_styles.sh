#!/bin/bash
# Take as arguments
#  - a style name
#  - a list of pairs 'family|given'


## Structure :
# execute _main to choose the style
# execute _<style name> function
#     - each function exec a for loop through $@
# return the author_field string formatted


###### STYLES FUNCTIONS ######
# The functions names must be correspond to the style name given as argument

english-style (){
   for pair in "$@"; do
      family="${pair%|*}"
      given="${pair#*|}"

      if [[ -z $author_field ]]; then
         author_field="$family, $given"
      else
         author_field+=" and $family, $given"
      fi
   done
}

english-maj (){
   for pair in "$@"; do
      family="${pair%|*}"
      given="${pair#*|}"

      family="${family^^}"

      if [[ -z $author_field ]]; then
         author_field="$family, $given"
      else
         author_field+=" and $family, $given"
      fi
   done
}

default (){
   for pair in "$@"; do
      family="${pair%|*}"
      given="${pair#*|}"

      if [[ -z $author_field ]]; then
         author_field="$given $family"
      else
         author_field+=", $given $family"
      fi
   done
}

##############################

#######################
# Do not edit this part
#
_main (){
   style="$1"; shift

   case $style in
      *) $style "$@";;
   esac

  # Return author_field (to author.sh)
   echo "$author_field"
}
#
_main "$@"
#
