#!/usr/bin/bash

TARGET_PATH=$1
BS=$2
SIZE=$3 # in MB
THREADS=$4
FALLOCATE=$5
MODE="write"

if [ ! $THREADS ]; then
    echo "Usage: $0 <path> <block size (e.g., 4K, 4096B)> <size in MiB> <threads> [mode(read|write|randwrite|randread)]"
    exit 1
fi

if [ $6 ]; then
    MODE=$6
fi

if (( "$THREADS" == 1 )); then
    sudo fio -filename="$TARGET_PATH" -fallocate="$FALLOCATE" -direct=1 -iodepth=64 -rw="$MODE" -ioengine=io_uring -sqthread_poll=1 -bs="$BS" -size="$SIZE"M -name=test --group_reporting -runtime=60
else
    sudo fio -directory="$TARGET_PATH" -fallocate="$FALLOCATE" -direct=1 -iodepth=64 -rw="$MODE" -ioengine=io_uring -sqthread_poll=1 -bs="$BS" -size="$SIZE"M -name=test --group_reporting -thread -numjobs="$THREADS" -runtime=60
fi