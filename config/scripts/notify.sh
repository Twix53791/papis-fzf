#!/bin/bash

msg=$1; shift

[[ $1 == "error" ]] && error=("-u" "critical") && shift

for title in "$@"; do
   entries+="$title\n"
done

notify-send "${error[@]}" -t 2000 "$msg" "$entries" 2> /dev/null
