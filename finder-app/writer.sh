#!/bin/bash

set -e

function failexit {
    echo "$1"
    exit 1
}

writefile="$1"
writestr="$2"

[[ "$#" -ne 2 ]] && failexit "Usage: writer.sh <writefile> <writestr>"

touch "$writefile" || failexit "Error: could not create $writefile"
echo "$writestr" > "$writefile" || failexit "Error: could not write to $writefile"
