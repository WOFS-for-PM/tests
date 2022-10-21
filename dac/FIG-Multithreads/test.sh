#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools


FILE_SYSTEMS=( "NOVA" "PMFS" "HUNTER-FSYNC" "HUNTER")
FILE_SIZES=( $((1 * 1024)) )
NUM_JOBS=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 )

TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system file_size num_job bandwidth(MiB/s)"

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fsize in "${FILE_SIZES[@]}"; do
        for job in "${NUM_JOBS[@]}"; do
            size=$(split_workset "$fsize" "$job")
            if (( job == 1 )); then
                fpath="/mnt/pmem0/test"
            else 
                fpath="/mnt/pmem0/"
            fi
            
            if [[ "${file_system}" == "HUNTER-FSYNC" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                BW=$(bash "$TOOLS_PATH"/fio-fsync.sh "$fpath" 4K "$size" "$job" | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            elif [[ "${file_system}" == "HUNTER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                BW=$(bash "$TOOLS_PATH"/fio.sh "$fpath" 4K "$size" "$job" | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                BW=$(bash "$TOOLS_PATH"/fio.sh "$fpath" 4K "$size" "$job" | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            fi
            
            table_add_row "$TABLE_NAME" "$file_system $fsize $job $BW"
        done
    done
done

# Add PM performan measured by OptaneStudy to the table
table_add_row "$TABLE_NAME" "PMM 4096 1 2259.2"
table_add_row "$TABLE_NAME" "PMM 4096 2 2240.0"
table_add_row "$TABLE_NAME" "PMM 4096 3 2246.4"
table_add_row "$TABLE_NAME" "PMM 4096 4 2227.2"
table_add_row "$TABLE_NAME" "PMM 4096 5 2169.6"
table_add_row "$TABLE_NAME" "PMM 4096 6 2035.2"
table_add_row "$TABLE_NAME" "PMM 4096 7 1779.2"
table_add_row "$TABLE_NAME" "PMM 4096 8 1587.2"
table_add_row "$TABLE_NAME" "PMM 4096 9 1555.2"
table_add_row "$TABLE_NAME" "PMM 4096 10 1369.6"
table_add_row "$TABLE_NAME" "PMM 4096 11 1337.6"
table_add_row "$TABLE_NAME" "PMM 4096 12 1241.6"
table_add_row "$TABLE_NAME" "PMM 4096 13 1222.4"
table_add_row "$TABLE_NAME" "PMM 4096 14 1164.8"
table_add_row "$TABLE_NAME" "PMM 4096 15 1126.4"
table_add_row "$TABLE_NAME" "PMM 4096 16 1100.8"