#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

# FILE_SYSTEMS=( "NOVA" "PMFS" "KILLER" "SplitFS-FIO" "EXT4-DAX" "XFS-DAX" "PMM")
FILE_SYSTEMS=( "KILLER-MEM" )
FILE_SIZES=( $((32 * 1024)) )

TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "ops file_system regulate file_size bandwidth(MiB/s)"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for fsize in "${FILE_SIZES[@]}"; do
            if [[ "${file_system}" == *"KILLER"* ]]; then
                DATA_OBJS=( 0 $((16 * 1024)) )
                for data_obj in "${DATA_OBJS[@]}"; do
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "killer-mem" "0" "$data_obj"
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                    
                    table_add_row "$TABLE_NAME" "seq-write $file_system $data_obj $fsize $BW"
                done
            fi
            
            if [[ "${file_system}" == *"KILLER"* ]]; then
                # 0%, 25%, 50%, 75%, 100% memory objects
                DATA_OBJS=( 0 $((2 * 1024 * 1024)) $((4 * 1024 * 1024)) $((6 * 1024 * 1024)) $((8 * 1024 * 1024)) )

                for data_obj in "${DATA_OBJS[@]}"; do
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "killer-mem" "0" "$data_obj"
                    BW=$(bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                    
                    table_add_row "$TABLE_NAME" "rnd-write $file_system $data_obj $fsize $BW"
                done
            fi

            sleep 1
        done
    done
done