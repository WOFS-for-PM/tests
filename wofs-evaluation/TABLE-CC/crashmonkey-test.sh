#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

# Test successful when the PMEM is not larger than 16 GiB.

# run within emulated pmem

PM_SIZE=4 # in MB

FILE_SYSTEMS=( "KILLER" )

WORKLOADS=( "$ABS_PATH/workloads/append.sh" "$ABS_PATH/workloads/create_delete.sh" "$ABS_PATH/workloads/rename_root_to_sub.sh" )
NUM_CRASHPOINTS=1000

loop=1
if [ "$1" ]; then
    loop=$1
fi

TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "workload cp latest-consistent"

mkdir -p /mnt/ramdisk

umount /mnt/ramdisk/

mount -t tmpfs -o size="$PM_SIZE"m tmpfs /mnt/ramdisk
mkdir -p /mnt/pmem0
mkdir -p /mnt/pmem1

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for workload in "${WORKLOADS[@]}"; do
            for crash_point in $(seq 1 $NUM_CRASHPOINTS); do
                echo "Running $file_system with $workload workload and $crash_point crash point"
                # clear pmems
                bash "$TOOLS_PATH"/cc/clear_pmem.sh $PM_SIZE

                # mount killer
                bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25-io-trace" "0"
                
                # take snapshot of /dev/pmem0
                bash "$TOOLS_PATH"/cc/take_snapshot.sh /dev/pmem0 $PM_SIZE

                # start tracing I/Os
                echo 1 > /proc/fs/HUNTER/pmem0/Enable_trace
                
                # execute program here
                $workload

                # stop tracing I/Os
                echo 0 > /proc/fs/HUNTER/pmem0/Enable_trace
                umount /mnt/pmem0
                
                cp -f /tmp/killer-trace "$ABS_PATH"/killer-trace

                # prepare /dev/pmem0 and /dev/pmem1 for latest image and crash image
                bash "$TOOLS_PATH"/cc/clear_pmem.sh $PM_SIZE

                bash "$TOOLS_PATH"/cc/apply_snapshot.sh /dev/pmem0 $PM_SIZE
                bash "$TOOLS_PATH"/cc/apply_snapshot.sh /dev/pmem1 $PM_SIZE

                OUTPUT=$(./gen_cp -t killer-trace -l /dev/pmem0 -c /dev/pmem1 -s "$crash_point")

                if [[ "${OUTPUT}" == *"No need to do further check"* ]]; then
                    echo "Early consistency check passed"
                    table_add_row "$TABLE_NAME" "$workload $crash_point early-passed"
                else
                    # check consistency
                    ret=$(bash "$TOOLS_PATH"/cc/check_cc.sh)
                    # if "Consistency check passed" in $ret
                    if [[ $ret == *"Consistency check passed"* ]]; then
                        echo "Consistency check passed"
                        table_add_row "$TABLE_NAME" "$workload $crash_point passed"
                    else
                        echo "Consistency check failed"
                        table_add_row "$TABLE_NAME" "$workload $crash_point failed"
                    fi
                fi

            done    
        done

    done
done

umount /mnt/ramdisk