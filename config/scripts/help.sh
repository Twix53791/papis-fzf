#!/bin/bash
# Edit here the help messages displayed in the fzf menus
# These messages display the commands and the keybindings

# Source the config file
configdir=$HOME/.config/papis-fzf
papisfzfdir=$HOME/.papis-fzf
source $configdir/config 2>/dev/null
[[ $? != 0 ]] && source $papisfzfdir/config/config

# Color of bindings
B="\033[33m"

# Color of the text legend
T="\033[34m"

# Help messages
if [[ $1 == "main" ]]; then
   # Main fzf menu help
   echo -e "${B}enter: ${T}cite ; ${B}$main_show: ${T}show ; ${B}$main_edit: ${T}edit ; ${B}$main_tag: ${T}tag ; ${B}$main_browse: ${T}browse ; ${B}$main_export: ${T}export"
   echo -e "${B}$main_citations: ${T}show citations of the document ; ${B}$main_yank: ${T}yank ; ${B}$main_delete: ${T}delete"
   echo -e "${B}$main_searchbytags: ${T}search-by-tags ; To use complex search queries, just precede your query by 'filter:' (it use the whoosh syntax)"
   echo -e "${B}$selectall/$deselectall: ${T}select/deselect all ; ${B}$main_refresh: ${T}refresh (update the entries list)"
elif [[ $1 == "cite" ]]; then
   # Cite
   echo -e "${B}  $cite_edit: ${T}edit the citation formats"
elif [[ $1 == "searchbytags" ]]; then
   # Search-by-tags
   echo -e "${B}  enter: ${T}combine selected tags (or tags in the query if none selected) with AND operator"
   echo -e "${B}  $tags_or: ${T}combine selected tags with OR operator"
elif [[ $1 == "tag" ]]; then
   # Add/remove tags
   echo -e "${B}  $tag_remove: ${T}remove selected tags from the reference(s)"
   echo -e "${B}  $tag_query_and_add: ${T}add the query to the tags and ADD tags ; ${B}$tag_query_and_rm: ${T}add the query to the tags and REMOVE tags"
   echo -e "${B}  $selectall: ${T}select all ; ${B}$deselectall: ${T}deselect all"
elif [[ $1 == "add" ]]; then
   # Add entry (set tags menu)
   echo -e "${B}  $add_query: ${T}add the query to the list of selected tags"
   echo -e "${B}  $selectall: ${T}select all ; ${B}  $deselectall: ${T}deselect all"
elif [[ $1 == "citations" ]]; then
   # Citations menu
   echo -e "${B}  $citations_show: ${T}display the citation reference ; ${B}  $citations_browse: ${T}browse ; ${B}  $citations_cite: ${T}cite"
   echo -e "${B}  $selectall: ${T}select all ; ${B}  $deselectall: ${T}deselect all ; ${B}$main_yank: ${T}yank"
fi
