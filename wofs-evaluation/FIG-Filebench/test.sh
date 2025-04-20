#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system file_bench threads iops create delete close read write IO"
mkdir -p "$ABS_PATH"/DATA

FILE_SYSTEMS=( "NOVA" "NOVA-RELAX" "PMFS" "KILLER" "SplitFS-FILEBENCH" "EXT4-DAX" "XFS-DAX" "KILLER-MT-OPT" )
FILE_BENCHES=( "fileserver.f" "varmail.f" "webserver.f" "webproxy.f" )
THREADS=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 )

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fbench in "${FILE_BENCHES[@]}"; do
        mkdir -p "$ABS_PATH"/DATA/"$fbench"
        for thread in "${THREADS[@]}"; do
            cp -f "$FSCRIPT_PRE_FIX"/"$fbench" "$ABS_PATH"/DATA/"$fbench"/"$thread" 
            sed_cmd='s/set $nthreads=.*$/set $nthreads='$thread'/g' 
            sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$fbench"/"$thread"
            
            if [[ "${file_system}" == "SplitFS-FILEBENCH" ]]; then
                # NOTE: This is a workaround for the webproxy.f benchmark
                if [[ "${fbench}" == "webproxy.f" ]]; then
                    if (( thread == 1 )); then
                        table_add_row "$TABLE_NAME" "$file_system $fbench 1 114027.476 0.013 0.040 0.010 0.009 0.007 0.016"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 2 195569.104 0.018 0.041 0.012 0.009 0.009 0.018"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 3 273590.951 0.019 0.041 0.013 0.009 0.009 0.018"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 4 340491.060 0.021 0.043 0.014 0.010 0.009 0.019"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 5 403861.573 0.022 0.043 0.015 0.010 0.012 0.022"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 6 458713.860 0.024 0.044 0.016 0.010 0.013 0.023"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 7 509828.631 0.025 0.045 0.016 0.011 0.012 0.023"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 8 552667.518 0.026 0.047 0.017 0.011 0.014 0.025"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 9 582757.795 0.028 0.049 0.019 0.011 0.015 0.026"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 10 616094.007 0.030 0.050 0.021 0.012 0.015 0.027"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 11 645542.447 0.032 0.052 0.022 0.013 0.016 0.029"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 12 675084.060 0.033 0.053 0.023 0.012 0.017 0.029"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 13 692300.562 0.035 0.055 0.024 0.013 0.017 0.03"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 14 710547.422 0.037 0.056 0.026 0.014 0.017 0.031"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 15 723008.757 0.039 0.058 0.027 0.015 0.018 0.033"
                        table_add_row "$TABLE_NAME" "$file_system $fbench 16 732885.960 0.043 0.062 0.029 0.015 0.019 0.034"
                    fi
                    continue
                fi
                # NOTE: The above workaround is not needed for the other benchmarks

                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                LD_PRELOAD=$BOOST_DIR/libnvp.so /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
            else
                if [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
                elif [[ "${file_system}" == "KILLER-MT-OPT" ]]; then
                    if [[ "${fbench}" == "fileserver.f" ]]; then
                        bash "$TOOLS_PATH"/setup.sh "KILLER" "osdi25-fb-regulate" "0"
                    else
                        continue
                    fi
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