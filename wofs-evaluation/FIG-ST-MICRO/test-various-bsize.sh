#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs
MADFS_DIR=$ABS_PATH/../../../MadFS

FILE_SYSTEMS=( "NOVA" "PMFS" "NOVA-RELAX" "KILLER" "SplitFS-FIO" "EXT4-DAX" "XFS-DAX" "PMM" "MadFS" "KILLER-AVX")
FILE_SIZES=($((1 * 1024)))
BLK_SIZES=(256B 512B $((1 * 1024))B $((2 * 1024))B $((4 * 1024))B $((8 * 1024))B $((12 * 1024))B $((16 * 1024))B $((20 * 1024))B $((24 * 1024))B $((28 * 1024))B $((32 * 1024))B)

TABLE_NAME="$ABS_PATH/performance-comparison-table-bsize"
table_create "$TABLE_NAME" "ops file_system file_size blk_size bandwidth(MiB/s)"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i = 1; i <= loop; i++)); do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for fsize in "${FILE_SIZES[@]}"; do
            for bsize in "${BLK_SIZES[@]}"; do
                if [[ "${file_system}" == "PMM" ]]; then
                    BW=2259.2
                elif [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test "$bsize" "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "KILLER-AVX" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "KILLER" "osdi25-avx" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test "$bsize" "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs="$bsize" -size="$fsize"M -name=test | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "MadFS" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
                    BW=$(LD_PRELOAD=$MADFS_DIR/build-release/libmadfs.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs="$bsize" -size="$fsize"M -name=test | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test "$bsize" "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                table_add_row "$TABLE_NAME" "seq-write $file_system $fsize $bsize $BW"

                if [[ "${file_system}" == "PMM" ]]; then
                    BW=2259.2
                elif [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
                    BW=$(bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test "$bsize" "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "KILLER-AVX" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "KILLER" "osdi25-avx" "0"
                    BW=$(bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test "$bsize" "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=randwrite -ioengine=sync -bs="$bsize" -size="$fsize"M -name=test | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "MadFS" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
                    BW=$(LD_PRELOAD=$MADFS_DIR/build-release/libmadfs.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=randwrite -ioengine=sync -bs="$bsize" -size="$fsize"M -name=test | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    BW=$(bash "$TOOLS_PATH"/fio-rand.sh /mnt/pmem0/test "$bsize" "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                table_add_row "$TABLE_NAME" "rnd-write $file_system $fsize $bsize $BW"

                if [[ "${file_system}" == "PMM" ]]; then
                    BW=2483.2
                elif [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test "$bsize" "$fsize" 1 "read" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "KILLER-AVX" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "KILLER" "osdi25-avx" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test "$bsize" "$fsize" 1 "read" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=read -ioengine=sync -bs="$bsize" -size="$fsize"M -name=test | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "MadFS" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
                    BW=$(LD_PRELOAD=$MADFS_DIR/build-release/libmadfs.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=read -ioengine=sync -bs="$bsize" -size="$fsize"M -name=test | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test "$bsize" "$fsize" 1 "read" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                table_add_row "$TABLE_NAME" "seq-read $file_system $fsize $bsize $BW"

                if [[ "${file_system}" == "PMM" ]]; then
                    BW=2483.2
                elif [[ "${file_system}" == "KILLER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "osdi25" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test "$bsize" "$fsize" 1 "randread" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "KILLER-AVX" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "KILLER" "osdi25-avx" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test "$bsize" "$fsize" 1 "randread" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH="$BOOST_DIR"
                    export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
                    BW=$(LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=randread -ioengine=sync -bs="$bsize" -size="$fsize"M -name=test | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                elif [[ "${file_system}" == "MadFS" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "0"
                    export LD_LIBRARY_PATH=/usr/local/lib64:$LD_LIBRARY_PATH
                    BW=$(LD_PRELOAD=$MADFS_DIR/build-release/libmadfs.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=randread -ioengine=sync -bs="$bsize" -size="$fsize"M -name=test | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test "$bsize" "$fsize" 1 "randread" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                fi
                table_add_row "$TABLE_NAME" "rnd-read $file_system $fsize $bsize $BW"
            done
        done
    done
done
