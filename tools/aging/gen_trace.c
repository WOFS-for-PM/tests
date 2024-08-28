#include <stdio.h>
#include "mt19937ar.h"

#define FSIZE 64 * 1024 * 1024 * 1024L
#define NUM_BLOCKS (FSIZE / 4096)

#define PM_SIZE 128 * 1024 * 1024 * 1024L
#define NUM_PAGES (PM_SIZE / 4096)

int main() {
    FILE *fp = fopen("trace.txt", "w");
    unsigned long long i, blk;

    init_genrand(0);

    for (i = 0; i < NUM_BLOCKS; i++) {
        blk = genrand_int32() & (NUM_PAGES - 1);
        fprintf(fp, "%lld\n", blk);
    }

    fclose(fp);
    return 0;
}