#!/usr/bin/env sh
if [ "$#" -ne 3 ]; then
	echo "Usage : ./command <device> <size in MB> <target>"
	exit 1
fi

dev=$1
sizeMB=$2
target=$3

dd if="$dev" of=$target bs=1M count="$sizeMB"
