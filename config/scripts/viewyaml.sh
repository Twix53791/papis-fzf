#!/bin/bash
#===============================================
# This script display a selected content of the yaml files
#  of the library entries in papis-fzf.
# Edit it to custom the fields displayed.
#===============================================

tput reset

for yml in "$@"; do
   yml="${yml}/info.yaml"

   [[ -n $title ]] && echo && printf %"$COLUMNS"s | tr " " "="

   title=$(yq -C "pick([\"title\"])" "$yml")
   title="${title/32m/33m}"
   # Fold : go to line if text larger than x characters
   # sed 's/^/  /' (or sed -r 's/^(.*)/  \1/g' ) : add spaces at the beggining of each line (indent)
   echo -e "$title" | fold -w 100 -s | sed 's/^/  /'
   echo

   author=$(yq -C "pick([\"author\"])" "$yml")
   author="${author/32m/92m}"
   len=${#author}
   while [[ $len -gt 90 ]]; do
      line1="${author:0:90}"
      line1="${line1%,*},"
      echo "  $line1"
      author="${author/$line1 /}"
      len=${#author}
   done
   [[ -n $author ]] && echo -e "$author" | sed 's/^/  /'
   echo

   abstract=$(yq -C "pick([\"abstract\"])" "$yml")
   echo -e "$abstract" | fold -w 100 -s | sed 's/^/  /'
   echo

   yq_fields='"journal", "volume", "issue",  "month", "year", "pages", "publisher", "type", "doi", "url", "files"'
   yq -C "pick([$yq_fields])" "$yml" | sed 's/^/  /'

   tgs=$(yq -C "pick([\"tags\"])" "$yml")
   tgs="${tgs/32m/95m}"
   echo -e "$tgs" | sed 's/^/  /'
done
