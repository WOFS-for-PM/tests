#!/usr/bin/env bash
ABSPATH=$(cd $(dirname $0) && pwd)

cd "$ABSPATH" || exit

disk_name="pmem0"

if [ "$1" ]; then
    disk_name="$1"
fi

if [ ! -b "/dev/$disk_name" ]; then
    echo "Disk $disk_name does not exist"
    exit 1
fi

sudo rmmod "mkfs-killer.ko" > /dev/null 2>&1
sudo insmod "mkfs-killer.ko" disk_name="$disk_name"
sudo rmmod "mkfs-killer.ko"
