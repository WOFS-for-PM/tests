import sys

size_ranges = [
    ('0-1KB', 1024), 
    ('1-4KB', 4096), 
    ('4-10KB', 10240), 
    ('>10KB', float('inf'))]

def get_size_range(write_size):
    for size_range, upper_bound in size_ranges:
        if write_size <= upper_bound:
            return size_range

if __name__ == '__main__':
    strace_file = sys.argv[1]
    with open(strace_file, 'r') as f:
        w_size = {}
        w_times = {}
        r_size = {}
        r_times = {}
        for line in f:
            if 'write(' in line and '/mnt/pmem0' in line:
                size = int(line.split(', ')[1][:-1])
                range = get_size_range(size)
                w_size[range] += size
                w_times[range] += 1 

            if 'read(' in line and '/mnt/pmem0' in line:
                size = int(line.split(', ')[1][:-1])
                range = get_size_range(size)
                r_size[range] += size
                r_times[range] += 1 
            
    # Calculate the average write size
    w_total_size = sum(w_size.values())
    w_total_time = sum(w_times.values())
    r_total_size = sum(r_size.values())
    r_total_time = sum(r_times.values())

    print("{:<10} | {:<10}{:<10}{:<10} | {:<10}{:<10}{:<10}".format("range", "write_size", "write_times", "write_avg", "read_size", "read_times", "read_avg"))
    for range in size_ranges:
         key = range.key()
         write_size = w_size[key]
         write_times = w_times[key]
         read_size = r_size[key]
         read_times = r_times[key]
         print("{:<10} | {:<10}{:<10}{:<10} | {:<10}{:<10}{:<10}"
        .format(range.key(), write_size, write_times, write_size / write_times,
                read_size, read_times, read_size / read_times))
    print("\n")

    # Print the total write size and average write size
    print(f'Total write size: {w_total_size}')
    print(f'Average write size: {w_total_size / w_total_time}')
    print(f'Total read size: {r_total_size}')
    print(f'Average read size: {r_total_size / r_total_time}')