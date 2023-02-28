CFLAGS := -O3

TARGETS := replay replay_static

all: ${TARGETS}

mt19937ar.o: mt19937ar.c mt19937ar.h
	gcc -c mt19937ar.c -O3 -o $@

lcg.o: lcg.c lcg.h
	gcc -c lcg.c -O3 -o $@

map.o: map.c map.h
	gcc -c map.c -O3 -o $@

replay: replay.c mt19937ar.o lcg.o map.o 
	gcc $^ -O3 -g -o $@ -lpthread

replay_static: replay.c mt19937ar.o lcg.o map.o 
	gcc $^ -static -O3 -o $@ -lpthread
	
%: %.c
	gcc $^ -O3 -o $@

%: %.cpp
	g++ $^ -O3 -o $@

clean:
	rm ${TARGETS}

.PHONY: all clean
