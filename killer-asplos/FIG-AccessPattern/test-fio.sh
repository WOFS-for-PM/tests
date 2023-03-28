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
FILE_SIZES=( $((1 * 1024)) )
PATTERNS=( "seq" "rand" )

for file_system in "${FILE_SYSTEMS[@]}"; do
    for fsize in "${FILE_SIZES[@]}"; do
        for pattern in "${PATTERNS[@]}"; do

            if [[ "${pattern}" == "seq" ]]; then
                if [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                    sudo bash "$TOOLS_PATH"/traces/pm-io-trace/monitor_pm_io.sh pmem0 bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1
                elif [[ "${file_system}" == "SplitFS-FIO" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    sudo bash "$TOOLS_PATH"/traces/pm-io-trace/monitor_pm_io.sh pmem0 LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs="4K" -size="$fsize"M -name=test
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    sudo bash "$TOOLS_PATH"/traces/pm-io-trace/monitor_pm_io.sh pmem0 bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1
                fi
            else
                if [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                    sudo bash "$TOOLS_PATH"/traces/pm-io-trace/monitor_pm_io.sh pmem0 bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test 4K "$fsize" 1
                elif [[ "${file_system}" == "SplitFS-FIO" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    sudo bash "$TOOLS_PATH"/traces/pm-io-trace/monitor_pm_io.sh pmem0 LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=randwrite -ioengine=sync -bs="4K" -size="$fsize"M -name=test
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    sudo bash "$TOOLS_PATH"/traces/pm-io-trace/monitor_pm_io.sh pmem0 bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test 4K "$fsize" 1
                fi
            fi

            mkdir -p "$ABS_PATH"/PERF_DATA/"$file_system"
            mkdir -p "$ABS_PATH"/PERF_DATA/"$file_system"/perfs-fio-"$pattern"

            mv -f "$ABS_PATH"/perfs/* "$ABS_PATH"/PERF_DATA/"$file_system"/perfs-fio-"$pattern"
            mv -f "$ABS_PATH"/perf_report_filtered "$ABS_PATH"/PERF_DATA/"$file_system"/perf_report_filtered-fio-"$pattern"
        done
    done
done