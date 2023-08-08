#!/bin/bash
source "../../common.sh"
ABS_PATH=$(where_is_script "$0")

sqlite_path="/usr/local/sqlite3-trace"
sqlite_src=$ABS_PATH/../../../../splitfs/sqlite3-trace

sudo mkdir -p $sqlite_path
sudo cp -r $sqlite_src/* $sqlite_path

cd $sqlite_path || exit

./configure
make clean
make -j"$(nproc)"
sudo make install

