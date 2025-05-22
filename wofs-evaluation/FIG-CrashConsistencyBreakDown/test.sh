#!/usr/bin/env bash

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    bash meta-fio.sh 1
    bash meta-filebench.sh 1
done