#!/bin/bash

function failexit {
    echo "$1"
    exit 1
}

filesdir="$1"
searchstr="$2"

[[ "$#" -ne 2 ]] && failexit "Usage: finder.sh <filesdir> <searchstr>"
[[ ! -d "$filesdir" ]] && failexit "Error: $filesdir is not a directory"

files=$(grep -r "$searchstr" "$filesdir" | cut -d: -f1 | uniq | wc -l)
lines=$(grep -r "$searchstr" "$filesdir" | wc -l)

echo "The number of files are $files and the number of matching lines are $lines"
