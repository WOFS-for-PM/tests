#!/usr/bin/env python3

# read trace.txt, and calculate the contignous length of each line

import sys

len_dict = {}
with open("trace.txt", 'r') as f:
    lines = f.readlines()
    last_blk = -1
    cur_len = 1
    
    blks = []
    for line in lines:
        blk = int(line.split()[0])
        blks.append(blk)
    blks.sort()
    
    print("sort done")
    for blk in blks:
        if cur_len > 512:
            if cur_len in len_dict:
                len_dict[cur_len] += 1
            else:
                len_dict[cur_len] = 1
            cur_len = 1
        else:
            if blk == last_blk + 1:
                cur_len += 1
            else:
                if cur_len in len_dict:
                    len_dict[cur_len] += 1
                else:
                    len_dict[cur_len] = 1
                cur_len = 1
        last_blk = blk

print(len_dict)