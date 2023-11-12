#!/usr/bin/env bash
#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts

mkdir -p "$ABS_PATH"/DATA
mkdir -p "$ABS_PATH"/MEM_DATA

FILE_SYSTEMS=( "NOVA" "KILLER" "SplitFS-FILEBENCH" "EXT4-DAX" "XFS-DAX" )
FILE_BENCHES=( "fileserver.f" )
THREADS=( 1 )

loop=1
if [ "$1" ]; then
    loop=$1
fi

TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system workload peak_mem(KiB) avg_mem(KiB)"

for ((i=1; i <= loop; i++))
do 
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for fbench in "${FILE_BENCHES[@]}"; do
            mkdir -p "$ABS_PATH"/DATA/"$fbench"
            for thread in "${THREADS[@]}"; do
                cp -f "$FSCRIPT_PRE_FIX"/"$fbench" "$ABS_PATH"/DATA/"$fbench"/"$thread" 
                sed_cmd='s/set $nthreads=.*$/set $nthreads='$thread'/g' 
                sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$fbench"/"$thread"
                
                echo "Memory(KiB)" > "$ABS_PATH"/"MEM_DATA/mem-table-$fbench-$thread-$file_system"
                bash "$ABS_PATH"/listen-mem.sh "$ABS_PATH"/"MEM_DATA/mem-table-$fbench-$thread-$file_system" &
                process_id=$(ps -aux | grep "listen-mem.sh" | grep -v "grep" | awk '{print $2}')
                echo "$process_id"
                sleep 1

                if [[ "${file_system}" == "SplitFS-FILEBENCh" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    LD_PRELOAD=$BOOST_DIR/libnvp.so /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
                else
                    if [[ "${file_system}" == "KILLER" ]]; then
                        bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                    else
                        bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    fi
                    
                    sudo /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
                fi
                
                sleep 1
                sudo kill -9 "$process_id"

                MEM_INFO=$(python3 $ABS_PATH/calc_mem_usage.py "$ABS_PATH"/"MEM_DATA/mem-table-$fbench-$thread-$file_system")
                # peak: 858804
                # average: 426319
                # parse peak from MEM_INFO
                peak=$(echo $MEM_INFO | grep "peak" | awk '{print $2}')
                # parse average from MEM_INFO
                average=$(echo $MEM_INFO | grep "average" | awk '{print $4}')

                table_add_row "$TABLE_NAME" "$file_system fileserver $peak $average"  
            done
        done
    done
done