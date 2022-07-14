#!/usr/bin/bash

fs_src_path=$1
tracer=$2

if [ ! "${tracer}" ]; then
    echo "Tracer is off"  
else
    if [[ "${tracer}" != "trace" ]]; then
        echo "An exmple of trace: ./trace.sh ./simfs trace"
        exit
    else 
        echo "Tracer is on"
    fi
fi

cd "$fs_src_path" || exit
sudo dmesg -C
sudo bash setup.sh "$2"
echo 32768 | sudo tee /sys/kernel/tracing/buffer_size_kb
echo | sudo tee /sys/kernel/tracing/trace
sudo fio -filename=/mnt/pmem1/test -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs=4K -size=128M -name=write
sudo cat /sys/kernel/tracing/trace > pattern
sudo umount /mnt/pmem1/
dmesg | tail -n 50

cd - || exit
