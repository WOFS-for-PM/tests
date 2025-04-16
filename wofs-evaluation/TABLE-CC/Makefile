CC = g++
CFLAGS = -Wall -Wextra -pedantic -std=c++17

all: gen_cp

gen_cp: gen_cp.cpp
	$(CC) $(CFLAGS) -o gen_cp gen_cp.cpp

.PHONY: clean
clean:
	rm -f gen_cp