#!/usr/bin/bash

ABS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
 
if [[ -z "$(mount | grep ext4 | grep pmem-mnt)" ]]; then
   sudo mkfs.ext4 "/dev/pmem0"
   sudo mount -t ext4 -o dax "/dev/pmem0" "/mnt/pmem0"
   sudo chmod 777 "/mnt/pmem0"
fi

cd "$ABS_PATH"/build || exit
make -j32
cd - || exit


