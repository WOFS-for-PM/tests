#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs
MADFS_DIR=$ABS_PATH/../../../MadFS
SplitFS_DIR=$ABS_PATH/../../../splitfs

FILE_SYSTEMS=( "NOVA" "PMFS" "NOVA-RELAX" "KILLER" "SplitFS-FIO" "EXT4-DAX" "XFS-DAX" "PMM" "MadFS" )

FILE_SIZES=( $((1 * 1024)) $((2 * 1024)) $((4 * 1024)) $((8 * 1024)) $((12 * 1024)) $((16 * 1024)) $((20 * 1024)) $((24 * 1024)) $((28 * 1024)) $((32 * 1024)) )

TABLE_NAME="$ABS_PATH/performance-comparison-table-fsize"
table_create "$TABLE_NAME" "ops file_system file_size bandwidth(MiB/s)"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for fsize in "${FILE_SIZES[@]}"; do
            if [[ "${file_system}" == "PMM" ]]; then
                BW=2259.2
            elif [[ "${file_system}" == "KILLER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
                BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            elif [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
                cd "$SplitFS_DIR" || exit
                git checkout no-prefault
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                cd - || exit
            elif [[ "${file_system}" == "MadFS" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
                BW=$(LD_PRELOAD=$MADFS_DIR/build-release/libmadfs.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            fi
            table_add_row "$TABLE_NAME" "seq-write $file_system $fsize $BW"

            if [[ "${file_system}" == "PMM" ]]; then
                BW=2259.2
            elif [[ "${file_system}" == "KILLER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
                BW=$(bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            elif [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
                cd "$SplitFS_DIR" || exit
                git checkout no-prefault
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=randwrite -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                cd - || exit
            elif [[ "${file_system}" == "MadFS" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
                BW=$(LD_PRELOAD=$MADFS_DIR/build-release/libmadfs.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=randwrite -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                BW=$(bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            fi
            table_add_row "$TABLE_NAME" "rnd-write $file_system $fsize $BW"

            if [[ "${file_system}" == "PMM" ]]; then
                BW=2483.2
            elif [[ "${file_system}" == "KILLER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
                BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 "read" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            elif [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
                cd "$SplitFS_DIR" || exit
                git checkout no-prefault
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=read -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                cd - || exit
            elif [[ "${file_system}" == "MadFS" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
                BW=$(LD_PRELOAD=$MADFS_DIR/build-release/libmadfs.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=read -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 "read" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            fi
            table_add_row "$TABLE_NAME" "seq-read $file_system $fsize $BW"
            
            if [[ "${file_system}" == "PMM" ]]; then
                BW=2483.2
            elif [[ "${file_system}" == "KILLER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
                BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 "randread" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            elif [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
                cd "$SplitFS_DIR" || exit
                git checkout no-prefault
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH="$BOOST_DIR"
                export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=randread -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                cd - || exit
            elif [[ "${file_system}" == "MadFS" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
                BW=$(LD_PRELOAD=$MADFS_DIR/build-release/libmadfs.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=randread -ioengine=sync -bs="4K" -size="$fsize"M -name=test | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1 "randread" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            fi
            table_add_row "$TABLE_NAME" "rnd-read $file_system $fsize $BW"
        done
    done
done