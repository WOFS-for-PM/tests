#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

FILE_SYSTEMS=( "HUNTER-J-SYNC" "HUNTER-J" "SoupFS" "KILLER" "SquirrelFS" )
FILE_SIZES=( $((1 * 1024)) )

TABLE_NAME="$ABS_PATH/performance-comparison-table-fio"
table_create "$TABLE_NAME" "ops file_system file_size bandwidth(MiB/s)"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for fsize in "${FILE_SIZES[@]}"; do
            if [[ "${file_system}" == "PMM" ]]; then
                BW=2259.2
            elif [[ "${file_system}" == "KILLER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
                BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            elif [[ "${file_system}" == "SquirrelFS" ]]; then
                # must switch to squirrelfs kernel, so we report our previously measured bandwidth here
                BW=633
            elif [[ "${file_system}" == "HUNTER-J-SYNC" ]]; then
                bash "$TOOLS_PATH"/setup.sh "HUNTER-J" "osdi25-hunter-sync" "0"
                BW=$(bash "$TOOLS_PATH"/fio-fsync.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            elif [[ "${file_system}" == "HUNTER-J" ]]; then
                bash "$TOOLS_PATH"/setup.sh "HUNTER-J" "osdi25-hunter-async" "0"
                BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            fi
            table_add_row "$TABLE_NAME" "seq-write $file_system $fsize $BW"
        done
    done
done