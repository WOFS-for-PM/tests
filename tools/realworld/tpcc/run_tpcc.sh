#!/usr/bin/bash

source "../../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../../tools
OUTPUT="$ABS_PATH/output"
TCPP="/usr/local/tpcc-sqlite"
WORKLOAD=$TCPP/database
SRC_DIR=$ABS_PATH/../../../../splitfs
BOOST_DIR=$SRC_DIR/splitfs


FILE_SYSTEMS=("NOVA" "PMFS" "SplitFS")

mkdir -p $OUTPUT

ulimit -c unlimited

for file_system in "${FILE_SYSTEMS[@]}"; do
    echo ---------------TPCC WORKLOAD:${file_system}-----------------

    if [[ "${file_system}" == "SplitFS" ]]; then
        #1, setup fs
        sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0" 
        export LD_LIBRARY_PATH="$BOOST_DIR"
        export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree

        #2 copy
        sudo cp $WORKLOAD/tpcc.db /mnt/pmem0 && sync

        #3 run tpcc
        #-w|WAREHOUSES| -c|CONNECTIONS| -t|TRANSACTION_NUM|
        sudo LD_PRELOAD=$BOOST_DIR/libnvp.so $TCPP/tpcc_start -w 4 -c 1 -t 200000  > $OUTPUT/$file_system
    else
        #1, setup fs   
        sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0" 

        #2 copy
        sudo cp $WORKLOAD/tpcc.db /mnt/pmem0 && sync

        #3 run tpcc
        sudo $TCPP/tpcc_start -w 4 -c 1 -t 200000 > $OUTPUT/$file_system
    fi

    echo Sleeping for 2 seconds . .
    sleep 2
done


