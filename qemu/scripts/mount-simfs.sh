cd /
mkdir -p mnt
mount -t OpenSIMFS -o init /dev/pmem0 /mnt
# SLEEP FOR WHILE