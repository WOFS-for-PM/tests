#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system file_bench threads memory(bytes) iops"
mkdir -p "$ABS_PATH"/DATA

FILE_SYSTEMS=( "KILLER" "NOVA" )
FILE_BENCHES=( "fileserver.f" "varmail.f" )
THREADS=( 1 )

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
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25-meta-trace" "1"
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "meta-trace" "1"
                fi
                
                sudo /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"

                if [[ "${file_system}" == "KILLER" ]]; then
                    cat /proc/fs/HUNTER/pmem0/timing_stats > "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"-timing
                else
                    cat /proc/fs/NOVA/pmem0/timing_stats > "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"-timing
                fi
            fi
            
            sleep 5

            memory=$(cat "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"-timing | grep "mem_usage" | awk '{print $2}')

            iops=$(filebench_attr_iops "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread")
            
            table_add_row "$TABLE_NAME" "$file_system $fbench $thread $memory $iops"
        done
    done
done