#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
set -x
FILE_SYSTEMS=("XFS" "F2FS" "EXT4" "KILLER")
FILE_SIZES=($((1 * 1024)))

BS_SIZES=($((4 * 1024)) $((8 * 1024)) $((12 * 1024)) $((16 * 1024)) $((20 * 1024)) $((24 * 1024)) $((28 * 1024)) $((32 * 1024)) $((36 * 1024)) $((40 * 1024)) $((44 * 1024)))

RW=("write" "randwrite")
SYNC_META=("0")
PREALLOC=("0")

TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "ops file_system blk_size bandwidth(MiB/s)"

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i = 1; i <= loop; i++)); do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for fsize in "${FILE_SIZES[@]}"; do
            for bsize in "${BS_SIZES[@]}"; do
                for rw in "${RW[@]}"; do
                    for pre_alloc in "${PREALLOC[@]}"; do
                        for sync_meta in "${SYNC_META[@]}"; do
                            if [[ "${file_system}" == "RAW" ]]; then
                                engine="io-ring"
                            else
                                engine="io-ring-sqpoll"
                            fi

                            if [[ "${sync_meta}" == "0" ]]; then
                                fio_tool="$TOOLS_PATH"/fio-$engine.sh
                                op="$rw-data"
                            else
                                fio_tool="$TOOLS_PATH"/fio-$engine-fsync.sh
                                op="$rw-meta+data"
                            fi

                            if [[ "${pre_alloc}" == "0" ]]; then
                                op+="-no-prealloc"
                            else
                                op+="-alloc-for-write"
                            fi

                            sync /dev/nvme0n1p1
                            umount /mnt/nvme0n1p1

                            if [[ "${file_system}" == "KILLER" ]]; then
                                cd ../../../killer-nvme/ || exit

                                if [[ "${sync_meta}" == "0" ]]; then
                                    make clean && make MODE=0 -j32
                                else
                                    make clean && make MODE=1 -j32
                                fi

                                if [[ $rw == "read" || $rw == "randread" ]]; then
                                    BW=$(sudo bash scripts/run_killer.sh fio -filename="\a" -fallocate=none -direct=0 -iodepth 1 -rw="$rw" -ioengine=sync -bs="$bsize" -size="$fsize"M -name=read -thread | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                                else
                                    BW=$(sudo bash scripts/run_killer.sh fio -filename="\a" -fallocate=none -direct=0 -iodepth 1 -rw="$rw" -ioengine=sync -bs="$bsize" -size="$fsize"M -name=write -thread | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                                fi
                                cd - || exit
                            else
                                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" 0
                                if [[ $rw == "read" || $rw == "randread" ]]; then
                                    BW=$(bash "$fio_tool" /mnt/nvme0n1p1/test "$bsize" "$fsize" 1 "$pre_alloc" "$rw" | grep READ: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                                else
                                    BW=$(bash "$fio_tool" /mnt/nvme0n1p1/test "$bsize" "$fsize" 1 "$pre_alloc" "$rw" | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
                                fi
                            fi

                            table_add_row "$TABLE_NAME" "$op $file_system $bsize $BW"
                        done
                    done
                done
            done
        done
    done
done
