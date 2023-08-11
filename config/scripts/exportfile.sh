#!/bin/bash
#===============================================
# When export library references to bibtext/json/yaml file
# Set the filename/dirname with this script
#===============================================

ranger_config="$HOME/.config/ranger-savefileas"
kitty --name "ranger-dwl-filepicker" -o font_family=Iosevka-Term-Extended -o background_opacity=0.9 -e ranger -r "$ranger_config" 2>/dev/null

ranger_output="/tmp/qute-ranger-dwl-filepicker"

echo "$(tail -1 $ranger_output)"
