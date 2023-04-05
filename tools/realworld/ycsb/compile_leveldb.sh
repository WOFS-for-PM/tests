#!/bin/bash

set -x

leveldb_path="/usr/local/leveldb"

sudo mkdir -p $leveldb_path/build
leveldb_build_path=$leveldb_path/build
workload_path=$leveldb_path/workloads

cd $leveldb_build_path
sudo cmake -DCMAKE_BUILD_TYPE=Release .. && make -j4
