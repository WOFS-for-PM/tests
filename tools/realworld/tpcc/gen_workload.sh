#!/bin/bash

set -x

tpcc_path="/usr/local/tpcc-sqlite"
pmem_dir=/mnt/pmem0

cd $tpcc_path
sudo cp ./schema2/tpcc.db $pmem_dir/
sudo ./tpcc_load -w 4

sudo mkdir ./database
sudo cp $pmem_dir/tpcc.db ./database/