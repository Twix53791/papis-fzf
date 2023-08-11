#!/bin/bash
# To overwrite user config (by default ~/.config/papis-fzf)
#  run this script with '--overwrite-user-config' (or '-o') flag

PAPIS_FZF_DIR=$HOME/.papis-fzf
PAPIS_FZF_CONFIG=$HOME/.config/papis-fzf

# Check if fzf exist
if command -v fzf &> /dev/null; then
   fzfbin=$(which -a fzf | tail -1)
else
   echo "papis-fzf install ERROR :: fzf bin not found. Exit"
   exit
fi

##################################################
# Install the papis-fzf files (by default in ~/.papis-fzf)
[[ -d $PAPIS_FZF_DIR ]] && rm -r $PAPIS_FZF_DIR
mkdir $PAPIS_FZF_DIR

if cp -r * $PAPIS_FZF_DIR; then
   echo "$PAPIS_FZF_DIR created"
else
   echo "papis-fzf install ERROR :: Cannot create $PAPIS_FZF_DIR. Exit"
   exit
fi

rm $PAPIS_FZF_DIR/install.sh

##################################################
# Create/overwrite user config (by default in ~/.config/papis-fzf)
if [[ ! -d $PAPIS_FZF_CONFIG || $1 == "--overwrite-user-config" || $1 == "-o" ]]; then
   [[ -d $PAPIS_FZF_CONFIG ]] && rm -r $PAPIS_FZF_CONFIG

   mkdir $PAPIS_FZF_CONFIG
   if cp -r config/* $PAPIS_FZF_CONFIG; then
      echo "$PAPIS_FZF_CONFIG created"
   else
      echo "papis-fzf install ERROR :: Cannot create $PAPIS_FZF_CONFIG"
   fi
fi

##################################################
# Create the bin files (symlink to bin in /usr/local/bin)
# fzf-papis is just an aliases for fzf, needed by papis-fzf

# Remove existing links if they exists before
[[ -L /usr/local/bin/papis-fzf ]] && rm /usr/local/bin/papis-fzf
[[ -L /usr/local/bin/fzf-papis ]] && rm /usr/local/bin/fzf-papis

# Create links. Ask for sudo permission
if sudo ln -s $PAPIS_FZF_DIR/papis-fzf /usr/local/bin/papis-fzf; then
   echo "/usr/local/bin/papis-fzf created"
else
   echo "papis-fzf install ERROR :: Cannot create /usr/local/bin/papis-fzf"
fi

if sudo ln -s $fzfbin /usr/local/bin/fzf-papis; then
   echo "/usr/local/bin/fzf-papis created"
else
   echo "papis-fzf install ERROR :: Cannot create /usr/local/bin/fzf-papis"
fi
