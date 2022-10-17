#!/usr/bin/bash

function where_is_script() {
    local script=$1
    cd "$( dirname "$script" )" && pwd
}

ABS_PATH=$(where_is_script "$0")

NOVA_PATH="$ABS_PATH"/../../nova
PMFS_PATH="$ABS_PATH"/../../pmfs
HUNTER_PATH="$ABS_PATH"/../../hunter-kernel


if [ ! $1 ] || [ ! $2 ]; then
    echo "Usage: $0 <fs> <branch>"
    exit 1
fi

fs=$1
branch=$2

if [ ! "$3" ]; then
    measure_timing=0
else
    measure_timing=$3
fi

case "${fs}" in
    "NOVA")
        cd "$NOVA_PATH" || exit
        git checkout "$branch"
        
        if (( measure_timing == 1 )); then
            bash setup.sh config.mt.json 
        else
            bash setup.sh
        fi
    ;;
    "PMFS")
        cd "$PMFS_PATH" || exit
        git checkout "$branch"
        bash setup.sh /dev/pmem0 /mnt/pmem0 -j32 "$measure_timing" 
    ;;
    "HUNTER")
        cd "$HUNTER_PATH" || exit
        git checkout "$branch"
        bash setup.sh "$measure_timing"
    ;;
    *)
        echo "Unknown file system: $fs"
        exit 1
esac
