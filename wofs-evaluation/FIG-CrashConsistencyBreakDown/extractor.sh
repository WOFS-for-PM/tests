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
    write_journal=$(nova_attr_time "write_journal" "$output")

    echo $((read_entry+write_entry+read_entry_trans_id+read_entry_type+read_entry_epoch+write_journal))
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
    update_journal_ptr=$(nova_attr_time "update_journal_ptr" "$output")
    echo $((read_pi+write_pi+write_pi_log_ptr+update_pi_tail+update_journal_ptr))
}

function extract_pmfs_IO_time_from_output() {
    local output="$1"
    read=$(pmfs_attr_time "memcpy_read" "$output")
    write=$(pmfs_attr_time "memcpy_write" "$output")
    echo $(( read + write ))
}

function extract_pmfs_update_index_time_from_output() {
    local output="$1"
    read=$(pmfs_attr_time "read_meta_block" "$output")
    write=$(pmfs_attr_time "write_meta_block" "$output")
    echo $(( read + write ))    
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

function extract_pmfs_commit_time_from_output() {
    local output="$1"
    commit_trans=$(pmfs_attr_time "commit_trans" "$output")
    echo $((commit_trans))
}

function extract_pmfs_journal_time_from_output() {
    local output="$1"
    
    new_trans_alloc_tail=$(pmfs_attr_time "new_trans_alloc_tail" "$output")
	read_trans=$(pmfs_attr_time "read_trans" "$output")
	read_trans_tail=$(pmfs_attr_time "read_trans_tail" "$output")
	read_trans_head=$(pmfs_attr_time "read_trans_head" "$output")
	read_trans_base=$(pmfs_attr_time "read_trans_base" "$output")
	read_trans_genid=$(pmfs_attr_time "read_trans_genid" "$output")
	read_trans_type=$(pmfs_attr_time "read_trans_type" "$output")
	write_trans_genid=$(pmfs_attr_time "write_trans_genid" "$output")
	write_log_entry=$(pmfs_attr_time "write_log_entry" "$output")
	read_journal_head=$(pmfs_attr_time "read_journal_head" "$output")
	write_journal_head=$(pmfs_attr_time "write_journal_head" "$output")
	read_journal_tail=$(pmfs_attr_time "read_journal_tail" "$output")
	read_genid=$(pmfs_attr_time "read_genid" "$output")
    
    echo $((new_trans_alloc_tail+read_trans+read_trans_tail+read_trans_head+read_trans_base+read_trans_genid+read_trans_type+write_trans_genid+write_log_entry+read_journal_head+write_journal_head+read_journal_tail+read_genid)) 
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
    create_inode_package=$(killer_attr_time "transaction_new_inode" "$output")
    create_data_package=$(killer_attr_time "transaction_new_data" "$output")
    update_data_package=$(killer_attr_time "update_data_package" "$output")
    create_unlink_package=$(killer_attr_time "transaction_new_unlink" "$output")
    create_attr_package=$(killer_attr_time "transaction_new_attr" "$output")
    
    echo $((create_inode_package+create_data_package+update_data_package+create_unlink_package+create_attr_package))
}

function extract_killer_update_bm_time_from_output() {
    local output="$1"
    set_bm=$(killer_attr_time "imm_set_bitmap" "$output")
    clear_bm=$(killer_attr_time "imm_clear_bitmap" "$output")
    echo $((set_bm+clear_bm))
}

function extract_splitfs_IO_time_from_output() {
    local output="$1"
    local wl="$2"
    
    overread=$(splitfs_attr_time "copy_overread" "$output" "$wl")
    overwrite=$(splitfs_attr_time "copy_overwrite" "$output" "$wl")
    appendread=$(splitfs_attr_time "copy_appendread" "$output" "$wl")
    appendwrite=$(splitfs_attr_time "copy_appendwrite" "$output" "$wl")
    echo $(( (overread + overwrite + appendread + appendwrite) * 1000 )) # ns
}

function extract_splitfs_journal_time_from_output() {
    local output="$1"
    local wl="$2"

    append_entry=$(splitfs_attr_time "append_log_entry" "$output" "$wl")
    op_entry=$(splitfs_attr_time "op_log_entry" "$output" "$wl")
    echo $(( (append_entry + op_entry) * 1000)) # ns
}

function extract_splitfs_total_op_time_from_output() {
    local output="$1"
    local wl="$2"

    open=$(splitfs_attr_time "open" "$output" "$wl")
    read=$(splitfs_attr_time "read" "$output" "$wl")
    write=$(splitfs_attr_time "write" "$output" "$wl")
    close=$(splitfs_attr_time "close" "$output" "$wl")
    unlink=$(splitfs_attr_time "unlink" "$output" "$wl")
    seek=$(splitfs_attr_time "seek" "$output" "$wl")

    echo $(( (open+read+write+close+unlink+seek) * 1000 )) # ns
}
