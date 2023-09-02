# This script build the indexes files
# index, index-raw, and index-colored
# By default in ~/.cache/papis-fzf
# Run by buildindexes.pm

import os
import sys
import papis.document
import papis.database.whoosh


# Gets working directories
indexdir = sys.argv[1]
configpy = sys.argv[2]

# Sets file locations
idx = indexdir + "/index"
idxraw = indexdir + "/index-raw"
idxcolor = indexdir + "/index-colored"

## Gets config
index_fields = eval(sys.argv[3])
fzf_fields = eval(sys.argv[4])
fzf_colors = eval(sys.argv[5])

# Open the class Database, get the whoosh index
db = papis.database.whoosh.Database()
ix = db.get_index()


def main():
    # If a list of papis-folder is given, update them
    papisFolders = sys.argv[6:]

    # If not, rebuild the indexes (writemode to write)
    writemode = "a" if papisFolders else "w"

    # Get all or matching arguments documents from database
    # OR get the documents from --doc-folder (papisFolders)
    # documents: [(Document object, papis-folder), ...]
    with ix.searcher() as searcher:
        all_docs = searcher.documents()
        documents = []

        for d in all_docs:
            folder = d.get("papis-folder")
            if not papisFolders or folder in papisFolders:
                doc = (papis.document.from_folder(folder), folder)
                documents.append(doc)

        if documents:
            update_indexes(documents, writemode)


# documents: list of tuples : [(doc, folder), ...].
#  doc: a <class 'papis.document.Document'> object containing the fields values
# folder: <$HOME/papislibrary/papis-folder>
def update_indexes(documents, writemode):
    with open(idx, writemode) as idxfile, open(idxraw, writemode) as idxrwfile, open(idxcolor, writemode) as idxclfile:
        watch_duplicates = []

        for doc, folder in documents:
            # Special format for tags
            try:
                tags = [t for t in doc["tags"].split()]
            except Exception:
                tags = ""

            # Index string (main index file)
            for i, field in enumerate(index_fields):
                if i == 0:
                    idxStr = str(doc[field])
                elif field == "tags":
                    if tags:
                        idxStr = idxStr + "|TAGS:" + " ".join(tags)
                    else:
                        idxStr = idxStr + "|"
                else:
                    idxStr = idxStr + "|" + str(doc[field])
            idxStr = idxStr + "|" + folder

            # Index-raw string && indx-colored string (fzf menu)
            idxrawStr, idxcolorStr = [""]*2
            for i, field in enumerate(fzf_fields):
                if field == "tags" and tags:
                    idxrawStr = idxrawStr + " ".join(tags) + " "
                    idxcolorStr = idxcolorStr + fzf_colors[i] + " ".join(tags) + " "
                elif doc[field]:
                    idxrawStr = idxrawStr + str(doc[field]) + " "
                    idxcolorStr = idxcolorStr + fzf_colors[i] + str(doc[field]) + " "

            # Raw strings
            idxrawStr = idxrawStr.rstrip()
            idxcolorStr = idxcolorStr.rstrip()

            # Avoiding duplicates
            raw_duplicates = str(sum(s == idxrawStr for s in watch_duplicates))

            watch_duplicates.append(idxrawStr)

            if not raw_duplicates == "0":
                idxrawStr = idxrawStr + " " + "#" + raw_duplicates
                idxcolorStr = idxcolorStr + " \033[30m" + "#" + raw_duplicates

            #### Write the files ####
            idxfile.write(idxStr + "\n")
            idxrwfile.write(idxrawStr + "\n")
            idxclfile.write(idxcolorStr + "\n")

            # NOTE: update_indexes just write the entries it matched
            #  To 'update' selected entries in the database (and not all
            #  the time rewriting the entire files, the 'build-indexes'
            #  papis-fzf command delete the entries to be updated before

#######################
# Run the main function
main()
