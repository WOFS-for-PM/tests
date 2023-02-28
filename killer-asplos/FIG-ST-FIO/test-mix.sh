#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

FILE_SYSTEMS=( "NOVA" "PMFS" "KILLER" "SplitFS-FIO" "EXT4-DAX" "XFS-DAX" "PMM")
FILE_SIZES=( $((1 * 1024)) )
MIXRD_RATIOS=( "10" "30" "50" "70" "90" )
TABLE_NAME="$ABS_PATH/performance-comparison-table-mix"
table_create "$TABLE_NAME" "file_system mix_rw file_size bandwidth(MiB/s)"

loop=1
if [ "$1" ]; then
    loop=$1
fi

# TODO: KILLER is very slow in this benchmark, why?
for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for fsize in "${FILE_SIZES[@]}"; do
            for mix_rd_ratio in "${MIXRD_RATIOS[@]}"; do
                if [[ "${file_system}" == "PMM" ]]; then
                    BW=2259.2
                elif [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                    BW=$(bash "$TOOLS_PATH"/fio-mix.sh /mnt/pmem0/test 4K "$fsize" 1 "$mix_rd_ratio" | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "SplitFS-FIO" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=rw -ioengine=sync -bs="4K" -size="$fsize"M -name=test -rwmixread="$mix_rd_ratio" | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    BW=$(bash "$TOOLS_PATH"/fio-mix.sh /mnt/pmem0/test 4K "$fsize" 1 "$mix_rd_ratio" | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                table_add_row "$TABLE_NAME" "$file_system $mix_rd_ratio:$((100-mix_rd_ratio)) $fsize $BW"
            done
        done
    done
done