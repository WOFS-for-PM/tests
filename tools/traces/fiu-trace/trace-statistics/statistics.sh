#!/usr/bin/env bash
TRACE_DIR="/usr/local/trace"
TRACES_NAME=( "facebook" "gsf-filesrv" "moodle" "twitter" "ug-filesrv" "usr1" "usr2" )
echo "trace size(GiB) nfiles" > "IO-statistics-table"

for trace_name in "${TRACES_NAME[@]}"; do
    echo "Processing $trace_name"
    OUTPUT=$(python3 ../populate_files.py "$TRACE_DIR"/"$trace_name"/trace.syscalltrace /mnt/pmem0/ 0)
    tot_size=$(echo "$OUTPUT" | grep "Total Size (GIB):" | awk '{print $4}') 
    tot_files=$(echo "$OUTPUT" | grep "Files Created" | awk '{print $1}')
    echo "$trace_name $tot_size $tot_files" >> "IO-statistics-table"
done