#!/usr/bin/env sh
# First allow pmem1 to complete recovery

ABS_PATH=$(cd "$( dirname "$0" )" && pwd)
TOOLS_PATH="$ABS_PATH"/..

if ! cmp /dev/pmem0 /dev/pmem1; then
    echo "Consistency check passed."
    exit 0
else
    echo "Test with a live mount"
fi

# mount killer
"$TOOLS_PATH"/mount.sh "KILLER-TRACE" "killer-trace" "/dev/pmem0"
"$TOOLS_PATH"/mount.sh "KILLER-TRACE" "killer-trace" "/dev/pmem1"

#echo "Unmount pmem1"
#umount /mnt/pmem1

diff -qr /mnt/pmem0 /mnt/pmem1 
error=$?

if [ $error -eq 0 ]; then
	echo "The files in two devices match"
elif [ $error -eq 1 ]; then
   	echo "Files in the devices differ"
else
   	echo "There was something wrong with the diff command"
fi

echo "Unmount devices"
umount /mnt/pmem0
umount /mnt/pmem1
