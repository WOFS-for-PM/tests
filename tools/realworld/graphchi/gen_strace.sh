cur_dir=$(pwd)

sudo cp /usr/local/graphchi/graph/cit-Patents.txt /mnt/pmem0

cd /usr/local/graphchi/graphchi-cpp && echo edgelist \
| strace -o $cur_dir/strace.txt -e trace=read,write bin/example_apps/pagerank file \
/mnt/pmem0/cit-Patents.txt niters 10 
