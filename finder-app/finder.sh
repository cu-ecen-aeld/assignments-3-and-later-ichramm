#!/bin/sh

##
# Note: Had to change the shebang to #!/bin/sh because #!/bin/bash is not available on the target rootfs

failexit() {
    echo "$1"
    exit 1
}

filesdir="$1"
searchstr="$2"

if [ "$#" -ne 2 ]; then
    failexit "Usage: finder.sh <filesdir> <searchstr>"
fi

if [ ! -d "$filesdir" ]; then
    failexit "Error: $filesdir is not a directory"
fi

files=$(find "$filesdir" -type f | wc -l)
lines=$(grep -r "$searchstr" "$filesdir" | wc -l)

echo "The number of files are $files and the number of matching lines are $lines"
