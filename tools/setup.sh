#!/usr/bin/bash

function where_is_script() {
    local script=$1
    cd "$(dirname "$script")" && pwd
}

ABS_PATH=$(where_is_script "$0")

NOVA_PATH="$ABS_PATH"/../../nova
PMFS_PATH="$ABS_PATH"/../../pmfs
HUNTER_PATH="$ABS_PATH"/../../hunter-kernel
SPLITFS_PATH="$ABS_PATH"/../../splitfs/splitfs
EXT4RELINK_PATH="$ABS_PATH"/../../ext4relink
SOUPFS_PATH="$ABS_PATH"/../../eulerfs
CONFIGS_PATH="$ABS_PATH"/configs
WINEFS_PATH="$ABS_PATH"/../../winefs
MADFS_PATH="$ABS_PATH"/../../MadFS
F2FS_PATH="$ABS_PATH"/../../f2fs

function compile_splitfs() {
    local measure_timing=$1
    make clean

    if ((measure_timing == 1)); then
        export LEDGER_INSTRU=1
        # export LEDGER_DEBUG=1
        # export LIBNVP_DEBUG=1
    fi

    make -e -j"$(nproc)"

    sudo umount /mnt/pmem0
    # sudo rmmod ext4relink

    # cd "$EXT4RELINK_PATH" || exit
    # make -j32
    # sudo insmod ext4relink.ko
    # cd - || exit

    sudo mkfs.ext4 -F -b 4096 /dev/pmem0
    sudo mount -o dax /dev/pmem0 /mnt/pmem0
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

# free memory at first
echo "Drop caches..."
sync
echo 1 | sudo tee /proc/sys/vm/drop_caches
sync
echo 1 | sudo tee /proc/sys/vm/drop_caches
sync
echo 1 | sudo tee /proc/sys/vm/drop_caches

# setup
case "${fs}" in
"NOVA-RELAX")
    cd "$NOVA_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
        bash setup.sh "$CONFIGS_PATH"/nova/config.mt.relax.json
    else
        bash setup.sh "$CONFIGS_PATH"/nova/config.relax.json
    fi
    ;;
"NOVA")
    cd "$NOVA_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
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
"WINEFS")
    cd "$WINEFS_PATH" || exit
    git checkout "$branch"
    bash setup.sh /dev/pmem0 /mnt/pmem0 -j32 "$measure_timing"
    ;;
"MadFS")
    cd "$MADFS_PATH" || exit
    make BUILD_TARGETS="madfs"
    sudo umount /mnt/pmem0
    sudo mkfs.ext4 -F -b 4096 /dev/pmem0
    sudo mount -o dax /dev/pmem0 /mnt/pmem0
    ;;
# Different configurations of HUNTER.
"HUNTER-NOHISTORY")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
        bash setup.sh "$CONFIGS_PATH"/hunter/nohistory/config.mt.nowprotect.json
    else
        bash setup.sh "$CONFIGS_PATH"/hunter/nohistory/config.nowprotect.json
    fi
    ;;
"HUNTER-LOSELAYOUT")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
        bash setup.sh "$CONFIGS_PATH"/hunter/loselayout/config.mt.nowprotect.json
    else
        bash setup.sh "$CONFIGS_PATH"/hunter/loselayout/config.nowprotect.json
    fi
    ;;
"HUNTER-LOSELAYOUT-SYNC")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
        bash setup.sh "$CONFIGS_PATH"/hunter/loselayout/sync/config.mt.nowprotect.json
    else
        bash setup.sh "$CONFIGS_PATH"/hunter/loselayout/sync/config.nowprotect.json
    fi
    ;;
"HUNTER")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
        bash setup.sh "$CONFIGS_PATH"/hunter/config.mt.nowprotect.json
    else
        bash setup.sh "$CONFIGS_PATH"/hunter/config.nowprotect.json
    fi
    ;;
"HUNTER-J")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
        bash setup.sh "$CONFIGS_PATH"/hunter-j/config.mt.nowprotect.json
    else
        bash setup.sh "$CONFIGS_PATH"/hunter-j/config.nowprotect.json
    fi
    ;;
"HUNTER-SYNC")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
        bash setup.sh "$CONFIGS_PATH"/hunter/sync/config.mt.nowprotect.json
    else
        bash setup.sh "$CONFIGS_PATH"/hunter/sync/config.nowprotect.json
    fi
    ;;
"HUNTER-ASYNC-1s")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    bash setup.sh "$CONFIGS_PATH"/hunter/async/config.1s.nowprotect.json
    ;;
"HUNTER-ASYNC-2s")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    bash setup.sh "$CONFIGS_PATH"/hunter/async/config.2s.nowprotect.json
    ;;
"HUNTER-ASYNC-3s")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    bash setup.sh "$CONFIGS_PATH"/hunter/async/config.3s.nowprotect.json
    ;;
"HUNTER-ASYNC-INFTY")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    bash setup.sh "$CONFIGS_PATH"/hunter/async/config.infty.nowprotect.json
    ;;
