#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
FILE_SIZES=( $((1 * 1024)) )

# Please test PM in dev/dax mode
FILE_SYSTEMS=( "PM" )
# TABLE_NAME="$ABS_PATH/performance-comparison-table-PM-512GB-interleaved"
TABLE_NAME="$ABS_PATH/performance-comparison-table-PM-256GB-non-interleaved"
NUM_JOBS=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 )
table_create "$TABLE_NAME" "ops file_system thread bandwidth(MiB/s)"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for fsize in "${FILE_SIZES[@]}"; do
            for job in "${NUM_JOBS[@]}"; do
                sync; echo 1 > /proc/sys/vm/drop_caches
                sync; echo 2 > /proc/sys/vm/drop_caches
                sync; echo 3 > /proc/sys/vm/drop_caches

                BW=$(fio -filename="/dev/dax0.0" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=libpmem -bs="4K" -size="$fsize"M -name=test -thread -numjobs="$job" -sync=1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                table_add_row "$TABLE_NAME" "seq-write $file_system $job $BW"

                BW=$(fio -filename="/dev/dax0.0" -fallocate=none -direct=0 -iodepth 1 -rw=randwrite -ioengine=libpmem -bs="4K" -size="$fsize"M -name=test -thread -numjobs="$job" -sync=1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                table_add_row "$TABLE_NAME" "rnd-write $file_system $job $BW"

                BW=$(fio -filename="/dev/dax0.0" -fallocate=none -direct=0 -iodepth 1 -rw=read -ioengine=libpmem -bs="4K" -size="$fsize"M -name=test -thread -numjobs="$job" -sync=1 | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                table_add_row "$TABLE_NAME" "seq-read $file_system $job $BW"

                BW=$(fio -filename="/dev/dax0.0" -fallocate=none -direct=0 -iodepth 1 -rw=randread -ioengine=libpmem -bs="4K" -size="$fsize"M -name=test -thread -numjobs="$job" -sync=1 | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                table_add_row "$TABLE_NAME" "rnd-read $file_system $job $BW"
            done

        done
    done
done