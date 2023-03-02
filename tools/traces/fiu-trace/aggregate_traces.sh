#!/usr/bin/env bash

dir=$(realpath "$1")

if [ -z "$dir" ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# list directory
rm -f "$dir/trace.syscalltrace"
for file in "$dir"/*; do    
    if [ -f "$file" ]; then
        echo "Processing $file"
        cat "$file" >> "$dir/trace.syscalltrace"
    fi 
done
