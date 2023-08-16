# This script build the indexes files
# index, index-raw, and index-colored
# By default in ~/.cache/papis-fzf

import os
import sys
import papis.document
import papis.database.whoosh


# Set files location
try:
    indexdir = os.environ["FZF_PAPIS_INDEXDIR"]
    configpy = os.environ["FZF_PAPIS_CONFIGPY"]
except:
    indexdir = os.path.expanduser("~") + "/.cache/papis-fzf"
    configpy = "/tmp/papis-fzf"

# Set the filenames
idx = indexdir + "/index"
idxraw = indexdir + "/index-raw"
idxcolor = indexdir + "/index-colored"

# Import config variables from /tmp/papis-fzf/config.py
sys.path.append(os.path.expanduser(configpy))
from config import *

# Open the class Database, get the whoosh index
db = papis.database.whoosh.Database()
ix = db.get_index()


def main():
    # If a list of papis-folder is given, update them
    papisFolders = sys.argv[1:]

    # If not, rebuild the indexes (writemode to write)
    writemode = "a" if papisFolders else "w"

    # Get all or matching arguments documents from database
    # OR get the documents from --doc-folder (papisFolders)
    with ix.searcher() as searcher:
        all_docs = searcher.documents()
        # documents: [(Document object, papis-folder), ...]
        documents = []

        for d in all_docs:
            folder = d.get("papis-folder")
            if not papisFolders or folder in papisFolders:
                doc = (papis.document.from_folder(folder), folder)
                documents.append(doc)

        if documents:
            update_indexes(documents, writemode)

# NOTE: this way using papis.document.from_folder(folder) is the safest way
# It recovers the true yaml fields even if the database doesn't get updated yet
# It is only 10% slower than the alternative way below

# OTHER POSSIBLE WAY
#from whoosh.qparser import QueryParser

#    if papisFolders:
#        with ix.searcher() as searcher:
#            results = []
#            for folder in papisFolders:
#                query = QueryParser("papis-folder", ix.schema).parse('"' + folder + '"')
#                entry = searcher.search(query)
#                if entry:
#                    results.append(entry[0])
#            if results:
#                update_indexes(results, "a")


# documents: list of tuples : [(doc, folder), ...].
#  doc: a <class 'papis.document.Document'> object containing the fields values
# folder: <$HOME/papislibrary/papis-folder>
def update_indexes(documents, writemode):
    with open(idx, writemode) as idxfile, open(idxraw, writemode) as idxrwfile, open(idxcolor, writemode) as idxclfile:
        watch_duplicates = []

        for doc, folder in documents:

            # Special format for tags
            tags = ["tag:" + t for t in doc["tags"].split()]

            # Index string (main index file)
            for i, field in enumerate(index_fields):
                if i == 0:
                    idxStr = str(doc[field])
                elif field == "tags":
                    idxStr = idxStr + "|" + ": ".join(tags) + ":"
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
