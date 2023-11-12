#!/usr/bin/env bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

TRACE_DIR="/usr/local/FIU-trace"
# FILE_SYSTEMS=( "HUNTER-J" "NOVA" "HUNTER-J-FAIL" "NOVA-FAIL")
# WORKLOADS=( "twitter" "facebook" "usr1" "usr2" "moodle" "gsf-filesrv" )
FILE_SYSTEMS=( "HUNTER-J" "NOVA" "HUNTER-J-FAIL" "NOVA-FAIL")
WORKLOADS=( "fio" )
TABLE_NAME="$ABS_PATH/performance-comparison-table-fio"
table_create "$TABLE_NAME" "file_system workload recovery"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for workload in "${WORKLOADS[@]}"; do
            echo "Start $workload recovery..."
            if [[ "${file_system}" == "HUNTER-J" ]]; then
                bash "$TOOLS_PATH"/setup.sh "${file_system}" "hunter-async" "0"
            elif [[ "${file_system}" == "HUNTER-J-FAIL" ]]; then
                bash "$TOOLS_PATH"/setup.sh "HUNTER-J" "hunter-async-failure" "0"
            elif [[ "${file_system}" == "NOVA-FAIL" ]]; then
                bash "$TOOLS_PATH"/setup.sh "NOVA" "failure-recovery" "0"
            else
                bash "$TOOLS_PATH"/setup.sh "NOVA" "main" "0"
            fi
            
            if [[ "${workload}" == "fio" ]]; then
                fsize=$(( 64 * 1024 ))
                BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            else 
                trace_name=$workload
                echo "Tailoring $trace_name for replaying"
                python3 "$TOOLS_PATH"/traces/fiu-trace/trace_tailor.py "$TRACE_DIR"/"$trace_name"/trace.syscall "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored
                
                echo "Replaying $trace_name on $file_system"
                OPS=$(sudo python3 "$TOOLS_PATH"/traces/fiu-trace/replay.py "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored /mnt/pmem0 1 | grep "OPS: " | awk '{print $2}')
            fi
            

            echo "Umounting $file_system"
            sudo umount /mnt/pmem0

            echo "Mounting $file_system"
            case "${file_system}" in
                "NOVA")
                    RECOVERY_TIME=$( (time bash "$TOOLS_PATH"/mount.sh "NOVA" "main" "0") 2>&1 | grep real | awk '{print $2}' )
                ;;
                "NOVA-FAIL")
                    RECOVERY_TIME=$( (time bash "$TOOLS_PATH"/mount.sh "NOVA" "failure-recovery" "0") 2>&1 | grep real | awk '{print $2}' )
                ;;
                "HUNTER-J")
                    RECOVERY_TIME=$( (time bash "$TOOLS_PATH"/mount.sh "HUNTER-J" "hunter-async" "0") 2>&1 | grep real | awk '{print $2}' )
                ;;
                "HUNTER-J-FAIL")
                    RECOVERY_TIME=$( (time bash "$TOOLS_PATH"/mount.sh "HUNTER-J" "hunter-async-failure" "0") 2>&1 | grep real | awk '{print $2}' )
                ;;
                *)
                    echo "default (none of above)"
                ;;
            esac

            _MINUTES=$(echo "$RECOVERY_TIME" | awk -F 'm' '{print $1}' | sed 's/ //g')
            _SECONDS=$(echo "$RECOVERY_TIME" | awk -F 'm' '{print $2}' | awk -F 's' '{print $1}' | sed 's/ //g')
            TOTAL_SECONDS=$(echo "$_MINUTES * 60 + $_SECONDS" | bc -l)

            # Finish a iteration, umount the disk
            sudo umount /mnt/pmem0

            table_add_row "$TABLE_NAME" "$file_system $workload $TOTAL_SECONDS"  
        done
    done
done