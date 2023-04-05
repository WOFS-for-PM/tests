!/bin/bash
source "../../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../../tools
OUTPUT="$ABS_PATH/output"

ycsb_dir="/usr/local/YCSB"
pmem_dir="/mnt/pmem0"
leveldb_dir="/usr/local/leveldb"
leveldb_build_dir=$leveldb_dir/build
database_dir=$pmem_dir/leveldbtest
workload_dir=$leveldb_dir/workloads
src_dir=$ABS_PATH/../../../../splitfs
boost_dir=$src_dir/splitfs

FILE_SYSTEMS=("NOVA" "PMFS" "SplitFS")

mkdir -p $OUTPUT


for file_system in "${FILE_SYSTEMS[@]}"; do
    echo ---------------YCSB WORKLOAD:${file_system}-----------------
    if [[ "${file_system}" == "SplitFS" ]]; then
        sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0" 
        export LD_LIBRARY_PATH=$boost_dir/
        export NVP_TREE_FILE=$boost_dir/bin/nvp_nvp.tree

        export trace_file=$workload_dir/loada_5M
        LD_PRELOAD=$boost_dir/libnvp.so $leveldb_build_dir/db_bench --use_existing_db=0 \
        --benchmarks=ycsb,stats,printdb --db=$database_dir --threads=1 --open_files=1000 \
        > $OUTPUT/$file_system

        export trace_file=$workload_dir/runa_5M_5M
        LD_PRELOAD=$boost_dir/libnvp.so $leveldb_build_dir/db_bench --use_existing_db=1 \
        --benchmarks=ycsb,stats,printdb --db=$database_dir --threads=1 --open_files=1000 \
        >> $OUTPUT/$file_system
    else
        sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0" 

        export trace_file=$workload_dir/loada_5M
        $leveldb_build_dir/db_bench --use_existing_db=0 --benchmarks=ycsb,stats,printdb \
        --db=$database_dir --threads=1 --open_files=1000 > $OUTPUT/$file_system

        export trace_file=$workload_dir/runa_5M_5M
        $leveldb_build_dir/db_bench --use_existing_db=1 --benchmarks=ycsb,stats,printdb \
        --db=$database_dir --threads=1 --open_files=1000  >> $OUTPUT/$file_system
    fi

    echo Sleeping for 1 seconds . .
    sleep 1
done

