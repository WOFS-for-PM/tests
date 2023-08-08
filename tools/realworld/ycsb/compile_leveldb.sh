#!/bin/bash
source "../../common.sh"
ABS_PATH=$(where_is_script "$0")

set -x

leveldb_path="/usr/local/leveldb"
leveldb_src=$ABS_PATH/../../../../splitfs/leveldb

sudo mkdir -p $leveldb_path/build
sudo cp -r $leveldb_src/* $leveldb_path

leveldb_build_path=$leveldb_path/build
workload_path=$leveldb_path/workloads

cd $leveldb_build_path
sudo cmake -DCMAKE_BUILD_TYPE=Release .. && sudo make -j"$(nproc)"
