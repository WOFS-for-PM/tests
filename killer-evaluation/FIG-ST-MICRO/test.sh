#!/usr/bin/env bash

loop=1
if [ "$1" ]; then
    loop=$1
fi

bash test-small.sh "$loop"
bash test-large.sh "$loop"