# KILLER is a variant of HUNTER with WRITE-ONCE scheme.
"KILLER")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
        bash setup.sh "$CONFIGS_PATH"/killer/config.mt.nowprotect.json
    else
        bash setup.sh "$CONFIGS_PATH"/killer/config.nowprotect.json
    fi
    ;;
"KILLER-MEM")
    cd "$HUNTER_PATH" || exit
    if [ ! "$4" ]; then
        max_mem_obj=0
    else
        max_mem_obj=$4
    fi
    git checkout "$branch"
    if ((measure_timing == 1)); then
        bash setup.sh "$CONFIGS_PATH"/killer/config.mt.nowprotect.json "$max_mem_obj"
    else
        bash setup.sh "$CONFIGS_PATH"/killer/config.nowprotect.json "$max_mem_obj"
    fi
    ;;
"KILLER-NO-PREFETCH")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
        # 0: disable prefetching
        # 512: huge allocation block number
        bash setup.sh "$CONFIGS_PATH"/killer/config.mt.nowprotect.json 0 512
    else
        bash setup.sh "$CONFIGS_PATH"/killer/config.nowprotect.json 0 512
    fi
    ;;
"KILLER-NAIVE")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
        bash setup.sh "$CONFIGS_PATH"/killer/config.mt.nowprotect.json 0 1
    else
        bash setup.sh "$CONFIGS_PATH"/killer/config.nowprotect.json 0 1
    fi
    ;;
"KILLER-NOHISTORY")
    cd "$HUNTER_PATH" || exit
    git checkout "$branch"
    if ((measure_timing == 1)); then
        bash setup.sh "$CONFIGS_PATH"/killer/nohistory/config.mt.nowprotect.json
    else
        bash setup.sh "$CONFIGS_PATH"/killer/nohistory/config.nowprotect.json
    fi
    ;;
"EXT4-DAX")
    sudo umount /mnt/pmem0
    sudo mkfs.ext4 -F -b 4096 /dev/pmem0
    sudo mount -t ext4 -o dax /dev/pmem0 /mnt/pmem0
    ;;
"XFS-DAX")
    sudo umount /mnt/pmem0
    sudo mkfs -t xfs -m reflink=0 -f /dev/pmem0
    sudo mount -t xfs -o dax /dev/pmem0 /mnt/pmem0
    ;;
"SplitFS-FIO")
    cd "$SPLITFS_PATH" || exit
    export LEDGER_DATAJ=0
    export LEDGER_POSIX=1
    export LEDGER_FIO=1
    compile_splitfs "$measure_timing"
    ;;
"SplitFS-FIO-STRICT")
    cd "$SPLITFS_PATH" || exit
    export LEDGER_DATAJ=1
    export LEDGER_POSIX=0
    export LEDGER_FIO=1
    compile_splitfs
    ;;
"SplitFS-FILEBENCH")
    cd "$SPLITFS_PATH" || exit
    export LEDGER_DATAJ=0
    export LEDGER_POSIX=0
    export LEDGER_FILEBENCH=1
    compile_splitfs "$measure_timing"
    ;;
"SplitFS-FILEBENCH-STRICT")
    cd "$SPLITFS_PATH" || exit
    export LEDGER_DATAJ=1
    export LEDGER_POSIX=0
    export LEDGER_FILEBENCH=1
    compile_splitfs "$measure_timing"
    ;;
"SplitFS-YCSB")
    cd "$SPLITFS_PATH" || exit
    export LEDGER_DATAJ=0
    export LEDGER_POSIX=1
    export LEDGER_YCSB=1
    compile_splitfs
    ;;
"SplitFS-YCSB-STRICT")
    cd "$SPLITFS_PATH" || exit
    export LEDGER_DATAJ=1
    export LEDGER_POSIX=0
    export LEDGER_YCSB=1
    compile_splitfs
    ;;
"SplitFS-TPCC")
    cd "$SPLITFS_PATH" || exit
    export LEDGER_DATAJ=0
    export LEDGER_POSIX=1
    export LEDGER_TPCC=1
    compile_splitfs
    ;;
"SplitFS")
    cd "$SPLITFS_PATH" || exit
    export LEDGER_DATAJ=0
    export LEDGER_POSIX=1
    compile_splitfs
    ;;
"SoupFS")
    cd "$SOUPFS_PATH" || exit
    bash setup.sh
    ;;
"F2FS")
    cd "$F2FS_PATH" || exit
    git checkout "$branch"
    bash setup.sh
    ;;
"EXT4")
    sudo umount /mnt/nvme0n1p1
    sudo mkfs.ext4 -F -b 4096 /dev/nvme0n1p1
    sudo mount -t ext4 /dev/nvme0n1p1 /mnt/nvme0n1p1
    ;;
"XFS")
    sudo umount /mnt/nvme0n1p1
    sudo mkfs -t xfs -m reflink=0 -f /dev/nvme0n1p1
    sudo mount -t xfs /dev/nvme0n1p1 /mnt/nvme0n1p1
    ;;
*)
    echo "Unknown file system: $fs"
    exit 1
    ;;
esac
