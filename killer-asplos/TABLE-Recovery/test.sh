#!/usr/bin/env bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

TRACE_DIR="/usr/local/trace"
# FILE_SYSTEMS=( "KILLER" "NOVA" "KILLER-FAIL" "NOVA-FAIL")
FILE_SYSTEMS=( "NOVA" "NOVA-FAIL" )
TRACES_NAME=( "facebook" "twitter" )
TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system trace umount recovery"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for trace_name in "${TRACES_NAME[@]}"; do
            echo "Populating $trace_name for replaying"
            python3 "$TOOLS_PATH"/traces/populate_files.py "$TRACE_DIR"/"$trace_name"/trace.syscalltrace /mnt/pmem0/ 1
            
            echo "Replaying $trace_name on $file_system"
            if [[ "${file_system}" == "KILLER" || "${file_system}" == "KILLER-FAIL" ]]; then
                bash "$TOOLS_PATH"/setup.sh "KILLER" "dev" "0"
            else
                bash "$TOOLS_PATH"/setup.sh "NOVA" "main" "0"
            fi
            _=$("$TOOLS_PATH"/traces/replay -f "$TRACE_DIR"/"$trace_name"/trace.syscalltrace -o syscall -m fiu-no-content -d /mnt/pmem0/)

            echo "Umounting $file_system"
            UMOUNT_TIME=$( (time sudo umount /mnt/pmem0) 2>&1 | grep real | awk '{print $2}' )
            
            echo "Mounting $file_system"
            case "${file_system}" in
                "NOVA")
                    RECOVERY_TIME=$( (time bash "$TOOLS_PATH"/mount.sh "NOVA" "main" "0") 2>&1 | grep real | awk '{print $2}' )
                ;;
                "NOVA-FAIL")
                    RECOVERY_TIME=$( (time bash "$TOOLS_PATH"/mount.sh "NOVA" "failure-recovery" "0") 2>&1 | grep real | awk '{print $2}' )
                ;;
                "KILLLER")
                    RECOVERY_TIME=$( (time bash "$TOOLS_PATH"/mount.sh "KILLER" "dev" "0") 2>&1 | grep real | awk '{print $2}' )
                ;;
                "KILLLER-FAIL")
                    RECOVERY_TIME=$( (time bash "$TOOLS_PATH"/mount.sh "KILLER" "failure-recovery" "0") 2>&1 | grep real | awk '{print $2}' )
                ;;
                *)
                    echo "default (none of above)"
                ;;
            esac
            
            table_add_row "$TABLE_NAME" "$file_system $trace_name $UMOUNT_TIME $RECOVERY_TIME"  
        done
    done
done

bash "$ABS_PATH"/agg.sh "$loop" 