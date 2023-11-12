#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

TABLE_NAME="$ABS_PATH/performance-comparison-table-hunt"
table_create "$TABLE_NAME" "file_system file_bench threads iops"
mkdir -p "$ABS_PATH"/DATA

FILE_SYSTEMS=( "HUNTER" )
FILE_BENCHES=( "webserver.f" "webproxy.f" )
THREADS=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 )

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fbench in "${FILE_BENCHES[@]}"; do
        mkdir -p "$ABS_PATH"/DATA/"$fbench"
        for thread in "${THREADS[@]}"; do
            cp -f "$FSCRIPT_PRE_FIX"/"$fbench" "$ABS_PATH"/DATA/"$fbench"/"$thread" 
            sed_cmd='s/set $nthreads=.*$/set $nthreads='$thread'/g' 
            sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$fbench"/"$thread"
            
            if [[ "${file_system}" == "SplitFS-FILEBENCH" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                LD_PRELOAD=$BOOST_DIR/libnvp.so /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
            else
                if [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                elif [[ "${file_system}" == "HUNTER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dac" "0"
                elif [[ "${file_system}" == "HUNTER-J" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "hunter-async" "0"
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                fi
                
                sudo /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
            fi
            
            iops=$(filebench_attr_iops "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread")
            table_add_row "$TABLE_NAME" "$file_system $fbench $thread $iops"
        done
    done
done