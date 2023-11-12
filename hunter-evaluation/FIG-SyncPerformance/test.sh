#!/usr/bin/env bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

TRACE_DIR="/usr/local/FIU-trace"
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts
FILE_SYSTEMS=( "HUNTER-orig" "HUNTER-vheader" )
BRANCHES=( "hunter-J-orig" "hunter-J-vheader" )
FIO_FSIZES=( $((1 * 1024)) $((2 * 1024)) $((4 * 1024)) $((8 * 1024)) $((16 * 1024)) $((32 * 1024)) $((64 * 1024)) )
FILE_BENCHES=( "fileserver.f" "varmail.f" "webserver.f" "webproxy.f" )
TRACES_NAME=( "twitter" "facebook" "usr1" "usr2" "moodle" "gsf-filesrv" )
TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system workloads perf(MiBPS/OPS)"
MODES=( "strict" )

mkdir -p "$ABS_PATH"/DATA

loop=1
if [ "$1" ]; then
    loop=$1
fi

for ((i=1; i <= loop; i++))
do
    IDX=0
    for file_system in "${FILE_SYSTEMS[@]}"; do
        branch=${BRANCHES[$IDX]}
        for mode in "${MODES[@]}"; do
            # ANCHOR - FIO
            for fsize in "${FIO_FSIZES[@]}"; do
                bash "$TOOLS_PATH"/setup.sh "HUNTER-J" "$branch" "0"
                
                BW=$(bash "$TOOLS_PATH"/fio-fsync.sh /mnt/pmem0/test 4K "$fsize" 1 | grep WRITE: | awk '{print $2}' | sed 's/bw=//g' | "$TOOLS_PATH"/converter/to_MiB_s)
            
                table_add_row "$TABLE_NAME" "$file_system fio-$fsize $BW"
            done

            # ANCHOR - Filebench
            for fbench in "${FILE_BENCHES[@]}"; do
                bash "$TOOLS_PATH"/setup.sh "HUNTER-J" "$branch" "0"
                thread=1
                
                mkdir -p "$ABS_PATH"/DATA/"$fbench"
                cp -f "$FSCRIPT_PRE_FIX"/"$fbench" "$ABS_PATH"/DATA/"$fbench"/"$thread" 
                sed_cmd='s/set $nthreads=.*$/set $nthreads='$thread'/g' 
                sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$fbench"/"$thread"

                sudo /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread" | tee "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread"
                iops=$(filebench_attr_iops "$ABS_PATH"/DATA/"$fbench"/"$file_system"-"$thread")
                table_add_row "$TABLE_NAME" "$file_system $fbench $iops"
            done
            
            # ANCHOR - Trace
            for trace_name in "${TRACES_NAME[@]}"; do
                bash "$TOOLS_PATH"/setup.sh "HUNTER-J" "$branch" "0"

                echo "Tailoring $trace_name for replaying"
                python3 "$TOOLS_PATH"/traces/fiu-trace/trace_tailor.py "$TRACE_DIR"/"$trace_name"/trace.syscall "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored
                
                echo "Replaying $trace_name on $file_system"
                OPS=$(sudo python3 "$TOOLS_PATH"/traces/fiu-trace/replay.py "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored /mnt/pmem0 1 | grep "OPS: " | awk '{print $2}')
            
                table_add_row "$TABLE_NAME" "$file_system $trace_name-$mode $OPS"
            done
        done
        IDX=$((IDX+1))
    done
done
