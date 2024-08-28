#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
source "./measure_pm_ionum.sh"
source "./extractor.sh"

ABS_PATH=$(where_is_script "$0")
tools_path=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs
filebench=/usr/local/filebench/filebench
workload_dir=$tools_path/fbscripts/
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts

TABLE_NAME_NOVA="$ABS_PATH/performance-comparison-table-NOVA"

TABLE_NAME_PMFS="$ABS_PATH/performance-comparison-table-PMFS"

TABLE_NAME_KILLER="$ABS_PATH/performance-comparison-table-KILLER"

TABLE_NAME_SplitFS="$ABS_PATH/performance-comparison-table-SplitFS"

# FILE_SYSTEMS=("NOVA" "PMFS" "KILLER" "KILLER-NO-PREFETCH" "KILLER-NAIVE" )
# FILE_SYSTEMS=("KILLER" "KILLER-NO-PREFETCH" "KILLER-NAIVE" )

FILE_SYSTEMS=("NOVA" "PMFS" "KILLER" "SplitFS-FILEBENCH" )
# FILE_SYSTEMS=( "SplitFS-FILEBENCH" )
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
        elif [[ "${file_system}" =~ "KILLER" ]]; then
            bash "$tools_path"/setup.sh "$file_system" "meta-trace" "1"
        elif [[ "${file_system}" =~ "SplitFS-FILEBENCH" ]]; then
            bash "$tools_path"/setup.sh "$file_system" "null" "1"
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

        if [[ "${file_system}" == "SplitFS-FILEBENCH" ]]; then
            bash "$tools_path"/setup.sh "$file_system" "null" "1"
            export LD_LIBRARY_PATH="$BOOST_DIR"
            export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
            LD_PRELOAD=$BOOST_DIR/libnvp.so $filebench -f "$ABS_PATH"/DATA/"$workload"/"$THREAD" > /tmp/splitfs_filebench_output 2>&1
        else
            IOps=$(sudo $filebench -f "$ABS_PATH"/DATA/"$workload"/"$THREAD" | grep "IO Summary" | awk -F'[[:space:]]' '{print $6}')
        fi

        mkdir -p "$ABS_PATH"/M_DATA/filebench/${workload}
        measure_end ${PMEM_ID} > "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system}

        dmesg -c

        sudo umount /mnt/pmem0

        echo sleep for 1 sec
        sleep 1

        if [[ "${file_system}" == "SplitFS-FILEBENCH" ]]; then
            cat /tmp/splitfs_filebench_output >> "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system}
        else
            sudo dmesg >> "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system}        
            sed -i 's/\[\s*\([0-9]\)/[\1/g' "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} 
        fi

        if [[ "${file_system}" == "NOVA" ]]; then
            IO_time=$(extract_nova_IO_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_entry_time=$(extract_nova_update_entry_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_inode_time=$(extract_nova_update_inode_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_page_tail_time=$(extract_nova_update_page_tail_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            
            table_add_row "$TABLE_NAME_NOVA" "${workload} ${IO_time} ${update_entry_time} ${update_inode_time} ${update_page_tail_time}"
        elif [[ "${file_system}" == "PMFS" ]]; then
            IO_time=$(extract_pmfs_IO_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            journal_time=$(extract_pmfs_journal_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            commit_time=$(extract_pmfs_commit_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_index_time=$(extract_pmfs_update_index_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_inode_time=$(extract_pmfs_update_inode_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_dentry_time=$(extract_pmfs_update_dentry_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            meta_time=$((update_index_time+update_inode_time+update_dentry_time))
            table_add_row "$TABLE_NAME_PMFS" "${workload} ${IO_time} ${journal_time} ${commit_time} ${meta_time}"
        elif [[ "${file_system}" =~ "KILLER" ]]; then
            IO_time=$(extract_killer_IO_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_package_time=$(extract_killer_update_package_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})
            update_bm_time=$(extract_killer_update_bm_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system})

            table_add_row "$TABLE_NAME_KILLER" "${workload} ${IO_time} ${update_package_time} ${update_bm_time}"
        elif [[ "${file_system}" =~ "SplitFS-FILEBENCH" ]]; then
            IO_time=$(extract_splitfs_IO_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "FILEBENCH")
            journal_time=$(extract_splitfs_journal_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "FILEBENCH")
            tot_time=$(extract_splitfs_total_op_time_from_output "$ABS_PATH"/M_DATA/filebench/${workload}/${file_system} "FILEBENCH")
            meta_time=$((tot_time - journal_time - IO_time))
            table_add_row "$TABLE_NAME_SplitFS" "${workload} ${IO_time} ${journal_time} ${meta_time}"
        else
            echo file_system_type: $file_system
            continue
        fi

        STEP=$((STEP + 1))
    done
done
