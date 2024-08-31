#!/usr/bin/env sh
if [ "$#" -ne 1 ]; then
	echo "Usage : ./command <size in MB>"
	exit 1
fi

dev=$1
sizeMB=$2
dd if="$dev" of=/mnt/ramdisk/dump.snap bs=1M count="$sizeMB"
