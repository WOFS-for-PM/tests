cd /
mkdir -p mnt
mount -t pmfs -o init /dev/pmem0 /mnt
# SLEEP FOR WHILE