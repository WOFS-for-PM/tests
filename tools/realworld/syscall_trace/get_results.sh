TABLE_NAME="./syscall-trace-results"
echo "file_system workload time(ms)" > $TABLE_NAME
for workload in ./output/*; do
  for fs in "$workload"/*; do
    time=$(grep -E 'real[[:space:]]+' $fs | sed 's/^[[:space:]]*real[[:space:]]*//')
    echo "$(basename "$fs") $(basename "$workload") $time" >> $TABLE_NAME
  done
done