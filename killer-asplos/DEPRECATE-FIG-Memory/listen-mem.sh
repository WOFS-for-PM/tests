#!/usr/bin/env bash

table_name="$1"
# mem_start=$(cat /proc/meminfo | grep MemFree | awk '{print $2}')   

while true
do
    mem=$(cat /proc/meminfo | grep MemFree | awk '{print $2}')    
    echo "$mem ">> "$table_name"
    sleep 0.01
done