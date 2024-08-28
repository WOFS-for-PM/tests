#!/usr/bin/env bash

abs_path=$(cd $(dirname $0) && pwd)

profile=$1
if [ -z "$profile" ]; then
    profile="agrawal"
fi

partition_size=$((256 * 1024 * 1024 * 1024))

strace -f "$abs_path"/build/geriatrix -n $partition_size -u 0.75 -r 42 -m /mnt/pmem0 -a "$abs_path"/profiles/agrawal/age_distribution.txt -s "$abs_path"/profiles/agrawal/size_distribution.txt -d "$abs_path"/profiles/agrawal/dir_distribution.txt -x /tmp/age.out -y /tmp/size.out -z /tmp/dir.out -t 1 -i 1 -f 0 -p 0 -c 0 -q 0 -w 1 -b posix