#!/usr/bin/env bash
#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts

mkdir -p "$ABS_PATH"/DATA
mkdir -p "$ABS_PATH"/PERF_DATA

FILE_SYSTEMS=( "NOVA" "PMFS" "KILLER" "SplitFS-FILEBENCH" "EXT4-DAX" "XFS-DAX" )
FILE_BENCHES=( "fileserver.f" "varmail.f" "webserver.f" "webproxy.f" )
THREADS=( 1 )

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fbench in "${FILE_BENCHES[@]}"; do
        mkdir -p "$ABS_PATH"/DATA/"$fbench"
        for thread in "${THREADS[@]}"; do
            cp -f "$FSCRIPT_PRE_FIX"/"$fbench" "$ABS_PATH"/DATA/"$fbench"/"$thread" 
            sed_cmd='s/set $nthreads=.*$/set $nthreads='$thread'/g' 
            sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$fbench"/"$thread"

            if [[ "${file_system}" == "SplitFS-FILEBENCh" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                sudo bash "$TOOLS_PATH"/traces/pm-io-trace/monitor_pm_io.sh pmem0 LD_PRELOAD=$BOOST_DIR/libnvp.so /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
            else
                if [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                fi
                
                sudo bash "$TOOLS_PATH"/traces/pm-io-trace/monitor_pm_io.sh pmem0 /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
            fi

            mkdir -p "$ABS_PATH"/PERF_DATA/"$file_system"
            mkdir -p "$ABS_PATH"/PERF_DATA/"$file_system"/perfs-"$fbench"

            mv -f "$ABS_PATH"/perfs/* "$ABS_PATH"/PERF_DATA/"$file_system"/perfs-"$fbench"
            mv -f "$ABS_PATH"/perf_report_filtered "$ABS_PATH"/PERF_DATA/"$file_system"/perf_report_filtered-"$fbench"
        done
    done
done