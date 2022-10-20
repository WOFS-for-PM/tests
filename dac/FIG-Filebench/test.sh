#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts


TABLE_NAME="$ABS_PATH/performance-comparison-table-nosync"
table_create "$TABLE_NAME" "file_system file_bench threads iops"
mkdir -p "$ABS_PATH"/DATA

FILE_SYSTEMS=( "NOVA" "PMFS" "HUNTER" "HUNTER-NOHISTORY")
FILE_BENCHES=( "fileserver.f" "varmail.f" )
THREADS=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 )

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fbench in "${FILE_BENCHES[@]}"; do
        mkdir -p "$ABS_PATH"/DATA/"$fbench"
        for thread in "${THREADS[@]}"; do
            if [[ "${file_system}" == "HUNTER" || "${file_system}" == "HUNTER-NOHISTORY" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
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

# We show the case that file (e.g., deletion/creation) operation 
# is also asynchronous in varmail-nosync. 
FILE_SYSTEMS=( "HUNTER-NOSYNC")
FILE_BENCHES=( "varmail-nosync.f" )
THREADS=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 )

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fbench in "${FILE_BENCHES[@]}"; do
        mkdir -p "$ABS_PATH"/DATA/"$fbench"
        for thread in "${THREADS[@]}"; do
            if [[ "${file_system}" == "HUNTER-NOSYNC" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
            fi
            
            cp -f "$FSCRIPT_PRE_FIX"/"$fbench" "$ABS_PATH"/DATA/"$fbench"/"$thread" 
            sed_cmd='s/set $nthreads=.*$/set $nthreads='$thread'/g' 
            sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$fbench"/"$thread"
            
            sudo /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"

            iops=$(filebench_attr_iops "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread")
            
            _fbench=$fbench
            
            # fbench alias
            if [[ "${fbench}" == "varmail-nosync.f" ]]; then
                _fbench="varmail.f"
            fi
           
            table_add_row "$TABLE_NAME" "$file_system $_fbench $thread $iops"
        done
    done
done