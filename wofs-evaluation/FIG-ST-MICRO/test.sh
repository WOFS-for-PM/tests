#!/usr/bin/env bash

loop=1
if [ "$1" ]; then
    loop=$1
fi

bash test-various-bsize.sh "$loop"
bash test-various-fsize.sh "$loop"