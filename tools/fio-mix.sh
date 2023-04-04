#!/usr/bin/bash

TARGET_PATH=$1
BS=$2
SIZE=$3 # in MB
THREADS=$4
RD_RATIO=$5

if [ ! "$THREADS" ]; then
    echo "Usage: $0 <path> <block size (e.g., 4K, 4096B)> <size in MiB> <threads> <read ratio>"
    exit 1
fi

if (( "$THREADS" == 1 )); then
    sudo fio -filename="$TARGET_PATH" -fallocate=none -direct=0 -iodepth 1 -rw="rw" -ioengine=sync -bs="$BS" -size="$SIZE"M -rwmixread="$RD_RATIO" -name=test
else
    sudo fio -directory="$TARGET_PATH" -fallocate=none -direct=0 -iodepth 1 -rw="rw" -ioengine=sync -bs="$BS" -size="$SIZE"M -thread -numjobs="$THREADS" -rwmixread="$RD_RATIO" -name=test
fi
