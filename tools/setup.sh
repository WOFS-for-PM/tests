#!/usr/bin/bash

function where_is_script() {
    local script=$1
    cd "$( dirname "$script" )" && pwd
}

ABS_PATH=$(where_is_script "$0")

NOVA_PATH="$ABS_PATH"/../../nova
PMFS_PATH="$ABS_PATH"/../../pmfs
HUNTER_PATH="$ABS_PATH"/../../hunter-kernel
CONFIGS_PATH="$ABS_PATH"/configs


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

# free memory at first
echo "Drop caches..."
sync; echo 1 | sudo tee /proc/sys/vm/drop_caches
sync; echo 1 | sudo tee /proc/sys/vm/drop_caches
sync; echo 1 | sudo tee /proc/sys/vm/drop_caches 

# setup
case "${fs}" in
    "NOVA-RELAX")
        cd "$NOVA_PATH" || exit
        git checkout "$branch"
        if (( measure_timing == 1 )); then
            bash setup.sh "$CONFIGS_PATH"/nova/config.mt.relax.json
        else
            bash setup.sh "$CONFIGS_PATH"/nova/config.relax.json
        fi
    ;;
    "NOVA")
        cd "$NOVA_PATH" || exit
        git checkout "$branch"
        if (( measure_timing == 1 )); then
            bash setup.sh "$CONFIGS_PATH"/nova/config.mt.json 
        else
            bash setup.sh
        fi
    ;;
    "PMFS")
        cd "$PMFS_PATH" || exit
        git checkout "$branch"
        bash setup.sh /dev/pmem0 /mnt/pmem0 -j32 "$measure_timing" 
    ;;
    "HUNTER-SYNC")
        cd "$HUNTER_PATH" || exit
        git checkout "$branch"
        if (( measure_timing == 1 )); then
            bash setup.sh "$CONFIGS_PATH"/hunter/config.sync.mt.nowprotect.json
        else
            bash setup.sh "$CONFIGS_PATH"/hunter/config.sync.nowprotect.json
        fi
    ;;
    "HUNTER-NOHISTORY")
        cd "$HUNTER_PATH" || exit
        git checkout "$branch"
        if (( measure_timing == 1 )); then
            bash setup.sh "$CONFIGS_PATH"/hunter/config.mt.nohistory.nowprotect.json
        else
            bash setup.sh "$CONFIGS_PATH"/hunter/config.nohistory.nowprotect.json
        fi
    ;;
    "HUNTER")
        cd "$HUNTER_PATH" || exit
        git checkout "$branch"
        if (( measure_timing == 1 )); then
            bash setup.sh "$CONFIGS_PATH"/hunter/config.mt.nowprotect.json
        else
            bash setup.sh "$CONFIGS_PATH"/hunter/config.nowprotect.json
        fi
    ;;
    *)
        echo "Unknown file system: $fs"
        exit 1
esac
