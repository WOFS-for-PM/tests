#!/bin/bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
output="$ABS_PATH/output"
result="$ABS_PATH/performance-comparison-table-splitfs"

ycsb_dir="/usr/local/YCSB"
pmem_dir="/mnt/pmem0"
leveldb_dir="/usr/local/leveldb"
leveldb_build_dir=$leveldb_dir/build
database_dir=$pmem_dir/leveldbtest
workload_dir=$leveldb_dir/workloads
src_dir=$ABS_PATH/../../../splitfs
boost_dir=$src_dir/splitfs

FILE_SYSTEMS=( "SplitFS-YCSB" )
NUM_JOBS=( 1 )

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

    if [[ "${file_system}" =~ "SplitFS" ]]; then
        LD_PRELOAD=$boost_dir/libnvp.so $leveldb_build_dir/db_bench --use_existing_db=0 --benchmarks=ycsb,stats,printdb --db=$database_dir --threads="$threads" --open_files=1000 2>&1 | tee $output/$fs/$threads/$tracefile
    else
        $leveldb_build_dir/db_bench --use_existing_db=0 --benchmarks=ycsb,stats,printdb --db=$database_dir --threads="$threads" --open_files=1000 2>&1 | tee $output/$fs/$threads/$tracefile
    fi

    ycsb_result=$(grep -oP 'ycsb\s*:\s*\K\d+(\.\d+)?' $output/$fs/$threads/$tracefile)
    echo -n " $ycsb_result" >>$result

    echo Sleeping for 1 seconds . .
    sleep 1
}

#strace -e trace=read,write /usr/local/leveldb/build/db_bench --use_existing_db=1 --benchmarks=ycsb,stats,printdb --db=/mnt/pmem0/leveldbtest --threads=1 --open_files=1000
run_workload() {
    tracefile=$1
    fs=$2
    threads=$3
    echo ----------------------- LevelDB YCSB Run $tracefile ---------------------------

    export trace_file=$workload_dir/$tracefile
    mkdir -p $output/$fs/$threads/

    if [[ "${file_system}" =~ "SplitFS" ]]; then
        export LD_LIBRARY_PATH=$boost_dir/
        export NVP_TREE_FILE=$boost_dir/bin/nvp_nvp.tree
    fi

    if [[ "${file_system}" =~ "SplitFS" ]]; then
        LD_PRELOAD=$boost_dir/libnvp.so $leveldb_build_dir/db_bench --use_existing_db=1 --benchmarks=ycsb,stats,printdb --db=$database_dir --threads="$threads" --open_files=1000 2>&1 | tee $output/$fs/$threads/$tracefile
    else
        $leveldb_build_dir/db_bench --use_existing_db=1 --benchmarks=ycsb,stats,printdb --db=$database_dir --threads="$threads" --open_files=1000 2>&1 | tee $output/$fs/$threads/$tracefile
    fi
    ycsb_result=$(grep -oP 'ycsb\s*:\s*\K\d+(\.\d+)?' $output/$fs/$threads/$tracefile)
    echo -n " $ycsb_result" >>$result

    echo Sleeping for 1 seconds . .
    sleep 1
}

echo "file_system num_job loada(micros/op) runa(micros/op) runb(micros/op) runc(micros/op) rund(micros/op) loade(micros/op) rune(micros/op) runf(micros/op)" >$result

for job in "${NUM_JOBS[@]}"; do

    for file_system in "${FILE_SYSTEMS[@]}"; do
        echo -n $file_system >>$result
        echo -n " $job" >>$result
        if [[ "${file_system}" =~ "SplitFS" ]]; then
            sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
        elif [[ "${file_system}" == "KILLER" ]]; then
            sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
        else
            sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
        fi
        echo "Running with $job threads"
        load_workload loada_1M $file_system $job
        run_workload runa_1M_1M $file_system $job
        run_workload runb_1M_1M $file_system $job
        run_workload runc_1M_1M $file_system $job
        run_workload rund_1M_1M $file_system $job

        if [[ "${file_system}" =~ "SplitFS" ]]; then
            sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
        elif [[ "${file_system}" == "KILLER" ]]; then
            sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
        else
            sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
        fi
        load_workload loade_1M $file_system $job
        run_workload rune_1M_1M $file_system $job
        run_workload runf_1M_1M $file_system $job
        echo "" >>$result
    done

    # load_workload loade_5M $file_system
    # run_workload rune_5M_1M $file_system
    # echo "" >>$result
done
