#!/bin/bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
output="$ABS_PATH/output-rocksdb"
result="$ABS_PATH/performance-comparison-table-rocksdb"
# rocksdb source from (compling with fallocate disabled): https://github.com/Andiry/RocksDB-pmem, https://github.com/Andiry/liblightnvm
rocksdb_dir="/usr/local/RocksDB-pmem"
rocksdb_build_dir=$rocksdb_dir/build
local_lib_dir=/usr/local/lib/
src_dir=$ABS_PATH/../../../splitfs
boost_dir=$src_dir/splitfs

FILE_SYSTEMS=( "NOVA" "NOVA-RELAX" "PMFS" "KILLER" "SplitFS-FIO" "EXT4-DAX" "XFS-DAX" )
WORKLOADS=("fillseq" "fillrandom" "appendrandom" "updaterandom")
NUM_JOBS=( 1 )


run_benchmark() {
    fs=$1
    threads=$2
    workload=$3

    echo ----------------------- RocksDB Workload: $3 ---------------------------

    mkdir -p $output/$fs/$threads

    export LD_LIBRARY_PATH=$local_lib_dir/

    if [[ "${file_system}" =~ "SplitFS" ]]; then
        export LD_LIBRARY_PATH=$local_lib_dir/:$boost_dir/
        export NVP_TREE_FILE=$boost_dir/bin/nvp_nvp.tree
    fi

    if [[ "${file_system}" =~ "SplitFS" ]]; then
        LD_PRELOAD=$boost_dir/libnvp.so $rocksdb_dir/db_bench --db=/mnt/pmem0/rocksdb --num_levels=6 --key_size=20 --prefix_size=20 \
     --keys_per_prefix=0 --value_size=1024 --cache_size=17179869184 --cache_numshardbits=6 \
     --compression_type=none --compression_ratio=1 --min_level_to_compress=-1 --disable_seek_compaction=1 \
     --hard_rate_limit=2 --write_buffer_size=134217728 --max_write_buffer_number=2 \
     --level0_file_num_compaction_trigger=8 --target_file_size_base=268435456 \
     --max_bytes_for_level_base=2147483648 --disable_wal=0 --wal_dir=/mnt/pmem0/rocksdb/WAL_LOG \
     --sync=1 --verify_checksum=1 --delete_obsolete_files_period_micros=314572800 \
     --max_background_compactions=4 --max_background_flushes=0 --level0_slowdown_writes_trigger=16 \
     --level0_stop_writes_trigger=24 --statistics=0 --stats_per_interval=0 --stats_interval=1048576 \
     --histogram=0 --use_plain_table=1 --open_files=-1 --mmap_read=0 --mmap_write=0 \
     --memtablerep=prefix_hash --bloom_bits=10 --bloom_locality=1 \
     --benchmarks="$workload" --use_existing_db=0 --num=1000000 --threads="$threads" 2>&1 | tee $output/$fs/$threads/rocksdb
        echo -n " 0" >>$result
    else
        $rocksdb_dir/db_bench --db=/mnt/pmem0/rocksdb --num_levels=6 --key_size=20 --prefix_size=20 \
     --keys_per_prefix=0 --value_size=4076 --cache_size=17179869184 --cache_numshardbits=6 \
     --compression_type=none --compression_ratio=1 --min_level_to_compress=-1 --disable_seek_compaction=1 \
     --hard_rate_limit=2 --write_buffer_size=134217728 --max_write_buffer_number=2 \
     --level0_file_num_compaction_trigger=8 --target_file_size_base=134217728  \
     --max_bytes_for_level_base=1073741824 --disable_wal=0 --wal_dir=/mnt/pmem0/rocksdb/WAL_LOG \
     --sync=1 --verify_checksum=1 --delete_obsolete_files_period_micros=314572800 \
     --max_background_compactions=4 --max_background_flushes=0 --level0_slowdown_writes_trigger=16 \
     --level0_stop_writes_trigger=24 --statistics=0 --stats_per_interval=0 --stats_interval=1048576 \
     --histogram=0 --use_plain_table=1 --open_files=-1 --mmap_read=0 --mmap_write=0 \
     --memtablerep=prefix_hash --bloom_bits=10 --bloom_locality=1 \
     --benchmarks="$workload" --use_existing_db=0 --num=1000000 --threads="$threads"  2>&1 | tee $output/$fs/$threads/rocksdb
        throughput=$(cat $output/$fs/$threads/rocksdb | grep -oE '[0-9]+\.[0-9]+ MB/s' | sed 's/ MB\/s//')
        echo -n " $throughput" >>$result
    fi

    echo Sleeping for 1 seconds . .
    sleep 1
}

echo "file_system num_job fill_seq(MB/s) fillrandom(MB/s) appendrandom(MB/s) updaterandom(MB/s)" >$result

for job in "${NUM_JOBS[@]}"; do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        echo -n $file_system >>$result
        echo -n " $job" >>$result
        echo "Running with $job threads"
        for workload in "${WORKLOADS[@]}"; do
            if [[ "${file_system}" =~ "SplitFS" ]]; then
                sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
            elif [[ "${file_system}" == "KILLER" ]]; then
                sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
            else
                sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
            fi
            run_benchmark $file_system $job $workload
        done

        echo "" >>$result
    done
done
