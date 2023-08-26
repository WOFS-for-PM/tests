#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
source "./measure_pm_ionum.sh"
source "./extractor.sh"

ABS_PATH=$(where_is_script "$0")
tools_path=$ABS_PATH/../../tools
filebench=/usr/local/filebench/filebench
workload_dir=$tools_path/fbscripts/
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts

TABLE_NAME_NOVA="$ABS_PATH/performance-comparison-table-NOVA"

TABLE_NAME_PMFS="$ABS_PATH/performance-comparison-table-PMFS"

TABLE_NAME_KILLER="$ABS_PATH/performance-comparison-table-KILLER"

# FILE_SYSTEMS=("NOVA" "PMFS" "KILLER")
FILE_SYSTEMS=( "KILLER" )
WORKLOADS=("fileserver.f" "varmail.f" "webserver.f" "webproxy.f")
THREAD=1
mkdir -p "$ABS_PATH"/M_DATA/filebench
mkdir -p "$ABS_PATH"/DATA/

STEP=0

PMEM_ID=$(get_pmem_id_by_name "pmem0")

for file_system in "${FILE_SYSTEMS[@]}"; do
    for workload in "${WORKLOADS[@]}"; do
        if [[ "${file_system}" == "NOVA" ]]; then
            bash "$tools_path"/setup.sh "$file_system" "meta-trace" "1"
        elif [[ "${file_system}" == "PMFS" ]]; then
            bash "$tools_path"/setup.sh "$file_system" "meta-trace" "1"
        elif [[ "${file_system}" == "KILLER" ]]; then
            bash "$tools_path"/setup.sh "$file_system" "meta-trace" "1"
        else
            echo file_system_type: $file_system
            continue
        fi

        mkdir -p "$ABS_PATH"/DATA/"$workload"
        cp -f "$FSCRIPT_PRE_FIX"/"$workload" "$ABS_PATH"/DATA/"$workload"/"$THREAD" 
        sed_cmd='s/set $nthreads=.*$/set $nthreads='$THREAD'/g' 
        sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$workload"/"$THREAD"
        sed_cmd='s/run .*$/run 60/g' 
        sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$workload"/"$THREAD"

        measure_start ${PMEM_ID}

        IOps=$(sudo $filebench -f "$ABS_PATH"/DATA/"$workload"/"$THREAD" | grep "IO Summary" | awk -F'[[:space:]]' '{print $6}')

        mkdir -p "$ABS_PATH"/M_DATA/filebench/${workload}
        measure_end ${PMEM_ID} > "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system}

        dmesg -c

        sudo umount /mnt/pmem0

        echo sleep for 1 sec
        sleep 1

        sudo dmesg >> "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system}
        
        sed -i 's/\[\s*\([0-9]\)/[\1/g' "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} 
        
        meta_read=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "meta_read")
        meta_write=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "meta_write")
        meta_total=$((meta_read + meta_write))
        meta_time=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "meta_time")
        meta_times=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "meta_times")
        data_write=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "data_write")
        data_read=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "data_read")
        data_write_time=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "data_write_time")
        data_read_time=$(extract_software_IO_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "data_read_time")
        data_time=$((data_write_time + data_read_time))
        
        media_read=$(extract_media_IO_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "read")
        media_write=$(extract_media_IO_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "write")

        if [[ "${file_system}" == "NOVA" ]]; then
            IO_time=$(extract_nova_IO_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_entry_time=$(extract_nova_update_entry_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_inode_time=$(extract_nova_update_inode_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            journal_time=$(extract_nova_journal_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_page_tail_time=$(extract_nova_update_page_tail_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})

            table_add_row "$TABLE_NAME_NOVA" "${workload} ${meta_read} ${meta_write} ${meta_total} ${meta_time} ${meta_times} ${data_write} ${data_read} ${data_write_time} ${data_read_time} ${data_time} ${media_read} ${media_write} ${IO_time} ${update_entry_time} ${update_inode_time} ${journal_time} ${update_page_tail_time}"
        elif [[ "${file_system}" == "PMFS" ]]; then
            IO_time=$(extract_pmfs_IO_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_index_time=$(extract_pmfs_update_index_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_inode_time=$(extract_pmfs_update_inode_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            journal_time=$(extract_pmfs_journal_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_dentry_time=$(extract_pmfs_update_dentry_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})

            table_add_row "$TABLE_NAME_PMFS" "${workload} ${meta_read} ${meta_write} ${meta_total} ${meta_time} ${meta_times} ${data_write} ${data_read} ${data_write_time} ${data_read_time} ${data_time} ${media_read} ${media_write} ${IO_time} ${update_index_time} ${update_inode_time} ${journal_time} ${update_dentry_time}"

        elif [[ "${file_system}" == "KILLER" ]]; then
            IO_time=$(extract_killer_IO_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_package_time=$(extract_killer_update_package_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_bm_time=$(extract_killer_update_bm_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})

            table_add_row "$TABLE_NAME_KILLER" "${workload} ${meta_read} ${meta_write} ${meta_total} ${meta_time} ${meta_times} ${data_write} ${data_read} ${data_write_time} ${data_read_time} ${data_time} ${media_read} ${media_write} ${IO_time} ${update_package_time} ${update_bm_time}"
        else
            echo file_system_type: $file_system
            continue
        fi

        STEP=$((STEP + 1))
    done
done
