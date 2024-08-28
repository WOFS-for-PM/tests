#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

# FILE_SYSTEMS=( "KILLER" )
FILE_SYSTEMS=( "SplitFS-FIO" )
# FILE_SYSTEMS=( "NOVA" )
# FILE_SIZES=( $((1 * 1024)) )
FILE_SIZES=( $((32 * 1024)) )


loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for fsize in "${FILE_SIZES[@]}"; do
            if [[ "${file_system}" == "KILLER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "killer-aging" "0"
                sudo fio -filename=/mnt/pmem0/test -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs=4K -size="$fsize"M -name=test -write_bw_log="$file_system" -write_lat_log="$file_system" -log_avg_msec=500
            elif [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs="4K" -size="$fsize"M -name=test -eta-newline=500ms -eta-interval=500ms -eta=always > "$file_system"_bw.log
                python3 extra_splitfs_bw_log.py
                rm "$file_system"_bw.log
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                sudo fio -filename=/mnt/pmem0/test -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs=4K -size="$fsize"M -name=test -write_bw_log="$file_system" -write_lat_log="$file_system" -log_avg_msec=500
            fi
            cat /proc/fs/HUNTER/pmem0/timing_stats
        done
    done
done