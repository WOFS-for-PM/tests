#include "common.h"

/**
 * @brief log write is appending write, and higher level ensures it is not overwritten
 *
 * @param arg
 */
void log_write(u_int64_t pm_addr, u_int64_t target_addr, unsigned char *content, size_t size, size_t work_space)
{
    u_int64_t random = (rand() % work_space / size) * size;
    target_addr = target_addr + 0;

    memcpy((void *)target_addr, content, size);
    pmem_persist((const void *)target_addr, size);

    return;
}