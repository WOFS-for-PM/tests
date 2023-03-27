#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

FILE_SYSTEMS=( "KILLER" "NOVA" )
FILE_SIZES=( $((4 * 1024)) )
BLK_SIZES=( "4K" "8K" "16K" "32K" "128K" "1MB" )
NUM_JOBS=( 1 2 3 4 5 6 7 8 )
TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "ops file_system blk_size num_job file_size bandwidth(MiB/s)"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for fsize in "${FILE_SIZES[@]}"; do
            for bsize in "${BLK_SIZES[@]}"; do
                for job in "${NUM_JOBS[@]}"; do
                    if (( job == 1 )); then
                        fpath="/mnt/pmem0/test"
                    else 
                        fpath="/mnt/pmem0/"
                    fi
                    if [[ "${file_system}" == "KILLER" ]]; then
                        bash "$TOOLS_PATH"/setup.sh "$file_system" "read-study" "0"
                        BW=$(bash "$TOOLS_PATH"/fio.sh "$fpath" "$bsize" "$fsize" "$job" "read" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                    else
                        bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                        BW=$(bash "$TOOLS_PATH"/fio.sh "$fpath"  "$bsize" "$fsize" "$job" "read" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                    fi
                    table_add_row "$TABLE_NAME" "seq-read $file_system $bsize $job $fsize $BW"
                done
            
            done
        done
    done
done