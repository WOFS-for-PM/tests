#!/usr/bin/env bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

TRACE_DIR="/usr/local/FIU-trace"
FILE_SYSTEMS=( "HUNTER" "HUNTER-J" "PMFS" "NOVA" "NOVA-RELAX" "SplitFS-FILEBENCH" "EXT4-DAX" "XFS-DAX" )
TRACES_NAME=( "twitter" "facebook" "usr1" "usr2" "moodle" "gsf-filesrv" )
TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system trace ops"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for trace_name in "${TRACES_NAME[@]}"; do
            if [[ "${file_system}" == "SplitFS-FIO" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                echo "Tailoring $trace_name for replaying"
                python3 "$TOOLS_PATH"/traces/fiu-trace/trace_tailor.py "$TRACE_DIR"/"$trace_name"/trace.syscall "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored

                echo "Replaying $trace_name on $file_system"
                # OPS=$(sudo LD_PRELOAD=$BOOST_DIR/libnvp.so "$TOOLS_PATH"/traces/fiu-trace/replay -f "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored -o syscall -m fiu-no-content -d /mnt/pmem0 | grep "OPS: " | awk '{print $9}')
                OPS=$(sudo LD_PRELOAD=$BOOST_DIR/libnvp.so python3 "$TOOLS_PATH"/traces/fiu-trace/replay.py "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored /mnt/pmem0 | grep "OPS: " | awk '{print $2}')
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
                echo "Tailoring $trace_name for replaying"
                python3 "$TOOLS_PATH"/traces/fiu-trace/trace_tailor.py "$TRACE_DIR"/"$trace_name"/trace.syscall "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored
                
                echo "Replaying $trace_name on $file_system"
                # OPS=$(sudo "$TOOLS_PATH"/traces/fiu-trace/replay -f "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored -o syscall -m fiu-no-content -d /mnt/pmem0 | grep "OPS: " | awk '{print $9}')
                OPS=$(sudo python3 "$TOOLS_PATH"/traces/fiu-trace/replay.py "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored /mnt/pmem0 | grep "OPS: " | awk '{print $2}')
            fi

            table_add_row "$TABLE_NAME" "$file_system $trace_name $OPS"  
        done
    done
done
