#!/usr/bin/bash
source "../../common.sh"
ABS_PATH=$(where_is_script "$0")
tools_path=$ABS_PATH/../../../tools
output="$ABS_PATH/output"
boost_dir=$ABS_PATH/../../../../splitfs/splitfs
workload_path=/usr/local/trace

workload_name=$1
if [ ! "${workload_name}" ]; then
    echo "Usage: $0 <workload_name> (e.g. facebook / ug-filesrv)"
    exit 1
fi

if [ ! -e "$workload_path/$workload_name" ]; then
    echo "$workload_path/$workload_name not found"
    exit 1
fi

if [ ! -e "$workload_path/$workload_name/trace.syscalltrace" ]; then
    bash $tools_path/traces/fiu-trace/aggregate_traces.sh $workload_path/$workload_name
fi

if [ "${workload_name}" ]; then
    rm -rf $output/$workload_name
fi

mkdir -p $output/$workload_name

FILE_SYSTEMS=("SplitFS")

for file_system in "${FILE_SYSTEMS[@]}"; do
    if [[ "${file_system}" == "SplitFS" ]]; then
        sudo bash "$tools_path"/setup.sh "$file_system" "null" "0"
        export LD_LIBRARY_PATH="$boost_dir"/
        export NVP_TREE_FILE="$boost_dir"/bin/nvp_nvp.tree
        sudo python3 $tools_path/traces/fiu-trace/populate_files.py \
        $workload_path/$workload_name/trace.syscalltrace /mnt/pmem0 1 \

        sudo LD_PRELOAD=$boost_dir/libnvp.so $tools_path/traces/fiu-trace/replay -f \
        /usr/local/trace/facebook/trace.syscalltrace -o syscall -m fiu-no-content -d \
        /mnt/pmem0/ | tee $output/$workload_name/$file_system
    else
        sudo bash "$tools_path"/setup.sh "$file_system" "main" "0"

        sudo python3 $tools_path/traces/fiu-trace/populate_files.py \
        $workload_path/$workload_name/trace.syscalltrace /mnt/pmem0 1 \

        sudo $tools_path/traces/fiu-trace/replay -f $workload_path/$workload_name/trace.syscalltrace \
        -o syscall -m fiu-no-content -d /mnt/pmem0/ | tee $output/$workload_name/$file_system
    fi

    echo Sleeping for 2 seconds . .
    sleep 2
done