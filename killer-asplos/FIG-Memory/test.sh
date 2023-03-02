#!/usr/bin/env bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

TRACE_DIR="/usr/local/trace"
# TODO: KILLER and SplitFS-FIO is under developed, so we don't test it.
# FILE_SYSTEMS=( "NOVA" "PMFS" "KILLER" "SplitFS-FIO" "EXT4-DAX" "XFS-DAX")
FILE_SYSTEMS=( "NOVA" "PMFS" "EXT4-DAX" "XFS-DAX" )
TRACES_NAME=( "twitter" )

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for trace_name in "${TRACES_NAME[@]}"; do
            echo "Memory(KiB)" > "$ABS_PATH"/"mem-table-$trace_name-$file_system"

            bash "$ABS_PATH"/listen-mem.sh "$ABS_PATH"/"mem-table-$trace_name-$file_system" &
            process_id=$(ps -aux | grep "listen-mem.sh" | grep -v "grep" | awk '{print $2}')
            echo "$process_id"
            sleep 1
            
            if [[ "${file_system}" == "SplitFS-FIO" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                
                echo "Populating $trace_name for replaying"
                LD_PRELOAD=$BOOST_DIR/libnvp.so python3 "$TOOLS_PATH"/traces/fiu-trace/populate_files.py "$TRACE_DIR"/"$trace_name"/trace.syscalltrace /mnt/pmem0/ 1

                echo "Replaying $trace_name on $file_system"
                _=$(LD_PRELOAD=$BOOST_DIR/libnvp.so "$TOOLS_PATH"/traces/fiu-trace/replay -f "$TRACE_DIR"/"$trace_name"/trace.syscalltrace -o syscall -m fiu-no-content -d /mnt/pmem0/ | grep "OPS: " | awk '{print $9}')
            else
                if [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                fi

                echo "Populating $trace_name for replaying"
                python3 "$TOOLS_PATH"/traces/fiu-trace/populate_files.py "$TRACE_DIR"/"$trace_name"/trace.syscalltrace /mnt/pmem0/ 1
                
                echo "Replaying $trace_name on $file_system"
                _=$("$TOOLS_PATH"/traces/fiu-trace/replay -f "$TRACE_DIR"/"$trace_name"/trace.syscalltrace -o syscall -m fiu-no-content -d /mnt/pmem0/ | grep "OPS: " | awk '{print $9}')
            fi
            
            sleep 1
            sudo kill -9 "$process_id"
        done
    done
done
