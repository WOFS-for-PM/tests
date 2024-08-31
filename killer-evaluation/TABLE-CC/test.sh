#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

# run within emulated pmem

PM_SIZE=256 # in MB

FILE_SYSTEMS=( "KILLER" )

WORKLOADS=( "$ABS_PATH/workloads/append.sh" "$ABS_PATH/workloads/create_delete.sh" "$ABS_PATH/workloads/rename_root_to_sub.sh" )
NUM_CRASHPOINTS=1

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for workload in "${WORKLOADS[@]}"; do
            for crash_point in $(seq 1 $NUM_CRASHPOINTS); do
                echo "Running $file_system with $workload workload and $crash_point crash point"
                # clear pmems
                "$TOOLS_PATH"/cc/clear_pmem.sh $PM_SIZE

                # mount killer
                bash "$TOOLS_PATH"/setup.sh "$file_system" "killer" "0"
                
                # take snapshot of /dev/pmem0
                "$TOOLS_PATH"/cc/take_snapshot.sh /dev/pmem0 $PM_SIZE

                # start tracing I/Os
                echo 1 > /proc/fs/HUNTER/pmem0/Enable_trace
                
                # execute program here
                $workload

                # stop tracing I/Os
                echo 0 > /proc/fs/HUNTER/pmem0/Enable_trace
                umount /mnt/pmem0
                
                # prepare /dev/pmem0 and /dev/pmem1 for latest image and crash image
                "$TOOLS_PATH"/cc/clear_pmem.sh $PM_SIZE

                "$TOOLS_PATH"/cc/apply_snapshot.sh /dev/pmem0 $PM_SIZE
                "$TOOLS_PATH"/cc/apply_snapshot.sh /dev/pmem1 $PM_SIZE

                ./gen_cp -t killer -l /dev/pmem0 -c /dev/pmem1 -s "$crash_point"

                # check consistency
                "$TOOLS_PATH"/cc/check_cc.sh
            done    
        done

    done
done