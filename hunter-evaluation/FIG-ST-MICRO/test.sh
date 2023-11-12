#!/usr/bin/env bash

loop=1
if [ "$1" ]; then
    loop=$1
fi

bash test-variousio.sh "$loop"
bash test-variousio-fsync.sh "$loop"