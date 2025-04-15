#!/usr/bin/bash
# shellcheck source=/dev/null
source "../common.sh"
ABS_PATH=$(where_is_script "$0")
TOOLS_PATH=$ABS_PATH/../../tools

modprobe libcrc32c

dd if=./crash_image of=/dev/pmem0 bs=1M count=256

"$TOOLS_PATH"/mount.sh "KILLER-TRACE" "killer-trace" 0 "/dev/pmem0" "/mnt/pmem0"
