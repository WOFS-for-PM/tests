#!/usr/bin/env bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

FILE_SYSTEMS=( "KILLER" "NOVA" "KILLER-FAIL" "NOVA-FAIL")
WORKLOADS=( "fio" "fileserver" )
TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system workload umount recovery"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for workload in "${WORKLOADS[@]}"; do
            echo "Start $workload recovery..."
            if [[ "${file_system}" == "KILLER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "KILLER" "dev" "0"
            elif [[ "${file_system}" == "KILLER-FAIL" ]]; then
                # format the disk first, or garbage occurs. 
                # bash "$TOOLS_PATH"/killer-formater/mkfs.killer.sh pmem0
                bash "$TOOLS_PATH"/setup.sh "KILLER" "killer-failure" "0"
            elif [[ "${file_system}" == "NOVA-FAIL" ]]; then
                bash "$TOOLS_PATH"/setup.sh "NOVA" "failure-recovery" "0"
            else
                bash "$TOOLS_PATH"/setup.sh "NOVA" "main" "0"
            fi

            if [[ "${workload}" == "fio" ]]; then
                bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$((32 * 1024))" 1 
            elif [[ "${workload}" == "fileserver" ]]; then
                sudo /usr/local/filebench/filebench -f "$TOOLS_PATH"/fbscripts/fileserver.f
            fi

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
                "KILLER")
                    RECOVERY_TIME=$( (time bash "$TOOLS_PATH"/mount.sh "KILLER" "dev" "0") 2>&1 | grep real | awk '{print $2}' )
                ;;
                "KILLER-FAIL")
                    RECOVERY_TIME=$( (time bash "$TOOLS_PATH"/mount.sh "KILLER" "killer-failure" "0") 2>&1 | grep real | awk '{print $2}' )
                ;;
                *)
                    echo "default (none of above)"
                ;;
            esac

            # Finish a iteration, umount the disk
            sudo umount /mnt/pmem0

            table_add_row "$TABLE_NAME" "$file_system $workload $UMOUNT_TIME $RECOVERY_TIME"  
        done
    done
done

bash "$ABS_PATH"/agg.sh "$loop" 