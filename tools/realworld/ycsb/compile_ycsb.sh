#!/bin/bash

set -x

ycsb_path="/usr/local/YCSB"

cd $ycsb_path

sudo mvn install -DskipTests



