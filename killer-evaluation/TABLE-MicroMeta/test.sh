#!/usr/bin/env bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

FILE_SYSTEMS=( "NOVA" "PMFS" "KILLER" "SplitFS-FIO" "NOVA-RELAX")
FILE_SYSTEM_REMAPS=( "nova" "pmfs" "killer" "splitfs" "nova-relax")
TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system workload tput(works/sec)"
WORKLOADS=( "^DWTL$" "^MRPL$" "^MWCL$" "^MWUL$" "^MWRL$"  )
WORKLOAD_NAMES=( "DWTL" "MRPL" "MWCL" "MWUL" "MWRL" )

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    IDX=0
    for file_system in "${FILE_SYSTEMS[@]}"; do
        file_system_remap=${FILE_SYSTEM_REMAPS[$IDX]}
        WORKLOAD_IDX=0
        for work_load in "${WORKLOADS[@]}"; do
            fs_name="^$file_system_remap$"
            workload_name="${WORKLOAD_NAMES[$WORKLOAD_IDX]}"
            cd "$TOOLS_PATH"/fxmark/bin/ || exit
            python3 run-fxmark.py --media="pmem-local" --fs="$fs_name" --workload="$work_load" --ncore="^1$" --iotype='bufferedio' --dthread='0' --dsocket='0' --rcore='False' --delegate='False' --confirm='True' --directory_name=/tmp --log_name="$file_system_remap.$work_load.log" --duration=10
            cd - || exit

            cd "$TOOLS_PATH"/fxmark/parser/ || exit
            tput=$(python3 pdata.py --log=/tmp/"$file_system_remap.$work_load.log" --out="" --type=fxmark | awk '{print $2}')
            cd - || exit

            table_add_row "$TABLE_NAME" "$file_system $workload_name $tput"  
            WORKLOAD_IDX=$((WORKLOAD_IDX+1))
        done
        IDX=$((IDX+1))
    done
done