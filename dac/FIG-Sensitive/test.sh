#!/usr/bin/bash

# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

FILE_SYSTEMS=( "HUNTER1" "HUNTER2" "HUNTER3" "HUNTER")
INTERVALS=( 1 2 3 5 )
FILE_SIZES=( $((1 * 1024)) $((2 * 1024)) $((4 * 1024)) $((8 * 1024))
             $((16 * 1024)) $((32 * 1024)) $((64 * 1024)))


TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system file_size bandwidth(MiB/s)"

STEP=0
for file_system in "${FILE_SYSTEMS[@]}"; do
    for fsize in "${FILE_SIZES[@]}"; do
        interval=${INTERVALS[$STEP]}
        sudo umount /mnt/pmem0
        sudo mount -t HUNTER -o init,meta_local,meta_async="$interval" /dev/pmem0 /mnt/pmem0
        BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
        table_add_row "$TABLE_NAME" "$file_system $fsize $BW"
    done
    STEP=$((STEP + 1))
done