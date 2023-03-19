#!/usr/bin/env bash

ABS_PATH=$(cd "$( dirname "$0" )" && pwd)
pmem="pmem0"
args=( "$@" )

cmds=( "${args[*]:1}" )

echo Perfing: "${cmds[@]}"

tmp_file=$(mktemp tmp_cmd.XXXXXXXXXX)
echo "${cmds[@]}" > "$tmp_file"

mkdir -p perfs
sudo perf mem record -o perfs/perf.data bash "$tmp_file"
# perf mem report -F symbol_daddr -i perfs/perf.data > perfs/perf_report
perf script -i perfs/perf.data > perfs/perf_report 

pmem_virt_start=$(bash "$ABS_PATH"/detect_range.sh "$pmem" | grep "Virtual Memory Start" | awk '{print $4}')
pmem_virt_end=$(bash "$ABS_PATH"/detect_range.sh "$pmem" | grep "Virtual Memory End" | awk '{print $4}')

# filter out the lines that are in the pmem range

awk -v start="$pmem_virt_start" -v end="$pmem_virt_end" -f "$ABS_PATH"/filter_range.awk perfs/perf_report > perf_report_filtered
echo "Perf directoy generated @ $(realpath perfs)"
rm "$tmp_file"