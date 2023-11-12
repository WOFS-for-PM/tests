#!/usr/bin/env bash

# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
mkdir -p "$ABS_PATH"/DATA

TOOLS_PATH=$ABS_PATH/../../tools

FILE_SYSTEMS=( "HUNTER-orig" "HUNTER-vheader" "HUNTER-J" )
BRANCHES=( "hunter-J-orig" "hunter-J-vheader" "hunter-async" )
FILE_SIZES=( $((64 * 1024)) )

TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system pattern size allocate update-meta update-dram write-data other total bandwidth(MiB/s)"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    IDX=0
    for file_system in "${FILE_SYSTEMS[@]}"; do
        branch=${BRANCHES[$IDX]}
        for fsize in "${FILE_SIZES[@]}"; do
            output="$ABS_PATH"/DATA/"$file_system"-"$fsize"

            # ANCHOR - HUNTER 
            bash "$TOOLS_PATH"/setup.sh "HUNTER-J" "${branch}" "1"
            
            BW=$(bash "$TOOLS_PATH"/fio-fsync.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)

            cat /proc/fs/HUNTER/pmem0/timing_stats > "$output"
            whole_time=$(nova_attr_time_stats "write" "$output")   
            alloc_time=$(nova_attr_time_stats "alloc_blocks" "$output")
            meta_update_time=$(nova_attr_time_stats "valid_summary_header" "$output")
            dram_update_time=$(nova_attr_time_stats "linix_set" "$output")
            data_write_time=$(nova_attr_time_stats "memcpy_write_nvmm" "$output")
        
            other_time=$((whole_time - alloc_time - meta_update_time - dram_update_time - data_write_time))
            table_add_row "$TABLE_NAME" "$file_system seq $fsize $alloc_time $meta_update_time $dram_update_time $data_write_time $other_time $whole_time $BW"
        done
        IDX=$((IDX + 1))
    done
done