import sys

path = sys.argv[1] 

with open(path) as f:
    lines = f.readlines()
    lines = [x.strip() for x in lines] 
    lines = lines[1:]
    lines = [int(x) for x in lines] 
    # max diff
    print("peak: " + str(max(lines) - min(lines)))
    # average
    print("average: " + str(int((sum(lines) - len(lines) * min(lines)) / len(lines))))