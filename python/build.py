# This script build the indexes files
# index, index-raw, and index-colored
# By default in ~/.cache/papis-fzf

import os
import sys
import papis.database.whoosh
from whoosh.qparser import QueryParser

db = papis.database.whoosh.Database()
ix = db.get_index()

# Set files location
try:
    indexdir = os.environ["FZF_PAPIS_INDEXDIR"]
    configpy = os.environ["FZF_PAPIS_CONFIGPY"]
except:
    indexdir = "/home/archx/.cache/papis-fzf"
    configpy = "/tmp/papis-fzf"
#    quit()

# Set the filenames
idx = indexdir + '/index'
idxraw = indexdir + '/index-raw'
idxcolor = indexdir + '/index-colored'

# Import config variables from /tmp/papis-fzf/config.py
sys.path.append(os.path.expanduser(configpy))
from config import *


def main():
    # If a list of papis-folder is given, update them
    papisFolders = sys.argv[1:]

    if papisFolders:
        with ix.searcher() as searcher:
            results = []
            for folder in papisFolders:
                query = QueryParser("papis-folder", ix.schema).parse('"' + folder + '"')
                entry = searcher.search(query)
                if entry:
                    results.append(entry[0])
            if results:
                update_indexes(results, 'a')

    # If not, (re)build the indexes
    else:
        with ix.searcher() as searcher:
            results = searcher.documents()
            if results:
                update_indexes(results, 'w')


def update_indexes(results, writemode):
    with open(idx, writemode) as idxfile, open(idxraw, writemode) as idxrwfile, open(idxcolor, writemode) as idxclfile:
        for hit in results:
            with open('/tmp/tata', 'a') as t:
                t.write(str(hit) + '\n')
            # Special format for tags
            tags = ['tag:' + t for t in hit['tags'].split()]

            # Index string (main index file)
            for i, field in enumerate(index_fields):
                if i == 0:
                    idxStr = hit[field]
                elif field == 'tags':
                    idxStr = idxStr + '|' + ': '.join(tags) + ':'
                else:
                    idxStr = idxStr + '|' + hit[field]
            idxStr = idxStr + '|' + hit['papis-folder'] + '\n'

            # Index-raw string && indx-colored string (fzf menu)
            idxrawStr, idxcolorStr = [""]*2
            for i, field in enumerate(fzf_fields):
                if field == 'tags':
                    idxrawStr = idxrawStr + ' '.join(tags) + ' '
                    idxcolorStr = idxcolorStr + fzf_colors[i] + ' '.join(tags) + ' '
                else:
                    idxrawStr = idxrawStr + hit[field] + ' '
                    idxcolorStr = idxcolorStr + fzf_colors[i] + hit[field] + ' '
            idxrawStr = idxrawStr.rstrip() + '\n'
            idxcolorStr = idxcolorStr.rstrip() + '\n'

            with open('/tmp/tutu', 'a') as t:
                t.write(idxStr + '\n')
            #### Write the files ####
            idxfile.write(idxStr)
            idxrwfile.write(idxrawStr)
            idxclfile.write(idxcolorStr)

#######################
main()
