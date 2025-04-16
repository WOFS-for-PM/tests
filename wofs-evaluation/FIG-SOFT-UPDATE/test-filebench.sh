#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system file_bench threads iops"
mkdir -p "$ABS_PATH"/DATA

FILE_SYSTEMS=( "HUNTER-J-SYNC" "HUNTER-J" "SoupFS" "KILLER" "SquirrelFS" )
FILE_BENCHES=( "fileserver.f" "varmail.f" )
THREADS=( 1 )

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fbench in "${FILE_BENCHES[@]}"; do
        mkdir -p "$ABS_PATH"/DATA/"$fbench"
        for thread in "${THREADS[@]}"; do
            cp -f "$FSCRIPT_PRE_FIX"/"$fbench" "$ABS_PATH"/DATA/"$fbench"/"$thread" 
            sed_cmd='s/set $nthreads=.*$/set $nthreads='$thread'/g' 
            sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$fbench"/"$thread"
        
            if [[ "${file_system}" == "KILLER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
            elif [[ "${file_system}" == "SquirrelFS" ]]; then
                # must switch to squirrelfs kernel, so we report our previously measured bandwidth here
                echo "SquirrelFS"
            elif [[ "${file_system}" == "HUNTER-J-SYNC" ]]; then
                bash "$TOOLS_PATH"/setup.sh "HUNTER-J" "osdi25-hunter-dac" "0"
            elif [[ "${file_system}" == "HUNTER-J" ]]; then
                bash "$TOOLS_PATH"/setup.sh "HUNTER-J" "osdi25-hunter-async" "0"
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
            fi
            
            if [[ "${file_system}" == "SquirrelFS" ]]; then
                if [[ "${fbench}" == "fileserver.f" ]]; then
                    iops=34934.632
                else
                    iops=179121.033
                fi    
            else 
                sudo /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
                
                iops=$(filebench_attr_iops "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread")
            fi

            table_add_row "$TABLE_NAME" "$file_system $fbench $thread $iops"
        done
    done
done