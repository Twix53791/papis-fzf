#!/bin/bash
#====================================
# Run author_styles.sh as child
# Take a yaml file as argument $1
# The author_styles.sh location as $2
# And a style name as $3
#====================================

[[ ! -f $1 || ! $1 =~ \.yaml$ ]] && exit
styles_script="$2"
style_name="$3"

## Structure:
#   - check if author and author_list fields correspond to each other
#   - if author_list missing authors from author, update it
#   - from author_list, build a list of authors 'family|given'
#   - send this list to author_styles.sh which will format the text of the field

_main (){
   _fix_missing_authors "$1"

   [[ -z $2 || -z $3 ]] && exit

   _format_author_field "$1"
   newvalue=$($styles_script "$style_name" "${all[@]}")
   echo "TOTO $newvalue"

#   yq -i ".author = \"$newvalue\"" "$1"
}

_fix_missing_authors (){
   author=$(yq '.author' "$1")
   author="${author// and /|}"
   author="${author//, /,}"

   # Grab the list of family names in .author and .author_list
   author_list_family=$(yq ".author_list[] | pick([\"family\"]) | .family" "$1")

   while read line; do
      family_list+=("$line")
   done < <(grep -oP '(?<=^|\|).*?(?=,)' <<< $author)

   while read line; do
      given_list+=("$line")
   done < <(grep -oP '(?<=,).*?(?=\||$)' <<< $author)

   # Set the values to add (couples "family|given")
   i=0
   for family in "${family_list[@]}"; do
      if [[ $author_list_family != *"$family"* ]]; then
         toadd+=("$family|${given_list[$i]}")
      fi
      ((i++))
   done

   # Add the new author_list values
   for pair in "${toadd[@]}"; do
      F="${pair%|*}"
      G="${pair#*|}"

      yq -i ".author_list += {\"affiliation\": []}" "$1"
      yq -i ".author_list[-1] += {\"family\": \"$F\"}" "$1"
      yq -i ".author_list[-1] += {\"given\": \"$G\"}" "$1"
   done
}

_format_author_field (){
   while read line; do
      all_family+=("$line")
   done < <(yq ".author_list[] | pick([\"family\"]) | .family" "$1")

   while read line; do
      all_given+=("$line")
   done < <(yq ".author_list[] | pick([\"given\"]) | .given" "$1")

   for i in $(seq 1 "${#all_family[@]}"); do
      n=$(($i - 1))
      all+=("${all_family[$n]}|${all_given[$n]}")
   done
}


# Run _main
_main "$@"
