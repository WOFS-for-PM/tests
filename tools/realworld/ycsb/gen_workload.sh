#!/bin/bash

set -x

ycsb_dir="/usr/local/YCSB"
leveldb_dir="/usr/local/leveldb/workloads"
sudo mkdir -p ${leveldb_dir}

cd $ycsb_dir
num=1000000
num2=1000000

./bin/ycsb load tracerecorder -p recorder.file=${leveldb_dir}/loada_1M -p recordcount=${num} -P workloads/workloada
./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/runa_1M_1M -p recordcount=${num} -p operationcount=${num} -P workloads/workloada
./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/runb_1M_1M -p recordcount=${num} -p operationcount=${num} -P workloads/workloadb
./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/runc_1M_1M -p recordcount=${num} -p operationcount=${num} -P workloads/workloadc
./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/rund_1M_1M -p recordcount=${num} -p operationcount=${num} -P workloads/workloadd

./bin/ycsb load tracerecorder -p recorder.file=${leveldb_dir}/loade_1M -p recordcount=${num} -P workloads/workloade
./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/rune_1M_1M -p recordcount=${num} -p operationcount=${num2} -P workloads/workloade
./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/runf_1M_1M -p recordcount=${num} -p operationcount=${num} -P workloads/workloadf

