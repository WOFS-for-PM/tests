#!/usr/bin/env bash
source "../common.sh"

function extract_media_IO_from_output() {
    local output="$1"
    local rw="$2"

    if [[ "${rw}" == "read" ]]; then
        cat "$output" | grep "MediaReads" | awk -F= '{print $1}' | sed 's/MediaReads //g'
    elif [[ "${rw}" == "write" ]]; then
        cat "$output" | grep "MediaWrites" | awk -F= '{print $1}' | sed 's/MediaWrites //g'
    else
        echo "Error: Unknown rw: ${rw}"
        exit 1
    fi
}

function extract_software_IO_from_output() {
    local output="$1"
    local stat="$2"
    
    cat "$output" | grep -w "$stat" | awk -F: '{print $3}' | sed 's/ //g'
}

function extract_nova_IO_time_from_output() {
    local output="$1"
    
    read=$(nova_attr_time "memcpy_read_nvmm" "$output")
    write=$(nova_attr_time "memcpy_write_nvmm" "$output")
    echo $((read + write))
}

function extract_nova_update_entry_time_from_output() {
    local output="$1"
    read_entry=$(nova_attr_time "read_entry" "$output")
    write_entry=$(nova_attr_time "write_entry" "$output")
    read_entry_trans_id=$(nova_attr_time "read_entry_trans_id" "$output")
    read_entry_type=$(nova_attr_time "read_entry_type" "$output")
    read_entry_epoch=$(nova_attr_time "read_entry_epoch" "$output")

    echo $((read_entry+write_entry+read_entry_trans_id+read_entry_type+read_entry_epoch))
}

function extract_nova_update_page_tail_time_from_output() {
    local output="$1"
    read_page_tail=$(nova_attr_time "read_page_tail" "$output")
    write_page_tail=$(nova_attr_time "write_page_tail" "$output")
    echo $((read_page_tail+write_page_tail))
}

function extract_nova_update_inode_time_from_output() {
    local output="$1"
    read_pi=$(nova_attr_time "read_pi" "$output")
    write_pi=$(nova_attr_time "write_pi" "$output")
    write_pi_log_ptr=$(nova_attr_time "write_pi_log_ptr" "$output")
    update_pi_tail=$(nova_attr_time "update_pi_tail" "$output")
    echo $((read_pi+write_pi+write_pi_log_ptr+update_pi_tail))
}

function extract_nova_journal_time_from_output() {
    local output="$1"
    write_journal=$(nova_attr_time "write_journal" "$output")
    update_journal_ptr=$(nova_attr_time "update_journal_ptr" "$output")
    echo $((write_journal+update_journal_ptr))
}

function extract_pmfs_IO_time_from_output() {
    local output="$1"
    read=$(pmfs_attr_time "memcpy_read" "$output")
    write=$(pmfs_attr_time "memcpy_write" "$output")
    echo $(( read + write ))
}

function extract_pmfs_update_index_time_from_output() {
    local output="$1"
    find=$(pmfs_attr_time "find_block" "$output")
    read=$(pmfs_attr_time "read_meta_block" "$output")
    write=$(pmfs_attr_time "write_meta_block" "$output")
    echo $(( find + read + write ))    
}

function extract_pmfs_update_inode_time_from_output() {
    local output="$1"
    read_pi_i_blk_type=$(pmfs_attr_time "read_pi_i_blk_type" "$output")
    read_pi_height=$(pmfs_attr_time "read_pi_height" "$output")
    read_pi_i_blocks=$(pmfs_attr_time "read_pi_i_blocks" "$output")
    read_pi_i_flags=$(pmfs_attr_time "read_pi_i_flags" "$output")
    read_pi_attr=$(pmfs_attr_time "read_pi_attr" "$output")
    read_pi=$(pmfs_attr_time "read_pi" "$output")
    check_pi_free=$(pmfs_attr_time "check_pi_free" "$output")
    write_pi_time_and_size=$(pmfs_attr_time "write_pi_time_and_size" "$output")
    write_pi_time=$(pmfs_attr_time "write_pi_time" "$output")
    write_pi_size=$(pmfs_attr_time "write_pi_size" "$output")
    write_pi_root=$(pmfs_attr_time "write_pi_root" "$output")
    write_pi_height=$(pmfs_attr_time "write_pi_height" "$output")
    write_pi_i_blocks=$(pmfs_attr_time "write_pi_i_blocks" "$output")
    write_pi_links=$(pmfs_attr_time "write_pi_links" "$output")
    write_pi=$(pmfs_attr_time "write_pi" "$output")
    echo $((read_pi_i_blk_type+read_pi_height+read_pi_i_blocks+read_pi_i_flags+read_pi_attr+read_pi+check_pi_free+write_pi_time_and_size+write_pi_time+write_pi_size+write_pi_root+write_pi_height+write_pi_i_blocks+write_pi_links+write_pi))
}

function extract_pmfs_journal_time_from_output() {
    local output="$1"
    new_trans=$(pmfs_attr_time "new_trans" "$output")
    add_logentry=$(pmfs_attr_time "add_logentry" "$output")
    commit_trans=$(pmfs_attr_time "commit_trans" "$output")
    echo $((new_trans + add_logentry + commit_trans)) 
}

function extract_pmfs_update_dentry_time_from_output() {
    local output="$1"
    read_dentry=$(pmfs_attr_time "read_dentry" "$output")
    write_dentry=$(pmfs_attr_time "write_dentry" "$output")
    echo $((read_dentry+write_dentry))
}

function extract_killer_IO_time_from_output() {
    local output="$1"
    
    read=$(killer_attr_time "memcpy_read_nvmm" "$output")
    write=$(killer_attr_time "memcpy_write_nvmm" "$output")
    echo $((read + write))
}

function extract_killer_update_package_time_from_output() {
    local output="$1"
    create_inode_package=$(killer_attr_time "create_inode_package" "$output")
    create_data_package=$(killer_attr_time "create_data_package" "$output")
    update_data_package=$(killer_attr_time "update_data_package" "$output")
    create_unlink_package=$(killer_attr_time "create_unlink_package" "$output")
    create_attr_package=$(killer_attr_time "create_attr_package" "$output")
    
    echo $((create_inode_package+create_data_package+update_data_package+create_unlink_package+create_attr_package))
}

function extract_killer_update_bm_time_from_output() {
    local output="$1"
    set_bm=$(killer_attr_time "imm_set_bitmap" "$output")
    clear_bm=$(killer_attr_time "imm_clear_bitmap" "$output")
    echo $((set_bm+clear_bm))
}