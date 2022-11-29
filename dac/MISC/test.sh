#!/usr/bin/bash

# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

FILE_SYSTEMS=( "HUNTER")
# FILE_SYSTEMS=( "HUNTER-ASYNC-3s" "HUNTER" "HUNTER-ASYNC-INFTY")
FILE_SIZES=( $((64 * 1024)) )


TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system file_size memory(MiB)"

STEP=0
for file_system in "${FILE_SYSTEMS[@]}"; do
    for fsize in "${FILE_SIZES[@]}"; do
        bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
        MEM_BEFORE=$(free -m | grep Mem | awk '{print $3}')
        _=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
        MEM_AFTER=$(free -m | grep Mem | awk '{print $3}')
        table_add_row "$TABLE_NAME" "$file_system $fsize $((MEM_AFTER - MEM_BEFORE))"
    done
    STEP=$((STEP + 1))
done