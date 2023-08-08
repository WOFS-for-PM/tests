#!/bin/bash
source "../../common.sh"
ABS_PATH=$(where_is_script "$0")

set -x

cur_dir=$(readlink -f ./)

tpcc_path="/usr/local/tpcc-sqlite"
tpcc_src=$ABS_PATH/../../../../splitfs/tpcc-sqlite
tpcc_build_path="$tpcc_path/src"

sudo mkdir -p $tpcc_path
sudo cp -r $tpcc_src/* $tpcc_path

cd $tpcc_build_path
make clean
make -j"$(nproc)"

cd $cur_dir
