#!/bin/bash


#############################################
# PART TO EDIT
#  to adds fields in citations_list_style.py
#  add them first here
#   <field name>) fields[<field name>]="$value";;
#############################################
### Parse fields
# arguments: (flags) doc_folder
#  -d : debug
#  -i : enable parsing info.yaml file

_parse_citations_yaml (){
   key="${1%%:*}"
   value="${1#*: }"

   declare -g -A fields
   case $key in
      author) fields[author]="$value";;
      title) fields[title]="$value";;
      year) fields[year]="$value";;
      publisher) fields[publisher]="$value";;
      type) fields[type]="$value";;
   esac
   #echo "FIELDS ${fields[@]}"
}

_parse_info_yaml (){
   key="${1%%:*}"
   value="${1#*: }"

   declare -g -A fields
   case $key in
      author) fields[author]="$value";;
      article-title) fields[article-title]="$value";;
      series-title) fields[series-title]="$value";;
      unstructured) fields[unstructured]="$value";;
      year) fields[year]="$value";;
   esac
}


#############################################
#############################################

### Parse citations.yaml
_citations_yaml (){
   id=0
   while read line; do
      [[ $line == "---" ]] && _add cite $id && ((id++))
      [[ $line == *"  "* ]] && line="$(tr -s ' ' <<< $line)"
      _parse_citations_yaml "$line"
      ((i++))
   done < <(yq 'select(document_index == "*")' "$1")
           # Its important to use yq to get one line per key value
   _add cite $id
}

### Parse .citations from info.yaml
_info_yaml (){
   id=0
   while read line; do
      [[ ${line:0:1} == "-" && -n ${fields[@]} ]] && _add info $id && ((id++))
      [[ ${line:0:1} == "-" ]]  && line="${line:2}"
      [[ $line == *"  "* ]] && line="$(tr -s ' ' <<< $line)"
      _parse_info_yaml "$line"
   done < <(yq ".citations" "$1")
   _add info
}

# Create a string, which will be interpreted in python as a dictionnay
_add (){
   [[ $debug == 1 ]] && echo "---"
   [[ ${#fields[@]} -le 1 ]] && unset fields && return

   pairs=""
   for key in "${!fields[@]}"; do
      kvalue="${fields[$key]}"
      [[ ${kvalue:0:1} == "'" ]] && kvalue="${kvalue:1}"
      [[ ${kvalue: -1} == "'" ]] && kvalue="${kvalue:0:-1}"
      [[ ${kvalue:0:1} == '"' ]] && kvalue="${kvalue:1}"
      [[ ${kvalue: -1} == '"' ]] && kvalue="${kvalue:0:-1}"

      # If parsing info.yaml, check for duplicates
      keys_tochk="article-title series-title title"
      if [[ $1 == "info" && $keys_tochk == *"$key"* ]]; then
         tochk="\"${kvalue}\""
         chk=$(_check_duplicates "$tochk")
      fi

      [[ $chk == 1 ]] && unset fields && return

      [[ -n $kvalue ]] &&
         pairs+="\"$key\": \"$kvalue\", "

      [[ $debug == 1 ]] && echo "$key | ${fields[$key]}"
   done

   unset fields

   [[ $1 == "info" ]] &&
      pairs="${pairs}\"id\": \"#$id\"" ||
      pairs="${pairs}\"id\": \"$id\""

   dictionnary="{$pairs}"
   [[ $debug == 1 ]] && echo "$dictionnary"

   d_list+="$dictionnary,"
}

# Take a key_value as argument
# Try to find it in d_list
_check_duplicates (){
   if [[ ${d_list,,} == *"${1,,}"* ]]; then
      echo 1
   fi
}

_main (){
   [[ $1 == "-d" ]] && debug=1 && shift
   [[ $1 == "-i" ]] && info=1 && shift
   [[ ! -d $1 ]] && echo "citations.sh ERROR ::  Missing papis-folder id." && exit

   cfile="$1/citations.yaml"
   ifile="$1/info.yaml"

   [[ -f $cfile ]] && _citations_yaml "$cfile"
   [[ -f $ifile && $info == 1 ]] && _info_yaml "$ifile"

   pyscript="/home/archx/.config/papis-fzf/scripts/citations_list_style.py"
   d_list="${d_list%,}"
   output=$($pyscript "[$d_list]")

   echo -en "$output"
}

_main "$@"
