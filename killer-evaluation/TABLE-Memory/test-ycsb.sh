#!/bin/bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
output="$ABS_PATH/output"

ycsb_dir="/usr/local/YCSB"
pmem_dir="/mnt/pmem0"
leveldb_dir="/usr/local/leveldb"
leveldb_build_dir=$leveldb_dir/build
database_dir=$pmem_dir/leveldbtest
workload_dir=$leveldb_dir/workloads
src_dir=$ABS_PATH/../../../splitfs
boost_dir=$src_dir/splitfs

FILE_SYSTEMS=( "NOVA" "KILLER" "SplitFS-YCSB" "EXT4-DAX" "XFS-DAX" )
NUM_JOBS=( 1 )

TABLE_NAME="$ABS_PATH/performance-comparison-table"

loop=1
if [ "$1" ]; then
    loop=$1
fi

load_workload() {
    tracefile=$1
    fs=$2
    threads=$3
    echo ----------------------- YCSB Load $tracefile ---------------------------

    export trace_file=$workload_dir/$tracefile
    mkdir -p $output/$fs/$threads

    if [[ "${file_system}" =~ "SplitFS" ]]; then
        export LD_LIBRARY_PATH=$boost_dir/
        export NVP_TREE_FILE=$boost_dir/bin/nvp_nvp.tree
    fi
    
    echo "Memory(KiB)" > "$ABS_PATH"/"MEM_DATA/mem-table-yscb-loadA-$file_system"
    bash "$ABS_PATH"/listen-mem.sh "$ABS_PATH"/"MEM_DATA/mem-table-yscb-loadA-$file_system" &
    process_id=$(ps -aux | grep "listen-mem.sh" | grep -v "grep" | awk '{print $2}')
    echo "$process_id"
    sleep 1

    if [[ "${file_system}" =~ "SplitFS" ]]; then
        LD_PRELOAD=$boost_dir/libnvp.so $leveldb_build_dir/db_bench --use_existing_db=0 --benchmarks=ycsb,stats,printdb --db=$database_dir --threads="$threads" --open_files=1000 2>&1 | tee $output/$fs/$threads/$tracefile
    else
        $leveldb_build_dir/db_bench --use_existing_db=0 --benchmarks=ycsb,stats,printdb --db=$database_dir --threads="$threads" --open_files=1000 2>&1 | tee $output/$fs/$threads/$tracefile
    fi

    ycsb_result=$(grep -oP 'ycsb\s*:\s*\K\d+(\.\d+)?' $output/$fs/$threads/$tracefile)
    # echo -n " $ycsb_result" >>$result

    sleep 1
    sudo kill -9 "$process_id"

    MEM_INFO=$(python3 $ABS_PATH/calc_mem_usage.py "$ABS_PATH"/"MEM_DATA/mem-table-yscb-loadA-$file_system")
    # peak: 858804
    # average: 426319
    # parse peak from MEM_INFO
    peak=$(echo $MEM_INFO | grep "peak" | awk '{print $2}')
    # parse average from MEM_INFO
    average=$(echo $MEM_INFO | grep "average" | awk '{print $4}')

    table_add_row "$TABLE_NAME" "$file_system ycsbLoadA $peak $average"  
    
    echo Sleeping for 1 seconds . .
    sleep 1
}

for ((i=1; i <= loop; i++))
do 
    for job in "${NUM_JOBS[@]}"; do
        for file_system in "${FILE_SYSTEMS[@]}"; do

            if [[ "${file_system}" =~ "SplitFS" ]]; then
                sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
            elif [[ "${file_system}" == "KILLER" ]]; then
                sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
            else
                sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
            fi
            echo "Running with $job threads"
            load_workload loada_1M $file_system $job
            
        done
    done
done