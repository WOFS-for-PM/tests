#!/usr/bin/env bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

TRACE_DIR="/usr/local/trace"
# FILE_SYSTEMS=( "NOVA" "PMFS" "KILLER" "SplitFS-FIO" "EXT4-DAX" "XFS-DAX")
FILE_SYSTEMS=( "NOVA" "PMFS" "EXT4-DAX" "XFS-DAX")
# FILE_SYSTEMS=( "EXT4-DAX" )
# TRACES_NAME=( "facebook" "gsf-filesrv" "moodle" "twitter" "ug-filesrv" "usr1" "usr2" )
TRACES_NAME=( "facebook" "twitter" )
TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system trace ops"

mkdir -p "$ABS_PATH"/DATA

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
                echo "Populating $trace_name for replaying"
                LD_PRELOAD=$BOOST_DIR/libnvp.so python3 "$TOOLS_PATH"/traces/fiu-trace/populate_files.py "$TRACE_DIR"/"$trace_name"/trace.syscalltrace /mnt/pmem0/ 1

                echo "Replaying $trace_name on $file_system"
                OPS=$(sudo bash "$TOOLS_PATH"/traces/pm-io-trace/monitor_pm_io.sh pmem0 LD_PRELOAD=$BOOST_DIR/libnvp.so "$TOOLS_PATH"/traces/fiu-trace/replay -f "$TRACE_DIR"/"$trace_name"/trace.syscalltrace -o syscall -m fiu-no-content -d /mnt/pmem0/ | grep "OPS: " | awk '{print $9}')
            else
                if [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                fi
                echo "Populating $trace_name for replaying"
                python3 "$TOOLS_PATH"/traces/fiu-trace/populate_files.py "$TRACE_DIR"/"$trace_name"/trace.syscalltrace /mnt/pmem0/ 1
                
                echo "Replaying $trace_name on $file_system"
                OPS=$(sudo bash "$TOOLS_PATH"/traces/pm-io-trace/monitor_pm_io.sh pmem0 "$TOOLS_PATH"/traces/fiu-trace/replay -f "$TRACE_DIR"/"$trace_name"/trace.syscalltrace -o syscall -m fiu-no-content -d /mnt/pmem0/ | grep "OPS: " | awk '{print $9}')
            fi

            mkdir -p "$ABS_PATH"/DATA/"$file_system"
            mkdir -p "$ABS_PATH"/DATA/"$file_system"/perfs-"$trace_name"

            mv -f "$ABS_PATH"/perfs/* "$ABS_PATH"/DATA/"$file_system"/perfs-"$trace_name"
            mv -f "$ABS_PATH"/perf_report_filtered "$ABS_PATH"/DATA/"$file_system"/perf_report_filtered-"$trace_name"

            table_add_row "$TABLE_NAME" "$file_system $trace_name $OPS"  
        done
    done
done
