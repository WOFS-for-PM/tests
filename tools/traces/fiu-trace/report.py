#!/usr/bin/env python3
import math
import os
import sys

#python3 populate_files.py /usr/local/trace/moodle/trace.syscalltrace /mnt/pmem0 1
syscall_trace = sys.argv[1]     # /usr/local/trace/facebook/trace.syscalltrace

files = {
    # [min_offset, max_size]
}

write_size = 0
write_times = 0
read_size = 0
read_times = 0
fsync_times = 0
op_times = 0

OVERFLOW = "18446744073709551615"
tailored_content = []

def update_inode(inode: int, offset, size):
    global files
    if inode not in files:
        files[inode] = [int(offset), int(size)]
    files[inode] = [
        int(offset) if int(offset) < files[inode][0] else files[inode][0],
        int(offset) + int(size) if int(offset) + int(size) > files[inode][1] else files[inode][1]
    ]

def tailor_inode(inode: int, offset, fsize):
    tailored_offset = int(offset) - files[inode][0]
    tailored_fsize = files[inode][1]
    return [tailored_offset, tailored_fsize]

with open(syscall_trace, 'r') as trace_file:
    for syscall in trace_file.readlines():
        op_times += 1
        try:
            [seq, ts, op, inode, fsize, offset, size, hit] = ' '.join(syscall.split()).split()

            if size == OVERFLOW:
                continue 
            if size == 'vff':
                continue
            
            if op == "WRITE":
                write_times += 1
                write_size += int(size)

            if op == "READ":
                read_times += 1
                read_size += int(size)

            update_inode(inode, offset, size)
            tailored_content.append(syscall)
        except:
            try:
                [seq, ts, op, inode, fsize, offset, size] = ' '.join(syscall.split()).split()

                if size == OVERFLOW:
                    continue 
                
                if op == "WRITE":
                    write_times += 1
                    write_size += int(size)

                if op == "READ":
                    read_times += 1
                    read_size += int(size)
                
                update_inode(inode, offset, size)
                tailored_content.append(syscall)
            except:
                try:
                    [seq, ts, op, inode, fsize] = ' '.join(syscall.split()).split()
                    if inode not in files:
                        files[inode] = [0, 0]
                    if op == "FSYNC" or op == "FDATASYNC":
                        fsync_times += 1
                    tailored_content.append(syscall)
                except:
                    print("Error: " )
                    raise

for syscall in tailored_content:
    try:
        [seq, ts, op, inode, fsize, offset, size, hit] = ' '.join(syscall.split()).split()
        tailored_offset, tailored_fsize = tailor_inode(inode, offset, fsize)
    except:
        try:
            [seq, ts, op, inode, fsize, offset, size] = ' '.join(syscall.split()).split()
            tailored_offset, tailored_fsize = tailor_inode(inode, offset, fsize)
        except:
            try: 
                [seq, ts, op, inode, fsize] = ' '.join(syscall.split()).split()
                tailored_offset, tailored_fsize = tailor_inode(inode, offset, fsize)
            except:
                raise

tot_size = 0
writen = 0
max_size_file = [
    0, # size
    0  # inode
]

for inode in files:
    tot_size += files[inode][1]
    if files[inode][1] > max_size_file[0]:
        max_size_file = [
            files[inode][1],
            inode
        ]
    
print("Total Size (GIB): " + str(tot_size / 1024 / 1024 / 1024))
print("%d Files Created" % len(files))
print("Max File (" + str(max_size_file[1]) + ") Size (GIB): " + str(max_size_file[0] / 1024 / 1024 / 1024))
print("WRITE: times: " + str(write_times) + "  sizes: " + str(write_size) + "  avg: " + str(write_size / write_times))
print("READ: times: " + str(read_times) + "  sizes: " + str(read_size) + "  avg: " + str(read_size / read_times))
print("FSYNC: times: " + str(fsync_times))
print("OP: times: " + str(op_times))
