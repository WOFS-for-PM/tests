#!/usr/bin/env bash
ABS_PATH=$(cd "$( dirname "$0" )" && pwd)

disk_name="pmem0"

if [ "$1" ]; then
    disk_name="$1"
fi

if [ ! -b "/dev/$disk_name" ]; then
    echo "Disk $disk_name does not exist"
    exit 1
fi

cd "$ABS_PATH" || exit

make -j32 > /dev/null


sudo rmmod "$ABS_PATH"/pm_range_detect.ko
sudo insmod "$ABS_PATH"/pm_range_detect.ko disk_name="$disk_name" > /dev/null

dmesg | tail -2 > output 
virt_start=$(cat output | grep "pm_range_detect: get_nvmm_info: dev $disk_name" | sed 's/\[ /\[/' | awk '{print $9}')
virt_end=$(cat output | grep "pm_range_detect: get_nvmm_info: dev $disk_name" | sed 's/\[ /\[/' | awk '{print $11}' | sed 's/,//')
echo "Range for $disk_name:"
echo "Virtual Memory Start: $virt_start"
echo "Virtual Memory End: $virt_end"
rm output
