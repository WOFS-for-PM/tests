#!/usr/bin/bash

script_dir=$(cd "$(dirname "$0")" || exit;pwd)
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

git checkout meta-trace 
sudo bash setup.sh /dev/pmem1 /mnt/pmem1 "$tracer" 1

echo 32768 | sudo tee /sys/kernel/tracing/buffer_size_kb
echo | sudo tee /sys/kernel/tracing/trace

sudo bash "$script_dir"/../tools/fio.sh "/mnt/pmem1/test" "4K" "128" "1"

sudo cat /sys/kernel/tracing/trace > "$fs_src_path"/pattern
mkdir -p "$script_dir"/meta-traces
sudo cat /sys/kernel/tracing/trace > "$script_dir"/meta-traces/pattern-"$(basename "$fs_src_path")"

sudo cat /proc/fs/NOVA/pmem1/timing_stats
sudo umount /mnt/pmem1/

dmesg | tail -n 50

cd - || exit
