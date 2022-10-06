#!/usr/bin/bash

fss=( "NOVA" "PMFS" "SIMFS")
folders=( "../../nova" "../../pmfs" "../../simfs" )
cur_path=$(pwd)

STEP=0
for fs in "${fss[@]}"; do
    echo "Trace $fs meta"
    folder=${folders[$STEP]}
    bash trace.sh "$cur_path/$folder" "trace"
    cd "$cur_path" || exit
    STEP=$((STEP + 1))
done