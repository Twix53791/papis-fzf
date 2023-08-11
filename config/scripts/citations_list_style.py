#!/usr/bin/env python3

import sys
import ast

# Edit this function to change the fields displayed in the papis-fzf menu
# To be added here, a field MUST be stored in the whoosh papis database
# Set the fields stored in the database in the papis config file
#  by editing the value 'whoosh-schema-fields'
# Format:
# entry = entry + <color> + hit['<fiedname>']

#def setentry(dictArray):
dictArray = ast.literal_eval(sys.argv[1])
entries = []

for item in dictArray:
    entry = ''

  ### PART TO EDIT ###
    try:
        entry = entry + '\033[33m' + item['article-title'] + ' '
    except:
        pass

    try:
        entry = entry + '\033[33m' + item['title'] + ' '
    except:
        pass

    try:
        entry = entry + '\033[33m' + item['series-title'] + ' '
    except:
        pass

    try:
        entry = entry + '\033[91m' + item['unstructured'] + ' '
    except:
        pass

    try:
        entry = entry + '\033[32m' + item['author'] + ' '
    except:
        pass

    try:
        entry = entry + '\033[34m' + item['year'] + ' '
    except:
        pass

    try:
        entry = entry + '\033[36m' + item['publisher'] + ' '
    except:
        pass

    try:
        entry = entry + '\033[94m' + item['doi'] + ' '
    except:
        pass

    try:
        entry = entry + '\033[94m' + item['url'] + ' '
    except:
        pass

    ###################################################

    # The id is needed to retrieve the yaml section of the citation
    entry = entry + '\033[30m ' + item['id'] + '\033[0m'
    entries.append(entry)

if entries:
    print(*entries,sep='\n')
    # To pass the colors in the fzf preview :
    with open("/tmp/papis-fzf/papis-fzf-citations-preview", "w") as f:
        for line in entries:
            f.write(f"{line}\n")
