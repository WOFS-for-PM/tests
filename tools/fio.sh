#!/usr/bin/bash

TARGET_PATH=$1
BS=$2
SIZE=$3 # in MB
THREADS=$4
MODE="write"

if [ ! $THREADS ]; then
    echo "Usage: $0 <path> <block size (e.g., 4K, 4096B)> <size in MiB> <threads> [mode(read|write|randwrite|randread)]"
    exit 1
fi

if [ $5 ]; then
    MODE=$5
fi

if (( "$THREADS" == 1 )); then
    sudo fio -filename="$TARGET_PATH" -fallocate=none -direct=0 -iodepth 1 -rw="$MODE" -ioengine=sync -bs="$BS" -size="$SIZE"M -name=test
else
    sudo fio -directory="$TARGET_PATH" -fallocate=none -direct=0 -iodepth 1 -rw="$MODE" -ioengine=sync -bs="$BS" -size="$SIZE"M -thread -numjobs="$THREADS" -name=test
fi
