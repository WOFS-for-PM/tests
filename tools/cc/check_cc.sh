#!/usr/bin/env sh
# First allow pmem1 to complete recovery

set -x

ABS_PATH=$(cd "$( dirname "$0" )" && pwd)
TOOLS_PATH="$ABS_PATH"/..

# Compare the contents of /dev/pmem0 and /dev/pmem1
diff -qr /dev/pmem0 /dev/pmem1
error=$?

if [ $error -eq 0 ]; then
    echo "Consistency check passed"
    exit 0
else
    echo "Check with a live mount"
    # Continue with the rest of the script
    # ...
fi

# mount killer
# NOTE: currently, we do not support mounting killer with two instances
#       so we copy the directory from pmem0 to pmem1
"$TOOLS_PATH"/mount.sh "KILLER-TRACE" "killer-trace" 0 "/dev/pmem0" "/mnt/pmem0"
cp /mnt/pmem0/* -r /mnt/pmem1/

# We mount a crash snapshot of /dev/pmem1 to /mnt/pmem0
sleep 1

"$TOOLS_PATH"/mount.sh "KILLER-TRACE" "killer-trace" 0 "/dev/pmem1" "/mnt/pmem0"

#echo "Unmount pmem1"
#umount /mnt/pmem1

diff -qr /mnt/pmem0 /mnt/pmem1 
error=$?

if [ $error -eq 0 ]; then
	echo "Consistency check passed"
elif [ $error -eq 1 ]; then
   	echo "Files in the devices differ"
else
   	echo "There was something wrong with the diff command"
fi

echo "Unmount devices"
umount /mnt/pmem0
