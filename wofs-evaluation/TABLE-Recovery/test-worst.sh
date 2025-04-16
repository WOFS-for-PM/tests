#!/usr/bin/env bash
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
KILLER_PATH=$ABS_PATH/../../../hunter-kernel
TOOLS_PATH=$ABS_PATH/../../tools

echo "Starting cleaning device..."
bash "$TOOLS_PATH"/killer-formater/mkfs.killer.sh pmem0 1
echo "Device cleaned."

cd "$KILLER_PATH" || exit 1

git checkout osdi25-worst-recovery

make -j32

bash reboot-test.sh

umount /mnt/pmem0
rmmod hunter

cd "$ABS_PATH" || exit 1