cd /
mkdir -p mnt
mount -t NOVA -o init,data_cow /dev/pmem0 /mnt
# SLEEP FOR WHILE