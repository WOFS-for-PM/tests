#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

FILE_SYSTEMS=( "NOVA" "PMFS" "NOVA-RELAX" "KILLER" "SplitFS-FIO" "EXT4-DAX" "XFS-DAX" )
FILE_SIZES=( $((1 * 1024)) )
NUM_JOBS=( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16)
TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system ops job file_size bandwidth(MiB/s)"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for fsize in "${FILE_SIZES[@]}"; do
            for job in "${NUM_JOBS[@]}"; do
                if (( job == 1 )); then
                    fpath="/mnt/pmem0/test"
                else 
                    fpath="/mnt/pmem0/"
                fi

                if [[ "${file_system}" == "PMM" ]]; then
                    BW=2259.2
                elif [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh "$fpath" 4K "$fsize" "$job" | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "SplitFS-FIO" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -directory=/mnt/pmem0 -fallocate=none -direct=0 -iodepth 1 -thread -numjobs="$job" -rw=write -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh "$fpath" 4K "$fsize" "$job" | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                table_add_row "$TABLE_NAME" "$file_system seq-write $job $fsize $BW"
                
                if [[ "${file_system}" == "PMM" ]]; then
                    BW=2259.2
                elif [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                    BW=$(bash "$TOOLS_PATH"/fio-rand.sh $fpath 4K "$fsize" "$job" | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "SplitFS-FIO" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -directory=/mnt/pmem0 -fallocate=none -direct=0 -iodepth 1 -thread -numjobs="$job" -rw=randwrite -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    BW=$(bash "$TOOLS_PATH"/fio-rand.sh $fpath 4K "$fsize" "$job" | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                table_add_row "$TABLE_NAME" "$file_system rnd-write $job $fsize $BW"
                
                if [[ "${file_system}" == "PMM" ]]; then
                    BW=2259.2
                elif [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh "$fpath" 4K "$fsize" "$job" "read" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "SplitFS-FIO" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -directory=/mnt/pmem0 -fallocate=none -direct=0 -iodepth 1 -thread -numjobs="$job" -rw=read -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh "$fpath" 4K "$fsize" "$job" "read" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                table_add_row "$TABLE_NAME" "$file_system seq-read $job $fsize $BW"

                if [[ "${file_system}" == "PMM" ]]; then
                    BW=2483.2
                elif [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dev" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh "$fpath" 4K "$fsize" "$job" "randread" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "SplitFS-FIO" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -directory=/mnt/pmem0 -fallocate=none -direct=0 -iodepth 1 -thread -numjobs="$job" -rw=randread -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh "$fpath" 4K "$fsize" "$job" "randread" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                table_add_row "$TABLE_NAME" "$file_system rnd-read $job $fsize $BW"
           done
        done
    done
done