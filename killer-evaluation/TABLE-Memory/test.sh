#!/usr/bin/env bash

loop=1
if [ "$1" ]; then
    loop=$1
fi

bash test-fileserver.sh "$loop"
bash test-ycsb.sh "$loop"