#ifndef _HUNTER_TEST_LOG_STRUCTURE_COMMON_H
#define _HUNTER_TEST_LOG_STRUCTURE_COMMON_H

#include "libpmem.h"
#include "pthread.h"
#include "sys/time.h"
#include "sys/types.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "pm_util_c.h"

typedef void (*write_iter)(u_int64_t pm_addr, u_int64_t target_addr, unsigned char *content, size_t size, size_t work_space);

struct wr_param {
    off_t ofs;
    unsigned char *content;
    size_t size;
    size_t each;
    u_int64_t pm_addr;
    write_iter write_func;
};

void log_write(u_int64_t pm_addr, u_int64_t target_addr, unsigned char *content, size_t size, size_t work_space);
void link_write(u_int64_t pm_addr, u_int64_t target_addr, unsigned char *content, size_t size, size_t work_space);
#endif // _HUNTER_TEST_LOG_STRUCTURE_COMMON_H
