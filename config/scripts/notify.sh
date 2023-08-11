#!/bin/bash

msg=$1; shift

notify-send -t 2000 "$msg" "$1" 2> /dev/null
