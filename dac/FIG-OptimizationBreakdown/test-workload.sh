#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts

FILE_SYSTEMS=( "HUNTER" "NO-WORKLD" )
FILE_BENCHES=( "varmail.f" )
THREADS=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16)

TABLE_NAME="$ABS_PATH/performance-comparison-table-workload"
table_create "$TABLE_NAME" "file_system file_bench threads iops"
mkdir -p "$ABS_PATH"/DATA

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fbench in "${FILE_BENCHES[@]}"; do
        mkdir -p "$ABS_PATH"/DATA/"$fbench"
        for thread in "${THREADS[@]}"; do
            if [[ "${file_system}" == "HUNTER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
            else
                sudo umount /mnt/pmem0
                sudo mount -t HUNTER -o init,meta_local,meta_async,history_w /dev/pmem0 /mnt/pmem0
            fi

            cp -f "$FSCRIPT_PRE_FIX"/"$fbench" "$ABS_PATH"/DATA/"$fbench"/"$thread" 
            sed_cmd='s/set $nthreads=.*$/set $nthreads='$thread'/g' 
            sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$fbench"/"$thread"
            
            sudo /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"

            iops=$(filebench_attr_iops "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread")
            
            table_add_row "$TABLE_NAME" "$file_system $fbench $thread $iops"
        done
    done
done