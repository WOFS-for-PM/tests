#!/usr/bin/env bash

loop=1
if [ "$1" ]; then
    loop=$1
fi

bash test-no-fsync.sh "$loop"
bash test-fsync.sh "$loop"