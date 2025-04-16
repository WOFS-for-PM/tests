#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs
MADFS_DIR=$ABS_PATH/../../../MadFS

TABLE_NAME="$ABS_PATH/performance-comparison-table-madfs"
table_create "$TABLE_NAME" "file_system file_bench threads iops create delete close read write IO"
mkdir -p "$ABS_PATH"/DATA

FILE_SYSTEMS=( "MadFS" )
FILE_BENCHES=( "fileserver.f" "varmail.f" "webserver.f" "webproxy.f" )
THREADS=( 1 )

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fbench in "${FILE_BENCHES[@]}"; do
        mkdir -p "$ABS_PATH"/DATA/"$fbench"
        for thread in "${THREADS[@]}"; do
            cp -f "$FSCRIPT_PRE_FIX"/"$fbench" "$ABS_PATH"/DATA/"$fbench"/"$thread" 
            sed_cmd='s/set $nthreads=.*$/set $nthreads='$thread'/g' 
            sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$fbench"/"$thread"
            
            if [[ "${file_system}" == "SplitFS-FILEBENCH" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                LD_PRELOAD=$BOOST_DIR/libnvp.so /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
            elif [[ "${file_system}" == "MadFS" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
                LD_PRELOAD=$MADFS_DIR/build-release/libmadfs.so /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
            else
                if [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                fi
                
                sudo /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
            fi
            
            iops=$(filebench_attr_iops "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread")
            # Retreive the breakdown
            case "${fbench}" in
                "fileserver.f")
                    create=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile1")
                    delete=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "deletefile1")
                    close=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile1")
                    read=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile1")
                    write=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "wrtfile1")
                ;;
                "varmail.f")
                    create=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile3")
                    delete=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "deletefile1")
                    close=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile2")
                    read=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile4")
                    write=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "appendfilerand2")
                ;;
                "webserver.f")
                    create=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "openfile1")
                    delete=0
                    close=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile1")
                    read=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile1")
                    write=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "appendlog")
                ;;
                "webproxy.f")
                    create=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "createfile1")
                    delete=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "deletefile1")
                    close=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "closefile1")
                    read=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "readfile2")
                    write=$(filebench_attr_breakdown "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread" "appendfilerand1")
                ;;
                *)
                    echo "default (none of above)"
                ;;
            esac
            IO=$(echo $read $write | awk '{print $1 + $2}')
            table_add_row "$TABLE_NAME" "$file_system $fbench $thread $iops $create $delete $close $read $write $IO"
        done
    done
done