#!/bin/bash

set -x

ycsb_dir="/usr/local/YCSB"
leveldb_dir="/usr/local/leveldb/workloads"
sudo mkdir -p ${leveldb_dir}

cd $ycsb_dir
num=50000
num2=$(expr $num / 5)

./bin/ycsb load tracerecorder -p recorder.file=${leveldb_dir}/loada_5M -p recordcount=${num} -P workloads/workloada
./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/runa_5M_5M -p recordcount=${num} -p operationcount=${num} -P workloads/workloada
# ./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/runb_5M_5M -p recordcount=${num} -p operationcount=${num} -P workloads/workloadb
# ./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/runc_5M_5M -p recordcount=${num} -p operationcount=${num} -P workloads/workloadc
# ./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/runf_5M_5M -p recordcount=${num} -p operationcount=${num} -P workloads/workloadf
# ./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/rund_5M_5M -p recordcount=${num} -p operationcount=${num} -P workloads/workloadd

# ./bin/ycsb load tracerecorder -p recorder.file=${leveldb_dir}/loade_5M -p recordcount=${num} -P workloads/workloade
# ./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/rune_5M_1M -p recordcount=${num} -p operationcount=${num2} -P workloads/workloade

