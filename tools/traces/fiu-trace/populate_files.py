#!/usr/bin/env python3
import math
import sys

syscall_trace = sys.argv[1]     # /usr/local/trace/facebook/trace.syscalltrace
dst_dir = sys.argv[2]           # /mnt/pmem0
do_create = sys.argv[3]         # 1
files_size = {}

with open(syscall_trace, 'r') as trace_file:
    for syscall in trace_file.readlines():
        try:
            [seq, ts, op, inode, fsize, offset, size, hit] = ' '.join(syscall.split()).split()

            if size == '18446744073709551615':
                continue 
            if size == 'vff':
                continue
            
            if inode not in files_size:
                files_size[inode] = int(fsize)
            files_size[inode] = int(offset) + int(size) if int(offset) + int(size) > files_size[inode] else files_size[inode]
        except:
            try:
                [seq, ts, op, inode, fsize, offset, size] = ' '.join(syscall.split()).split()

                if size == '18446744073709551615':
                    continue 
                
                if inode not in files_size:
                    files_size[inode] = int(fsize)
                files_size[inode] = int(offset) + int(size) if int(offset) + int(size) > files_size[inode] else files_size[inode]
            except:
                try:
                    [seq, ts, op, inode, fsize] = ' '.join(syscall.split()).split()
                    if inode not in files_size:
                        files_size[inode] = int(fsize)
                except:
                    print("Error: " + syscall)
                    raise


tot_size = 0
for inode in files_size:
    files_size[inode] = math.ceil(files_size[inode] / 4096) * 4096
    tot_size += files_size[inode]
    if do_create == "1":
        assert(files_size[inode] % 4096 == 0)
        with open(dst_dir + "/" + inode, 'wb') as f:
            # populate file with zeros
            f.write(b'\0' * files_size[inode])

print("Total Size (GIB): " + str(tot_size / 1024 / 1024 / 1024))
print("%d Files Created" % len(files_size))