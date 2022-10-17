fio -filename=/mnt/test -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs=4K -size=10M -name=write -fsync=1

fio -directory=/mnt/ -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs=4K -size=16G -name=write -fsync=1 -numjobs=4