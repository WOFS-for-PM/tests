# FIO-write
# FIO-write-sync

# Fileserver
# Varmail (sync)

# Trace
# Trace-sync

#!/usr/bin/env bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

TRACE_DIR="/usr/local/FIU-trace"
FSCRIPT_PRE_FIX=$ABS_PATH/../../tools/fbscripts
FILE_SYSTEMS=( "HUNTER-J" )
FIO_FSIZES=( $(( 1 * 1024 )) $(( 2 * 1024 )) $(( 4 * 1024 )) $(( 8 * 1024 )) $(( 16 * 1024 )) $(( 32 * 1024 )) $(( 64 * 1024 )) )
TRACES_NAME=( "twitter" "facebook" "usr1" "usr2" "moodle" "gsf-filesrv" )
TABLE_NAME="$ABS_PATH/performance-comparison-table"
table_create "$TABLE_NAME" "file_system workloads real(s) user(s) sys(s)"
MODES=( "non-strict" "strict")

mkdir -p "$ABS_PATH"/DATA

get_time_in_seconds() {
    local time_file=$1
    local time_type=$2
    local _time="0m0.000s"

    if [[ "${time_type}" == "real" ]]; then
        _time=$(cat $time_file | awk '/^real/ {print $2}')
    elif [[ "${time_type}" == "user" ]]; then
        _time=$(cat $time_file | awk '/^user/ {print $2}')
    elif [[ "${time_type}" == "sys" ]]; then
        _time=$(cat $time_file | awk '/^sys/ {print $2}')
    fi
    
    # input str like: 0m0.000s
    _MINUTES=$(echo "$_time" | awk -F 'm' '{print $1}' | sed 's/ //g')
    _SECONDS=$(echo "$_time" | awk -F 'm' '{print $2}' | awk -F 's' '{print $1}' | sed 's/ //g')
    TOTAL_SECONDS=$(echo "$_MINUTES * 60 + $_SECONDS" | bc -l)
    echo "$TOTAL_SECONDS"    
}

loop=1
if [ "$1" ]; then
    loop=$1
fi


for ((i=1; i <= loop; i++))
do
    for file_system in "${FILE_SYSTEMS[@]}"; do
        for mode in "${MODES[@]}"; do
            # ANCHOR - FIO
            for fsize in "${FIO_FSIZES[@]}"; do
                if [[ "${file_system}" == "HUNTER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dac" "0"
                elif [[ "${file_system}" == "HUNTER-J" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "hunter-async" "0"
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                fi

                if [[ "${mode}" == "non-strict" ]]; then
                    BW=$(bash "$TOOLS_PATH"/fio.sh /mnt/pmem0/test 4K "$fsize" 1)
                else
                    BW=$(bash "$TOOLS_PATH"/fio-fsync.sh /mnt/pmem0/test 4K "$fsize" 1)
                fi

                { time umount /mnt/pmem0 ; } 2> "$ABS_PATH"/DATA/fio-"$fsize"-"$mode"-time
                sys=$(get_time_in_seconds "$ABS_PATH"/DATA/fio-"$fsize"-$"$mode"-time "sys")
                user=$(get_time_in_seconds "$ABS_PATH"/DATA/fio-"$fsize"-"$mode"-time "user")
                real=$(get_time_in_seconds "$ABS_PATH"/DATA/fio-"$fsize"-"$mode"-time "real")
                table_add_row "$TABLE_NAME" "$file_system fio-$fsize-$mode $real $user $sys"
            done

            # ANCHOR - Filebench
            if [[ "${file_system}" == "HUNTER" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "dac" "0"
            elif [[ "${file_system}" == "HUNTER-J" ]]; then
                bash "$TOOLS_PATH"/setup.sh "$file_system" "hunter-async" "0"
            else
                bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
            fi
            
            thread=1
            if [[ "${mode}" == "non-strict" ]]; then
                fbench="fileserver.f"
            else
                fbench="varmail.f"
            fi
            
            mkdir -p "$ABS_PATH"/DATA/"$fbench"
            cp -f "$FSCRIPT_PRE_FIX"/"$fbench" "$ABS_PATH"/DATA/"$fbench"/"$thread" 
            sed_cmd='s/set $nthreads=.*$/set $nthreads='$thread'/g' 
            sed -i "$sed_cmd" "$ABS_PATH"/DATA/"$fbench"/"$thread"

            sudo /usr/local/filebench/filebench -f "$ABS_PATH"/DATA/"$fbench"/"$thread"

            { time umount /mnt/pmem0 ; } 2> "$ABS_PATH"/DATA/filebench-"$mode"-time
            sys=$(get_time_in_seconds "$ABS_PATH"/DATA/filebench-"$mode"-time "sys")
            user=$(get_time_in_seconds "$ABS_PATH"/DATA/filebench-"$mode"-time "user")
            real=$(get_time_in_seconds "$ABS_PATH"/DATA/filebench-"$mode"-time "real")
            table_add_row "$TABLE_NAME" "$file_system filebench-$mode $real $user $sys"
            
            # ANCHOR - Trace
            for trace_name in "${TRACES_NAME[@]}"; do
                if [[ "${file_system}" == "HUNTER" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "dac" "0"
                elif [[ "${file_system}" == "HUNTER-J" ]]; then
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "hunter-async" "0"
                else
                    bash "$TOOLS_PATH"/setup.sh "$file_system" "main" "0"
                fi

                echo "Tailoring $trace_name for replaying"
                python3 "$TOOLS_PATH"/traces/fiu-trace/trace_tailor.py "$TRACE_DIR"/"$trace_name"/trace.syscall "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored
                
                echo "Replaying $trace_name on $file_system"
                if [[ "${mode}" == "non-strict" ]]; then
                    OPS=$(sudo python3 "$TOOLS_PATH"/traces/fiu-trace/replay.py "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored /mnt/pmem0 | grep "OPS: " | awk '{print $2}')
                else
                    OPS=$(sudo python3 "$TOOLS_PATH"/traces/fiu-trace/replay.py "$TRACE_DIR"/"$trace_name"/trace.syscall.tailored /mnt/pmem0 1 | grep "OPS: " | awk '{print $2}')
                fi

                { time umount /mnt/pmem0 ; } 2> "$ABS_PATH"/DATA/"$trace_name"-"$mode"-time
                sys=$(get_time_in_seconds "$ABS_PATH"/DATA/"$trace_name"-"$mode"-time "sys")
                user=$(get_time_in_seconds "$ABS_PATH"/DATA/"$trace_name"-"$mode"-time "user")
                real=$(get_time_in_seconds "$ABS_PATH"/DATA/"$trace_name"-"$mode"-time "real")
                table_add_row "$TABLE_NAME" "$file_system $trace_name-$mode $real $user $sys"
            done
        done
    done
done
