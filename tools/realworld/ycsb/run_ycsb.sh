#!/bin/bash
source "../../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../../tools
output="$ABS_PATH/output"
result="$ABS_PATH/ycsb_results"

ycsb_dir="/usr/local/YCSB"
pmem_dir="/mnt/pmem0"
leveldb_dir="/usr/local/leveldb"
leveldb_build_dir=$leveldb_dir/build
database_dir=$pmem_dir/leveldbtest
workload_dir=$leveldb_dir/workloads
src_dir=$ABS_PATH/../../../../splitfs
boost_dir=$src_dir/splitfs
FILE_SYSTEMS=("NOVA" "NOVA-RELAX" "PMFS" "EXT4-DAX" "XFS-DAX" "KILLER")

load_workload()
{
    tracefile=$1
    fs=$2
    echo -----------------------  YCSB Load $tracefile ---------------------------
    rm -rf $database_dir

    export trace_file=$workload_dir/$tracefile
    mkdir -p $output/$fs

    if [[ "${file_system}" == "SplitFS" ]]; then
        export LD_LIBRARY_PATH=$src_dir/splitfs-so/ycsb/strict
        export NVP_TREE_FILE=$boost_dir/bin/nvp_nvp.tree
    fi

    if [[ "${file_system}" == "SplitFS" ]]; then
        LD_PRELOAD=$src_dir/splitfs-so/ycsb/strict/libnvp.so $leveldb_build_dir/db_bench --use_existing_db=0 --benchmarks=ycsb,stats,printdb --db=$database_dir --threads=1 --open_files=1000 2>&1 | tee $output/$fs/$tracefile
    else
        $leveldb_build_dir/db_bench --use_existing_db=0 --benchmarks=ycsb,stats,printdb --db=$database_dir --threads=1 --open_files=1000 2>&1 | tee $output/$fs/$tracefile
    fi

    ycsb_result=$(grep -oP 'ycsb\s*:\s*\K\d+(\.\d+)?' $output/$fs/$tracefile)
    echo -n " $ycsb_result" >> $result
    rm $pmem_dir/*

    echo Sleeping for 1 seconds . .
    sleep 1
}

#strace -e trace=read,write /usr/local/leveldb/build/db_bench --use_existing_db=1 --benchmarks=ycsb,stats,printdb --db=/mnt/pmem0/leveldbtest --threads=1 --open_files=1000
run_workload()
{
    tracefile=$1
    fs=$2
    echo ----------------------- LevelDB YCSB Run $tracefile ---------------------------

    export trace_file=$workload_dir/$tracefile
    mkdir -p $output/$fs

    if [[ "${file_system}" == "SplitFS" ]]; then
        export LD_LIBRARY_PATH=$src_dir/splitfs-so/ycsb/strict
        export NVP_TREE_FILE=$boost_dir/bin/nvp_nvp.tree
    fi

    if [[ "${file_system}" == "SplitFS" ]]; then
        LD_PRELOAD=$src_dir/splitfs-so/ycsb/strict/libnvp.so $leveldb_build_dir/db_bench --use_existing_db=1 --benchmarks=ycsb,stats,printdb --db=$database_dir --threads=1 --open_files=1000 2>&1 | tee $output/$fs/$tracefile
    else
        $leveldb_build_dir/db_bench --use_existing_db=1 --benchmarks=ycsb,stats,printdb --db=$database_dir --threads=1 --open_files=1000 2>&1 | tee $output/$fs/$tracefile
    fi
    ycsb_result=$(grep -oP 'ycsb\s*:\s*\K\d+(\.\d+)?' $output/$fs/$tracefile)
    echo -n " $ycsb_result" >> $result
    rm $pmem_dir/*

    echo Sleeping for 1 seconds . .
    sleep 1
}



echo "file_system loada(micros/op) runa(micros/op) runb(micros/op) runc(micros/op) rund(micros/op) runf(micros/op)" > $result
for file_system in "${FILE_SYSTEMS[@]}"; do
    echo -n $file_system >> $result
    if [[ "${file_system}" == "SplitFS" ]]; then
        sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0" 
    elif [[ "${file_system}" == "KILLER" ]]; then 
        sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0" 
    else
        sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"         
    fi
    
    load_workload loada_5M $file_system
    run_workload runa_5M_5M $file_system
    run_workload runb_5M_5M $file_system
    run_workload runc_5M_5M $file_system
    run_workload rund_5M_5M $file_system
    run_workload runf_5M_5M $file_system

    # load_workload loade_5M $file_system
    # run_workload rune_5M_1M $file_system
    echo "" >> $result
done

