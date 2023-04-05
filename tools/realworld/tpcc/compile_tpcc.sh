cur_dir=`readlink -f ./`

tpcc_path="/usr/local/tpcc-sqlite"
tpcc_build_path="$tpcc_path/src"

cd $tpcc_build_path
make clean
make

cd $cur_dir