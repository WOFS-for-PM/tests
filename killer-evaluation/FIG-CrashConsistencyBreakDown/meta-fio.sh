#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
source "./measure_pm_ionum.sh"
source "./extractor.sh"

ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools
BOOST_DIR=$ABS_PATH/../../../splitfs/splitfs

FILE_SYSTEMS=("NOVA" "PMFS" "KILLER" "SplitFS-FIO" )
# FILE_SYSTEMS=( "SplitFS-FIO" )
WORKLOADS=("write" "read" "randwrite")
FILE_SIZE="32G"

TABLE_NAME_NOVA="$ABS_PATH/performance-comparison-table-NOVA"
table_create "$TABLE_NAME_NOVA" "workloads D(ns) JM(ns) JC(ns) GC(ns)"

TABLE_NAME_PMFS="$ABS_PATH/performance-comparison-table-PMFS"
table_create "$TABLE_NAME_PMFS" "workloads D(ns) JM(ns) JC(ns) M(ns)"

TABLE_NAME_KILLER="$ABS_PATH/performance-comparison-table-KILLER"
table_create "$TABLE_NAME_KILLER" "workloads D(ns) JM|JC(ns) M(ns)"

TABLE_NAME_SplitFS="$ABS_PATH/performance-comparison-table-SplitFS"
table_create "$TABLE_NAME_SplitFS" "workloads D(ns) JM|JC(ns) M(ns)"

STEP=0

mkdir -p "$ABS_PATH"/M_DATA/fio

PMEM_ID=$(get_pmem_id_by_name "pmem0")

for file_system in "${FILE_SYSTEMS[@]}"; do
    for workload in "${WORKLOADS[@]}"; do
        # if [[ "${file_system}" == "NOVA" ]]; then
        #     bash "$TOOLS_PATH"/setup.sh "$file_system" "meta-trace" "1"
        # elif [[ "${file_system}" == "PMFS" ]]; then
        #     bash "$TOOLS_PATH"/setup.sh "$file_system" "meta-trace" "1"
        # elif [[ "${file_system}" =~ "KILLER" ]]; then
        #     bash "$TOOLS_PATH"/setup.sh "$file_system" "meta-trace" "1"
        # elif [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
        #     bash "$TOOLS_PATH"/setup.sh "$file_system" "null" "1"
        # else
        #     echo  file_system_type: $file_system
        #     continue
        # fi

        # measure_start ${PMEM_ID}

        # if [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
        #     export LD_LIBRARY_PATH="$BOOST_DIR"
        #     export NVP_TREE_FILE="$BOOST_DIR"/bin/nvp_nvp.tree
        #     LD_PRELOAD=$BOOST_DIR/libnvp.so fio -filename="/mnt/pmem0/test" -fallocate=none -direct=0 -iodepth 1 -rw=$workload -ioengine=sync -bs="4K" -size="$FILE_SIZE" -name=test > /tmp/splitfs_fio_output 2>&1
        # else
        #     BW=$(sudo fio -filename=/mnt/pmem0/test -fallocate=none -direct=0 -iodepth 1 -rw=$workload \
        #     -ioengine=sync -bs="4k" -thread -numjobs=1 -size=$FILE_SIZE -name=test \
        #     | grep WRITE: | awk '{print $2}' | sed 's/bw=//g')
        # fi

        # mkdir -p "$ABS_PATH"/M_DATA/fio/${workload}

        # measure_end ${PMEM_ID} > "$ABS_PATH"/M_DATA/fio/${workload}/${file_system}

        # dmesg -c

        # sudo umount /mnt/pmem0

        # echo sleep for 1 sec
        # sleep 1

        # if [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
        #     cat /tmp/splitfs_fio_output >> "$ABS_PATH"/M_DATA/fio/${workload}/${file_system}
        # else
        #     sudo dmesg >> "$ABS_PATH"/M_DATA/fio/${workload}/${file_system}
        #     sed -i 's/\[\s*\([0-9]\)/[\1/g' "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} 
        # fi

        if [[ "${file_system}" == "NOVA" ]]; then
            IO_time=$(extract_nova_IO_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_entry_time=$(extract_nova_update_entry_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_inode_time=$(extract_nova_update_inode_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_page_tail_time=$(extract_nova_update_page_tail_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            
            table_add_row "$TABLE_NAME_NOVA" "${workload} ${IO_time} ${update_entry_time} ${update_inode_time} ${update_page_tail_time}"
        elif [[ "${file_system}" == "PMFS" ]]; then
            IO_time=$(extract_pmfs_IO_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            journal_time=$(extract_pmfs_journal_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            commit_time=$(extract_pmfs_commit_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_index_time=$(extract_pmfs_update_index_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_inode_time=$(extract_pmfs_update_inode_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_dentry_time=$(extract_pmfs_update_dentry_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            meta_time=$((update_index_time+update_inode_time+update_dentry_time))
            table_add_row "$TABLE_NAME_PMFS" "${workload} ${IO_time} ${journal_time} ${commit_time} ${meta_time}"
        elif [[ "${file_system}" =~ "KILLER" ]]; then
            IO_time=$(extract_killer_IO_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_package_time=$(extract_killer_update_package_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})
            update_bm_time=$(extract_killer_update_bm_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system})

            table_add_row "$TABLE_NAME_KILLER" "${workload} ${IO_time} ${update_package_time} ${update_bm_time}"
        elif [[ "${file_system}" =~ "SplitFS-FIO" ]]; then
            IO_time=$(extract_splitfs_IO_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "FIO")
            journal_time=$(extract_splitfs_journal_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "FIO")
            tot_time=$(extract_splitfs_total_op_time_from_output "$ABS_PATH"/M_DATA/fio/${workload}/${file_system} "FIO")
            meta_time=$((tot_time - journal_time - IO_time))
            echo $IO_time $journal_time $meta_time
            table_add_row "$TABLE_NAME_SplitFS" "${workload} ${IO_time} ${journal_time} ${meta_time}"
        else
            echo file_system_type: $file_system
            continue
        fi
        STEP=$((STEP + 1))
    done
done