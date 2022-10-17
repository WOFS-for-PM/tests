#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools


FILE_SYSTEMS=( "NOVA" "PMFS" "HUNTER-FSYNC" "HUNTER")
FILE_SIZES=( $((1 * 1024)) $((2 * 1024)) $((4 * 1024)) $((8 * 1024))
             $((16 * 1024)) $((32 * 1024)) $((64 * 1024)))


TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system file_size bandwidth(MiB/s)"

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fsize in "${FILE_SIZES[@]}"; do
        if [[ "${file_system}" == "HUNTER-FSYNC" ]]; then
            bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
            BW=$(bash "$TOOLS_PATH"/fio-fsync.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
        elif [[ "${file_system}" == "HUNTER" ]]; then
            bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
            BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
        else
            bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
            BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
        fi
        
        table_add_row "$TABLE_NAME" "$file_system $fsize $BW"
    done
done