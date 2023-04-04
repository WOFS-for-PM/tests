# mount async with meta local
cd /
mkdir -p mnt
mount -t HUNTER -o init,meta_async=5,meta_local /dev/pmem0 /mnt

# mount async with meta lfs
cd /
mkdir -p mnt
mount -t HUNTER -o init,meta_async=5,meta_lfs /dev/pmem0 /mnt

# mount sync with meta pack
cd /
mkdir -p mnt
mount -t HUNTER -o init,meta_pack /dev/pmem0 /mnt
# SLEEP FOR WHILE