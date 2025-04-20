#!/usr/bash
set -x
loop=1
if [ "$1" ]; then
    loop=$1
fi

table_name="performance-comparison-table"

sed 's/0m//g' -i "$table_name"
sed 's/s//g' -i "$table_name"
sed 's/file_ytem/file_system/g' -i "$table_name"
sed 's/file_ize/file_size/g' -i "$table_name"
sed 's/fileerver/fileserver/g' -i "$table_name"
# convert minutes to seconds
perl -pe 's/(\d+)m(\d+(?:\.\d+)?)/sprintf("%.3f", $1 * 60 + $2)/ge' -i "$table_name"

python3 ../aggregate.py "$table_name" "$loop"
mv "$table_name" "$table_name"-orig
mv "$table_name"_agg "$table_name"
