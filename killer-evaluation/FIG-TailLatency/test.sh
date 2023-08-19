#!/usr/bin/env bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

FILE_SYSTEMS=( "NOVA" "NOVA-RELAX" "PMFS" "KILLER" "SplitFS-FIO" "EXT4-DAX" "XFS-DAX")
FILE_SIZES=( $((1 * 1024)) $((32 * 1024)) )

TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system file_size tail50 tail60 tail70 tail80 tail90 tail95 tail99 tail995 tail999 tail9995 tail9999"

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
                bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                OUTPUT=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1)
            elif [[ "${file_system}" == "SplitFS-FIO" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                OUTPUT=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs="4K" -size="$fsize"M -name=test)
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                OUTPUT=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1)
            fi

            echo "$OUTPUT" > fio-output
            tail50=$(python3 extract.py fio-output 50.00)
            tail60=$(python3 extract.py fio-output 60.00)
            tail70=$(python3 extract.py fio-output 70.00)
            tail80=$(python3 extract.py fio-output 80.00)
            tail90=$(python3 extract.py fio-output 90.00)
            tail95=$(python3 extract.py fio-output 95.00)
            tail99=$(python3 extract.py fio-output 99.00)
            tail995=$(python3 extract.py fio-output 99.50)
            tail999=$(python3 extract.py fio-output 99.90)
            tail9995=$(python3 extract.py fio-output 99.95)
            tail9999=$(python3 extract.py fio-output 99.99)
            # tail99999=$(python3 extract.py fio-output 99.999)
            # tail999999=$(python3 extract.py fio-output 99.9999)
            # tail9999999=$(python3 extract.py fio-output 99.99999)
            # tail99999999=$(python3 extract.py fio-output 99.999999)

            table_add_row "$TABLE_NAME" "$file_system $fsize $tail50 $tail60 $tail70 $tail80 $tail90 $tail95 $tail99 $tail995 $tail999 $tail9995 $tail9999"  
        done
    done
done

# rm fio-output

# OUTPUT=$(sudo fio -directory=/mnt/pmem0 -fallocate=none -direct=1 -iodepth 1 -rw=write -ioengine=sync -bs=4K -thread -numjobs=$job -size=${EACH_SIZE}M -name=test --dedupe_percentage=0 -nrfiles=128 -group_reporting)
