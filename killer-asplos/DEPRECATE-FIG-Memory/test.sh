#!/usr/bin/env bash
#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts

mkdir -p "$ABS_PATH"/DATA
mkdir -p "$ABS_PATH"/MEM_DATA

FILE_SYSTEMS=( "NOVA" "PMFS" "KILLER" "SplitFS-FILEBENCH" "EXT4-DAX" "XFS-DAX" )
FILE_BENCHES=( "fileserver.f" "varmail.f" "webserver.f" "webproxy.f" )
THREADS=( 1 8 )

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
        done
    done
done