#!/bin/bash
source "../../common.sh"
ABS_PATH=$(where_is_script "$0")

set -x

ycsb_path="/usr/local/YCSB"
ycsb_src=$ABS_PATH/../../../../splitfs/ycsb

sudo yum install maven

mkdir -p $ycsb_path
sudo cp -r $ycsb_src/* $ycsb_path

cd $ycsb_path

sudo mvn install -DskipTests



