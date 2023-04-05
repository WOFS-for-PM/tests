#!/usr/bin/bash

if [ ! "$1" ]; then
    graph_name=cit-Patents.txt
else
    graph_name=$1
fi

if [ ! "$2" ]; then
    iter=10
else
    iter=$2
fi

source "../../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../../tools
OUTPUT="$ABS_PATH/output"
GRAPHCHI="/usr/local/graphchi"
GRAPHCHI_PATH="$GRAPHCHI"/graphchi-cpp
GRAPH_PATH="$GRAPHCHI"/graph/"$graph_name"
NEW_GRAPH_PATH=/mnt/pmem0/"$graph_name"
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

FILE_SYSTEMS=("NOVA" "PMFS" "SplitFS")

mkdir -p $OUTPUT

for file_system in "${FILE_SYSTEMS[@]}"; do
    if [[ "${file_system}" == "SplitFS" ]]; then
        #1, setup fs
        sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
        export LD_LIBRARY_PATH="$BOOST_DIR"
        export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree

        #2, copy graph to /mnt/pmem0
        sudo cp $GRAPH_PATH /mnt/pmem0

        #3, run grapchi
        cd $GRAPHCHI_PATH && echo edgelist | sudo LD_PRELOAD=$BOOST_DIR/libnvp.so \
        bin/example_apps/pagerank file $NEW_GRAPH_PATH niters $iter > $OUTPUT/${file_system}
    else
        #1, setup fs   
        sudo bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"

        #2, copy graph to /mnt/pmem0
        sudo cp $GRAPH_PATH /mnt/pmem0

        #3, run grapchi
        cd $GRAPHCHI_PATH && echo edgelist | sudo bin/example_apps/pagerank file \
        $NEW_GRAPH_PATH niters $iter > $OUTPUT/${file_system}
    fi
done

# echo run "$GRAPHCHI_PATH"/bin/example_apps/pagerank 
# cd $GRAPHCHI_PATH && echo edgelist | sudo bin/example_apps/pagerank file $NEW_GRAPH_PATH niters $iter
