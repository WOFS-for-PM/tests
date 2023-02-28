#!/usr/bin/sh

filesuffix() {
    filename="$1"
    if [ -n "$filename" ]; then
        echo "${filename##*.}"
    fi
}

issuffix() {
    filename="$1"
    suffix="$2"
    if [ "$(filesuffix "${filename}")" = "$suffix" ]; then
        return 0
    else
        return 1
    fi
}

cd "$1" || exit
loc=0

for file in *; do
    issuffix "${file}" "c"
    ret=$?
    if [  $ret -eq 0 ]; then
        wc -l "${file}"
        loc=$((loc + $(wc -l "${file}" | awk '{print $1}'))) 
    fi

    issuffix "${file}" "h"
    ret=$?
    if [  $ret -eq 0 ]; then
        wc -l "${file}"
        loc=$((loc + $(wc -l "${file}" | awk '{print $1}'))) 
    fi

    issuffix "${file}" "sh"
    ret=$?
    if [  $ret -eq 0 ]; then
        wc -l "${file}"
        loc=$((loc + $(wc -l "${file}" | awk '{print $1}'))) 
    fi
done

echo "LOC: "$loc

cd - || exit
