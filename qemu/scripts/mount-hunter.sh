cd /
mkdir -p mnt
mount -t HUNTER -o init,meta_async,meta_local /dev/pmem0 /mnt
# SLEEP FOR WHILE