import re
import os

if __name__ == '__main__':
    with open('syscall-trace-results', 'w') as output:
        output.write("fs workload sys_time\n")
        for workload in os.listdir("./output"):
            workload_path = os.path.join("./output", workload)
            for fs in os.listdir(workload_path):
                fs_path = os.path.join(workload_path, fs)
                with open(fs_path, 'r') as f:
                    contents = f.read()
                    real = re.search(r'real.*?(\d+\.?\d*m\d+\.?\d*s)', contents).group(1)
                    user = re.search(r'user.*?(\d+\.?\d*m\d+\.?\d*s)', contents).group(1)
                    sys = re.search(r'sys.*?(\d+\.?\d*m\d+\.?\d*s)', contents).group(1)
                    output.write(fs + " " + workload + " "+ sys + "\n")
                
