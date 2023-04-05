#!/usr/bin/bash
# shellcheck source=/dev/null
source "./common.sh"
ABS_PATH=$(where_is_script "$0")
tools_path=$ABS_PATH/../../tools
filebench=/usr/local/filebench/filebench
workload_dir=$tools_path/fbscripts/

FILE_SYSTEMS=( "NOVA" "PMFS" "HUNTER")
WORKLOADS=("fileserver.f" "varmail.f" "webserver.f" "webproxy.f")
TABLE_NAME="$ABS_PATH/metadata-trace-filebench-results"
table_create "$TABLE_NAME" "file_system workload meta_read(bytes) meta_write(bytes) meta_total(bytes) meta_time(ns) meta_times data_write(bytes) data_read(bytes) data_write_time(ns) data_read_time(ns) IOps(ops/s)"

mkdir -p "$ABS_PATH"/M_DATA/filebench

STEP=0


for file_system in "${FILE_SYSTEMS[@]}"; do
    for workload in "${WORKLOADS[@]}"; do
        if [[ "${file_system}" == "NOVA" ]]; then
                bash "$tools_path"/setup.sh "$file_system" "meta-trace" "1"
        elif [[ "${file_system}" == "PMFS" ]]; then
            bash "$tools_path"/setup.sh "$file_system" "meta-trace" "1"
        elif [[ "${file_system}" == "HUNTER" ]]; then
            echo TODO: setup HUNTER
            continue
        else
            echo  file_system_type: $file_system
            continue
        fi

        IOps=$(sudo $filebench -f $workload_dir/$workload | grep "IO Summary" | awk -F'[[:space:]]' '{print $6}')

        sudo umount /mnt/pmem0

        echo sleep for 1 sec
        sleep 1

        sudo dmesg | tail -n 20 > "$ABS_PATH"/M_DATA/filebench/OUTPUT${STEP}

        meta_read_size=$(attr_meta_stats "meta_read" "$ABS_PATH"/M_DATA/filebench/OUTPUT${STEP})
        meta_write_size=$(attr_meta_stats "meta_write" "$ABS_PATH"/M_DATA/filebench/OUTPUT${STEP})
        meta_total_size=`expr $meta_read_size + $meta_write_size`
        meta_time=$(attr_meta_stats "meta_time" "$ABS_PATH"/M_DATA/filebench/OUTPUT${STEP})
        meta_times=$(attr_meta_stats "meta_times" "$ABS_PATH"/M_DATA/filebench/OUTPUT${STEP})
        data_write_size=$(attr_meta_stats "data_write" "$ABS_PATH"/M_DATA/filebench/OUTPUT${STEP})
        data_read_size=$(attr_meta_stats "data_read" "$ABS_PATH"/M_DATA/filebench/OUTPUT${STEP})
        data_write_time=$(attr_meta_stats "data_write_time" "$ABS_PATH"/M_DATA/filebench/OUTPUT${STEP})
        data_read_time=$(attr_meta_stats "data_read_time" "$ABS_PATH"/M_DATA/filebench/OUTPUT${STEP})

        table_add_row "$TABLE_NAME" "$file_system $workload $meta_read_size $meta_write_size $meta_total_size $meta_time \
$meta_times $data_write_size $data_read_size $data_write_time $data_read_time $IOps" 
        STEP=$((STEP + 1))
    done
done