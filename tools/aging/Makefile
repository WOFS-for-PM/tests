all:
	gcc -o gen_trace gen_trace.c mt19937ar.c -Wall -Wextra -Werror -O3 -g -std=c99 -lm
	gcc -o aging_system aging_system.c mt19937ar.c -Wall -Wextra -O3 -g -std=c99 -lm