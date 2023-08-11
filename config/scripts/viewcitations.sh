#!/bin/bash
#===============================================
# This script display a selected content of the yaml files
#  of the library entries in papis-fzf.
# Edit it to custom the fields displayed.
# The yq -C output is already colored, the values set to \e[32m
# To change the color, just replace 32m by the code you want
# ex: author="${author/32m/92m}"
#===============================================

doc_folder="$1"
shift

n=0
for id in "$@"; do
   [[ ${id:0:1} == "#" ]] &&
      yamlfile="$doc_folder/info.yaml" ||
      yamlfile="$doc_folder/citations.yaml"

   [[ $n == 0 ]] && n=1
   [[ $n == 1 ]] && echo && printf %"$COLUMNS"s | tr " " "="

   title=$(yq -C "select(di == $id) | pick([\"title\"])" "$yamlfile")
   title="${title/32m/33m}"
   echo -e "$title" | fold -w 100 -s | sed 's/^/  /'
   echo

   author=$(yq -C "select(di == $id) | pick([\"author\"])" "$yamlfile")
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

   yq_fields='"journal", "volume", "issue", "month", "year", "pages", "publisher", "type", "doi", "url", "doc_url"'
   yq -C "select(di == $id) | pick([$yq_fields])" "$yamlfile" | sed 's/^/  /'
done
