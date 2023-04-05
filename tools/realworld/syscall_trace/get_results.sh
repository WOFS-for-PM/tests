TABLE_NAME="./metadata-trace-fio-results"
echo "file_system workload time(ms)" > $TABLE_NAME
for workload in ./output/*; do
  for fs in "$workload"/*; do
    time=$(grep -oP '\d+(?= ms)' "$fs")
    echo "$(basename "$fs") $(basename "$workload") $time" >> $TABLE_NAME
  done
done