import sys
import posix
import os
import psutil


MNT_PATH = "/mnt/pmem0/"
output = 1      #output
pid = 0

OPEN_FILE = {}
BUF = []
i = 0

#[seq num] [ts in ns] [operation] [inode num] [inode size in Bytes] [offset in Bytes] [size in Bytes] 
def replay(syscall):
    op = syscall[2]
    name = syscall[3]

    if op == "OPEN":
        try:
            fd = posix.open(MNT_PATH + name, posix.O_CREAT | posix.O_RDWR)
        except:
            print("OPEN: " + str(len(OPEN_FILE)))
            raise
        if name in OPEN_FILE:
            posix.close(OPEN_FILE[name])
        OPEN_FILE[name] = fd
        return
    
    elif op == "CLOSE":
        if name in OPEN_FILE:
            posix.close(OPEN_FILE[name])
            del OPEN_FILE[name]
        return
    
    elif op == "READ":
        if name not in OPEN_FILE:
            try:
                fd = posix.open(MNT_PATH + name, posix.O_CREAT | posix.O_RDWR)
            except:
                print("READ: " + str(len(OPEN_FILE)))
                raise
            OPEN_FILE[name] = fd
        if syscall[6] == "18446744073709551615":
            return
        try:
            offset = int(syscall[5])
            length = int(syscall[6])
        except:
            return
        
        if length == 0x10000000000000000:       #ignore
            return
        posix.pread(OPEN_FILE[name], length, offset)
    
    elif op == "WRITE":
        if name not in OPEN_FILE:
            fd = posix.open(MNT_PATH + name, posix.O_CREAT | posix.O_RDWR)
            OPEN_FILE[name] = fd
        try:
            offset = int(syscall[5])
            length = int(syscall[6])
        except:
            return

        BUF = "".zfill(length).encode("utf-8")
        ret = posix.pwrite(OPEN_FILE[name], BUF, offset)
        if ret != length:
            raise Exception("len: ", len, "ret: ", ret)

    elif op == "FDATASYNC" or op == "FSYNC":
        return                                 #ignore

    else:
        raise Exception('Unknown op: ', op)


def replay_file(trace_file):    
    global i
    with open(trace_file, 'r') as tfile:
        for syscall in tfile.readlines():
            replay(syscall.split())
            i = i + 1
            if output and i % 1_000_000 == 0:
                print(i)
    
#python3 replay.py /usr/local/trace/facebook /mnt/pmem0/
if __name__ == '__main__':
    trace_dir = sys.argv[1]
    MNT_PATH = sys.argv[2]
    
    if MNT_PATH[-1] != '/':
        MNT_PATH = MNT_PATH + '/'
    
    pid = os.getpid()
    print("Get PID: " + str(pid))

    process = psutil.Process()
    print(process.num_fds())

    import time
    time_start = time.perf_counter()
    print(trace_dir)

    # for file in os.listdir(trace_dir):
    #     replay_file(trace_dir + '/' + file)
    replay_file(trace_dir + '/' + "trace.syscalltrace")

    time_end = time.perf_counter()
    print('time: %s s' % str(time_end - time_start))
    print('OPS: %s ops/s' % str(i / ((time_end - time_start))))

    # close all file
    for name in OPEN_FILE:
        posix.close(OPEN_FILE[name])
    
    OPEN_FILE.clear()
    OPEN_FILE = {}
    