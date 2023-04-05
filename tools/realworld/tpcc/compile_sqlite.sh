sqlite_path="/usr/local/sqlite3-trace"
cd $sqlite_path
./configure
make clean
make
sudo make install

