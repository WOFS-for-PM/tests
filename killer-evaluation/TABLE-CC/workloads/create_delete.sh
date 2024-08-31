#!/usr/bin/env bash

# NOTE: from crash_monkey/code/tests/create_delete.c (https://github.com/utsaslab/crashmonkey.git)

NUM_FILES=10

mkdir /mnt/pmem0/test_dir

for i in $(seq 1 $NUM_FILES)
do
    touch /mnt/pmem0/test_dir/test_file$i
    dd if=/dev/zero of=/mnt/pmem0/test_dir/test_file$i bs=1024B count=1
done

for i in $(seq 1 $NUM_FILES)
do
    rm /mnt/pmem0/test_dir/test_file$i
done
