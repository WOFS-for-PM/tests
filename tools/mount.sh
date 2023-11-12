#!/usr/bin/bash

function where_is_script() {
    local script=$1
    cd "$( dirname "$script" )" && pwd
}


ABS_PATH=$(where_is_script "$0")

NOVA_PATH="$ABS_PATH"/../../nova
PMFS_PATH="$ABS_PATH"/../../pmfs
HUNTER_PATH="$ABS_PATH"/../../hunter-kernel
SPLITFS_PATH="$ABS_PATH"/../../splitfs/splitfs
EXT4RELINK_PATH="$ABS_PATH"/../../ext4relink
CONFIGS_PATH="$ABS_PATH"/configs

function compile_splitfs () {
    make clean
    make -e -j"$(nproc)"

    sudo umount /mnt/pmem0
    sudo rmmod ext4relink

    cd "$EXT4RELINK_PATH" || exit
    make -j32
    sudo insmod ext4relink.ko
    cd - || exit

    sudo mkfs.ext4 -F -b 4096 /dev/pmem0
    sudo mount -t ext4relink -o dax /dev/pmem0 /mnt/pmem0
}

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


# setup
case "${fs}" in
    "NOVA")
        cd "$NOVA_PATH" || exit
        git checkout "$branch"
        if (( measure_timing == 1 )); then
            bash setup.sh "$CONFIGS_PATH"/nova/config.mt.noinit.json 
        else
            bash setup.sh "$CONFIGS_PATH"/nova/config.noinit.json
        fi
    ;;
    "HUNTER-J")
        cd "$HUNTER_PATH" || exit
        git checkout "$branch"
        if (( measure_timing == 1 )); then
            bash setup.sh "$CONFIGS_PATH"/hunter-j/config.mt.noinit.json
        else
            bash setup.sh "$CONFIGS_PATH"/hunter-j/config.noinit.json
        fi
    ;;
    "KILLER")
        cd "$HUNTER_PATH" || exit
        git checkout "$branch"
        if (( measure_timing == 1 )); then
            bash setup.sh "$CONFIGS_PATH"/killer/config.mt.noinit.json
        else
            bash setup.sh "$CONFIGS_PATH"/killer/config.noinit.json
        fi
    ;;
    *)
        echo "Unknown file system: $fs"
        exit 1
esac
