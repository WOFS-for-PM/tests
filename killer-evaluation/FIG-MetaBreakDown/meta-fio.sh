#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
source "./measure_pm_ionum.sh"
source "./extractor.sh"

ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

# FILE_SYSTEMS=( "NOVA" "PMFS" "KILLER")
FILE_SYSTEMS=( "KILLER" )
WORKLOADS=("write" "read" "randwrite")
FILE_SIZE="32G"

TABLE_NAME_NOVA="$ABS_PATH/performance-comparison-table-NOVA"
table_create "$TABLE_NAME_NOVA" "workloads meta_read(bytes) meta_write(bytes) meta_total(bytes) meta_time(ns) meta_times data_write(bytes) data_read(bytes) data_write_time(ns) data_read_time(ns) data_time(ns) media_read(byte) media_write(byte) IO_time(ns) update_entry_time(ns) update_inode_time(ns) journal_time(ns) update_page_tail_time(ns)"

TABLE_NAME_PMFS="$ABS_PATH/performance-comparison-table-PMFS"
table_create "$TABLE_NAME_PMFS" "workloads meta_read(bytes) meta_write(bytes) meta_total(bytes) meta_time(ns) meta_times data_write(bytes) data_read(bytes) data_write_time(ns) data_read_time(ns) data_time(ns) media_read(byte) media_write(byte) IO_time(ns) update_index_time(ns) update_inode_time(ns) journal_time(ns) update_dentry_time(ns)"

TABLE_NAME_KILLER="$ABS_PATH/performance-comparison-table-KILLER"
table_create "$TABLE_NAME_KILLER" "workloads meta_read(bytes) meta_write(bytes) meta_total(bytes) meta_time(ns) meta_times data_write(bytes) data_read(bytes) data_write_time(ns) data_read_time(ns) data_time(ns) media_read(byte) media_write(byte) IO_time(ns) update_package_time(ns) update_bm_time(ns)"

STEP=0

mkdir -p "$ABS_PATH"/M_DATA/fio

PMEM_ID=$(get_pmem_id_by_name "pmem0")

for file_system in "${FILE_SYSTEMS[@]}"; do
    for workload in "${WORKLOADS[@]}"; do
        if [[ "${file_system}" == "NOVA" ]]; then
            bash "$TOOLS_PATH"/setup.sh "$file_system" "meta-trace" "1"
        elif [[ "${file_system}" == "PMFS" ]]; then
            bash "$TOOLS_PATH"/setup.sh "$file_system" "meta-trace" "1"
        elif [[ "${file_system}" == "KILLER" ]]; then
            bash "$TOOLS_PATH"/setup.sh "$file_system" "meta-trace" "1"
        else
            echo  file_system_type: $file_system
            continue
        fi

        measure_start ${PMEM_ID}

        BW=$(sudo fio -filename=/mnt/pmem0/test -fallocate=none -direct=0 -iodepth 1 -rw=$workload \
        -ioengine=sync -bs="4k" -thread -numjobs=1 -size=$FILE_SIZE -name=test \
        | grep WRITE: | awk '{print $2}' | sed 's/bw=//g')

        mkdir -p "$ABS_PATH"/M_DATA/fio/${workload}

        measure_end ${PMEM_ID} > "$ABS_PATH"/M_DATA/fio/${workload}/${file_system}

        dmesg -c

        sudo umount /mnt/pmem0

        echo sleep for 1 sec
        sleep 1

        sudo dmesg >> "$ABS_PATH"/M_DATA/fio/${workload}/${file_system}
        sed -i 's/\[\s*\([0-9]\)/[\1/g' "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} 

        meta_read=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "meta_read")
        meta_write=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "meta_write")
        meta_total=$((meta_read + meta_write))
        meta_time=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "meta_time")
        meta_times=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "meta_times")
        data_write=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "data_write")
        data_read=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "data_read")
        data_write_time=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "data_write_time")
        data_read_time=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "data_read_time")
        data_time=$((data_write_time + data_read_time))
        
        media_read=$(extract_media_IO_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "read")
        media_write=$(extract_media_IO_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "write")

        if [[ "${file_system}" == "NOVA" ]]; then
            IO_time=$(extract_nova_IO_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_entry_time=$(extract_nova_update_entry_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_inode_time=$(extract_nova_update_inode_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            journal_time=$(extract_nova_journal_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_page_tail_time=$(extract_nova_update_page_tail_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            
            table_add_row "$TABLE_NAME_NOVA" "${workload} ${meta_read} ${meta_write} ${meta_total} ${meta_time} ${meta_times} ${data_write} ${data_read} ${data_write_time} ${data_read_time} ${data_time} ${media_read} ${media_write} ${IO_time} ${update_entry_time} ${update_inode_time} ${journal_time} ${update_page_tail_time}"
        elif [[ "${file_system}" == "PMFS" ]]; then
            IO_time=$(extract_pmfs_IO_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_index_time=$(extract_pmfs_update_index_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_inode_time=$(extract_pmfs_update_inode_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            journal_time=$(extract_pmfs_journal_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_dentry_time=$(extract_pmfs_update_dentry_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})

            table_add_row "$TABLE_NAME_PMFS" "${workload} ${meta_read} ${meta_write} ${meta_total} ${meta_time} ${meta_times} ${data_write} ${data_read} ${data_write_time} ${data_read_time} ${data_time} ${media_read} ${media_write} ${IO_time} ${update_index_time} ${update_inode_time} ${journal_time} ${update_dentry_time}"

        elif [[ "${file_system}" == "KILLER" ]]; then
            IO_time=$(extract_killer_IO_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_package_time=$(extract_killer_update_package_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_bm_time=$(extract_killer_update_bm_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})

            table_add_row "$TABLE_NAME_KILLER" "${workload} ${meta_read} ${meta_write} ${meta_total} ${meta_time} ${meta_times} ${data_write} ${data_read} ${data_write_time} ${data_read_time} ${data_time} ${media_read} ${media_write} ${IO_time} ${update_package_time} ${update_bm_time}"
        else
            echo file_system_type: $file_system
            continue
        fi
        STEP=$((STEP + 1))
    done
done