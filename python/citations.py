import os
import sys
import json

# Set files location
try:
    tmpdir = os.environ["FZF_PAPIS_CONFIGPY"]
except:
    tmpdir = "/tmp/papis-fzf"

# Set the filenames
cttinput = tmpdir + "/tmp-citations-input"
cttraw = tmpdir + "/tmp-index-citations-raw"
cttcolor = tmpdir + "/tmp-index-citations-colored"
cttiraw = tmpdir + "/tmp-index-citations-info-raw"
ctticolor = tmpdir + "/tmp-index-citations-info-colored"

# This file will store the title key for each citation
# When info_index will be run, if a same title is found,
#  it will skip the info.yaml entry, trying to eliminate duplicates
duplicates = tmpdir + "/tmp-citations-watch-duplicates"


# Import config variables from /tmp/papis-fzf/config.py
sys.path.append(os.path.expanduser(tmpdir))
from config import *


def init():
    # Action
    action = sys.argv[1]

    if action == "citations":
        citations_index()

    elif action == "info":
        info_index()


def citations_index():
    # Get the input to parse (in json format from yq)
    with open(cttinput, "r") as jsonfile:
        jsonList = json.load(jsonfile)

    with open(cttraw, "a") as rawfile, open(cttcolor, "a") as colorfile, open(duplicates, "w") as dp:
        for citation in jsonList:
            cttStr, cttcolorStr = [""]*2

            # Indexes for citations.yaml
            for i, field in enumerate(citations_fields):
                try:
                    # Store title for info_index
                    if field == "title":
                        dp.write(citation[field] + "\n")

                    cttStr = cttStr + str(citation[field]) + " "
                    cttcolorStr = cttcolorStr + citations_colors[i] + str(citation[field]) + " "
                except Exception:
                    # If the key doesn't exists
                    pass

            # Write the indexes files
            rawfile.write(cttStr + "\n")
            colorfile.write(cttcolorStr.rstrip() + "\n")


def info_index():
    with open(cttinput, "r") as jsonfile:
        jsonList = json.load(jsonfile)

    # The fields to check in duplicates
    watch_duplicates = ["article-title", "series-title", "title"]

    # A list built from duplicates (writed by citations_index)
    with open(duplicates) as dp:
        titles_list = dp.read().splitlines()

    # Note: the files are cleared by the papis-fzf citations
    #  command, so we can use append here
    with open(cttiraw, "a") as rawfile, open(ctticolor, "a") as colorfile:
        for citation in jsonList:
            cttiStr, ctticolorStr = [""]*2

            for i, field in enumerate(citations_info_fields):
                try:
                    # If the title is found in titles_list,
                    #  its a duplicate of an entry from citations.yaml. Skip it
                    # BUT write 'null' in files to not disturb the nth of entries...
                    if field in watch_duplicates:
                        if citation[field] in titles_list:
                            cttiStr = ctticolorStr = "null"
                            break

                    cttiStr = cttiStr + str(citation[field]) + " "
                    ctticolorStr = ctticolorStr + citations_colors[i] + str(citation[field]) + " "

                except Exception:
                    # If the key doesn't exists
                    pass

            rawfile.write(cttiStr + "\n")
            colorfile.write(ctticolorStr.rstrip() + "\n")


#########################
init()
