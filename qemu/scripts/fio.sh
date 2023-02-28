fio -filename=/mnt/test -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs=4K -size=10M -name=write -fsync=1

fio -filename=/mnt/test -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs=4K -size=128k -name=write

fio -filename=/mnt/test -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs=4K -size=128M -name=write

fio -filename=/mnt/test -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs=4K -size=1G -name=write

fio -directory=/mnt/ -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs=4K -size=16G -name=write -numjobs=4

fio -directory=/mnt/ -fallocate=none -direct=0 -iodepth 1 -rw=write -ioengine=sync -bs=4K -size=1G -name=write -numjobs=4