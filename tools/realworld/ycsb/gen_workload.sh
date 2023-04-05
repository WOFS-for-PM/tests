#!/bin/bash

set -x

ycsb_dir="/usr/local/YCSB"
leveldb_dir="/usr/local/leveldb/workloads"
sudo mkdir -p ${leveldb_dir}

cd $ycsb_dir
num=500000

./bin/ycsb load tracerecorder -p recorder.file=${leveldb_dir}/loada_5M -p recordcount=${num} -P workloads/workloada
./bin/ycsb run tracerecorder -p recorder.file=${leveldb_dir}/runa_5M_5M -p recordcount=${num} -p operationcount=${num} -P workloads/workloada

