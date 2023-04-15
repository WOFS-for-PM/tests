#!/usr/bin/env python3
import math
import sys

#python3 populate_files.py /usr/local/trace/moodle/trace.syscalltrace /mnt/pmem0 1
syscall_trace = sys.argv[1]     # /usr/local/trace/facebook/trace.syscalltrace
dst_dir = sys.argv[2]           # /mnt/pmem0
do_create = sys.argv[3]         # 1
files_size = {}
write_size = 0
write_times = 0
read_size = 0
read_times = 0
invalid = 0

with open(syscall_trace, 'r') as trace_file:
    for syscall in trace_file.readlines():
        try:
            [seq, ts, op, inode, fsize, offset, size, hit] = ' '.join(syscall.split()).split()

            if size == '18446744073709551615':
                invalid += 1
                continue 
            if size == 'vff':
                continue
            
            if op == "WRITE":
                write_times += 1
                write_size += int(size)

            if op == "READ":
                read_times += 1
                read_size += int(size)

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
writen = 0
Gbytes = 1024 * 1024 * 1024
next_output = 1 * Gbytes

for inode in files_size:
    files_size[inode] = math.ceil(files_size[inode] / 4096) * 4096
    tot_size += files_size[inode]
    if do_create == "1":
        assert(files_size[inode] % 4096 == 0)
        with open(dst_dir + "/" + inode, 'wb') as f:
            # populate file with zeros
            f.write(b'\0' * files_size[inode])
            writen += files_size[inode]
            if writen > next_output:
                print("already write: " + "%.2fGB" % (writen / Gbytes))
                next_output = math.ceil(writen / Gbytes) * Gbytes

print("Total Size (GIB): " + str(tot_size / 1024 / 1024 / 1024))
print("%d Files Created" % len(files_size))
print("WRITE: times: " + str(write_times) + "  sizes: " + str(write_size) + "  avg: " + str(write_size / write_times))
print("READ: times: " + str(read_times) + "  sizes: " + str(read_size) + "  avg: " + str(read_size / read_times))