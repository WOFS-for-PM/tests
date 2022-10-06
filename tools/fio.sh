#!/usr/bin/bash

PATH=$1
BS=$2
SIZE=$3 # in MB
THREADS=$4

if [ ! $THREADS ]; then
    echo "Usage: $0 <path> <block size (e.g., 4K, 4096B)> <size in MiB> <threads>"
fi

if (( "$THREADS" == 1 )); then
    sudo fio -filename="$PATH" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs="$BS" -size="$SIZE"M -name=test
else
    sudo fio -directory="$PATH" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs="$BS" -size="$SIZE"M -threads -numjobs="$THREADS" -name=test
fi
