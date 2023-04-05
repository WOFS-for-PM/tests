#!/usr/bin/bash
# shellcheck source=/dev/null
source "./common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

FILE_SYSTEMS=( "NOVA" "PMFS" "HUNTER")
PATTERNS=("write" "randwrite")
FILE_SIZE="32G"
TABLE_NAME="$ABS_PATH/metadata-trace-fio-results"
table_create "$TABLE_NAME" "file_system meta_read(bytes) meta_write(bytes) meta_total(bytes) meta_time(ns) meta_times data_write(bytes) data_time(ns) COW_time(ns) bandwidth(MiB/s)"
STEP=0

mkdir -p "$ABS_PATH"/M_DATA/fio


for file_system in "${FILE_SYSTEMS[@]}"; do
    for pattern in "${PATTERNS[@]}"; do
        if [[ "${file_system}" == "NOVA" ]]; then
            bash "$TOOLS_PATH"/setup.sh "$file_system" "meta-trace" "1"
        elif [[ "${file_system}" == "PMFS" ]]; then
            bash "$TOOLS_PATH"/setup.sh "$file_system" "meta-trace" "1"
        elif [[ "${file_system}" == "HUNTER" ]]; then
            echo TODO: setup HUNTER
            continue
        else
            echo  file_system_type: $file_system
            continue
        fi

        BW=$(sudo fio -filename=/mnt/pmem0/test -fallocate=none -direct=0 -iodepth 1 -rw=$pattern \
        -ioengine=sync -bs="4k" -thread -numjobs=1 -size=$FILE_SIZE -name=test \
        | grep WRITE: | awk '{print $2}' | sed 's/bw=//g')
        
        sudo umount /mnt/pmem0

        echo sleep for 1 sec
        sleep 1

        sudo dmesg | tail -n 20 > "$ABS_PATH"/M_DATA/fio/OUTPUT${STEP}

        meta_read_size=$(attr_meta_stats "meta_read" "$ABS_PATH"/M_DATA/fio/OUTPUT${STEP})
        meta_write_size=$(attr_meta_stats "meta_write" "$ABS_PATH"/M_DATA/fio/OUTPUT${STEP})
        meta_total_size=`expr $meta_read_size + $meta_write_size`
        meta_time=$(attr_meta_stats "meta_time" "$ABS_PATH"/M_DATA/fio/OUTPUT${STEP})
        meta_times=$(attr_meta_stats "meta_times" "$ABS_PATH"/M_DATA/fio/OUTPUT${STEP})
        data_write_size=$(attr_meta_stats "data_write" "$ABS_PATH"/M_DATA/fio/OUTPUT${STEP})
        data_time=$(attr_meta_stats "data_write_time" "$ABS_PATH"/M_DATA/fio/OUTPUT${STEP})
        COW_time=$(attr_meta_stats "COW_time" "$ABS_PATH"/M_DATA/fio/OUTPUT${STEP})

        table_add_row "$TABLE_NAME" "$file_system $pattern $meta_read_size $meta_write_size $meta_total_size $meta_time \
$meta_times $data_write_size $data_time $COW_time $BW" 
        STEP=$((STEP + 1))
    done
done