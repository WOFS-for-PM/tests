#!/usr/bin/env bash
ABSPATH=$(cd $(dirname $0) && pwd)

cd "$ABSPATH" || exit

disk_name="pmem0"

if [ "$1" ]; then
    disk_name="$1"
fi

if [ "$2" ]; then
    only_zero="$2"
else
    only_zero=0
fi

if [ ! -b "/dev/$disk_name" ]; then
    echo "Disk $disk_name does not exist"
    exit 1
fi

cd "$ABSPATH" || exit

make -j$(nproc)

sudo rmmod "mkfs-killer.ko" > /dev/null 2>&1
sudo insmod "mkfs-killer.ko" disk_name="$disk_name" only_zero="$only_zero"
sudo rmmod "mkfs-killer.ko"

cd - || exit
