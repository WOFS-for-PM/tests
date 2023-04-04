#!/usr/bin/env bash

# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
mkdir -p "$ABS_PATH"/DATA

TOOLS_PATH=$ABS_PATH/../../tools


FILE_SYSTEMS=( "NOVA-RELAX" "NOVA" "PMFS" "HUNTER")
FILE_SIZES=( $((1 * 1024)) $((64 * 1024)))
WORK_LOADS=( "seq" "rand" )

TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system pattern size allocate update-meta update-dram write-data other total bandwidth(MiB/s)"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for file_system in "${FILE_SYSTEMS[@]}"; do
    for work_load in "${WORK_LOADS[@]}"; do
        for fsize in "${FILE_SIZES[@]}"; do
            output="$ABS_PATH"/DATA/"$file_system"-"$work_load"-"$fsize"
            # ANCHOR - HUNTER 
            if [[ "${file_system}" == "HUNTER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "HUNTER" "dac" "1"
                if [[ "${work_load}" == "seq" ]]; then
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${work_load}" == "rand" ]]; then
                    BW=$(bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                cat /proc/fs/HUNTER/pmem0/timing_stats > "$output"
                whole_time=$(nova_attr_time_stats "write" "$output")   
                alloc_time=$(nova_attr_time_stats "new_data_blocks" "$output")
                meta_update_time=$(nova_attr_time_stats "valid_summary_header" "$output")
                dram_update_time=$(nova_attr_time_stats "linix_set" "$output")
                data_write_time=$(nova_attr_time_stats "memcpy_write_nvmm" "$output")
            # ANCHOR - NOVA-RELAX
            elif [[ "${file_system}" == "NOVA-RELAX" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "1"
                if [[ "${work_load}" == "seq" ]]; then
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${work_load}" == "rand" ]]; then
                    _=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                    BW=$(bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                cat /proc/fs/NOVA/pmem0/timing_stats > "$output"
                whole_time=$(nova_attr_time_stats "inplace_write" "$output")   
                alloc_time=$(nova_attr_time_stats "new_data_blocks" "$output")
                append_fentry_time=$(nova_attr_time_stats "append_file_entry" "$output")
                update_tail_time=$(nova_attr_time_stats "update_tail" "$output")
                meta_update_time=$((append_fentry_time + update_tail_time))
                dram_update_time=$(nova_attr_time_stats "assign_blocks" "$output")
                data_write_time=$(nova_attr_time_stats "memcpy_write_nvmm" "$output")
            # ANCHOR - NOVA 
            elif [[ "${file_system}" == "NOVA" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "1"
                if [[ "${work_load}" == "seq" ]]; then
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${work_load}" == "rand" ]]; then
                    _=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                    BW=$(bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                cat /proc/fs/NOVA/pmem0/timing_stats > "$output"
                whole_time=$(nova_attr_time_stats "cow_write" "$output")   
                alloc_time=$(nova_attr_time_stats "new_data_blocks" "$output")
                append_fentry_time=$(nova_attr_time_stats "append_file_entry" "$output")
                update_tail_time=$(nova_attr_time_stats "update_tail" "$output")
                meta_update_time=$((append_fentry_time + update_tail_time))
                dram_update_time=$(nova_attr_time_stats "assign_blocks" "$output")
                data_write_time=$(nova_attr_time_stats "memcpy_write_nvmm" "$output")
            # ANCHOR - PMFS 
            elif [[ "${file_system}" == "PMFS" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "1"
                if [[ "${work_load}" == "seq" ]]; then
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${work_load}" == "rand" ]]; then
                    _=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                    BW=$(bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                umount /mnt/pmem0
                dmesg | tail -n 24 > "$output"
                whole_time=$(pmfs_attr_time_stats "xip_write" "$output")   
                alloc_time=$(pmfs_attr_time_stats "alloc_blocks" "$output")
                new_trans_time=$(pmfs_attr_time_stats "add_logentry" "$output")
                commit_trans_time=$(pmfs_attr_time_stats "add_logentry" "$output")
                meta_update_time=$((new_trans_time+commit_trans_time))
                dram_update_time=$(pmfs_attr_time_stats "new_trans" "$output")
                data_write_time=$(pmfs_attr_time_stats "memcpy_write" "$output")
            fi
            other_time=$((whole_time - alloc_time - meta_update_time - dram_update_time - data_write_time))
            table_add_row "$TABLE_NAME" "$file_system $work_load $fsize $alloc_time $meta_update_time $dram_update_time $data_write_time $other_time $whole_time $BW"
        done
    done
done