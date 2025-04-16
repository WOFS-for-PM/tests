#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

# FILE_SYSTEMS=( "KILLER" )
# FILE_SYSTEMS=( "NOVA" )
# FILE_SIZES=( $((1 * 1024)) )
WORKLOADS=( "write" "randwrite" )
FILE_SYSTEMS=( "KILLER" "WINEFS" "NOVA" )
FILE_SIZES=( $((96 * 1024)) )


loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for workload in "${WORKLOADS[@]}"; do
            for fsize in "${FILE_SIZES[@]}"; do
                echo 1 > /proc/sys/vm/drop_caches
                echo 2 > /proc/sys/vm/drop_caches
                echo 3 > /proc/sys/vm/drop_caches
                
                if [[ "${workload}" == "write" ]]; then
                    LOG="seq"-$file_system
                else
                    LOG="rand"-$file_system
                fi
                
                if [[ "${file_system}" == "KILLER" ]]; then
                    fsize=$((96 * 1024))
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25-aging" "0"
                    sudo fio -filename=/mnt/pmem0/test -fallocate=none -direct=0 -iodepth 1 -rw="$workload" -ioengine=sync -bs=4K -size="$fsize"M -name=test -write_bw_log="$LOG" -log_avg_msec=500
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    sudo fio -filename=/mnt/pmem0/file1 -fallocate=none -direct=0 -iodepth 1 -rw="$workload" -ioengine=sync -bs=4K -size="$fsize"M -name=test -write_bw_log="$LOG" -log_avg_msec=500
                fi

                # punch hole
                if [[ "${file_system}" == "KILLER" ]]; then
                    # do nothing
                    echo "KILLER"
                else
                    sudo "$TOOLS_PATH"/aging/aging_system -d /mnt/pmem0 -s 64 -o 50 -b 4096 -p 2
                fi

                # fill hole
                fsize=$((32 * 1024))
                if [[ "${file_system}" == "KILLER" ]]; then
                    # do nothing
                    echo "KILLER"
                else
                    sudo fio -filename=/mnt/pmem0/file2 -fallocate=none -direct=0 -iodepth 1 -rw="$workload" -ioengine=sync -bs=4K -size="$fsize"M -name=test -write_bw_log="$LOG" -log_avg_msec=500
                fi
            done
        done
    done
done