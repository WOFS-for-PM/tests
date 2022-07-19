#!/usr/bin/bash

FPATH=$1
BS=$2
SIZE=$3 # in MB
THREADS=$4

if (( "$THREADS" == 1 )); then
    sudo fio -filename="$FPATH" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs="$BS" -size="$SIZE"M -name=test
else
    sudo fio -directory="$FPATH" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs="$BS" -size="$SIZE"M -threads -numjobs="$THREADS" -name=test
fi
