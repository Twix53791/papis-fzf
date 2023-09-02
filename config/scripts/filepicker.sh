#!/bin/bash
# NEW
# Used by export.pm
# Run an external filepicker to choose the
#  location and the name of the export file.
# Must echo a path (string)

filename=$(ranger-filepicker stdout download)

echo "$filename"
