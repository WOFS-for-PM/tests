#include "common.h"

/**
 * @brief param->ofs is useless since link write is random
 *
 * @param arg
 */
void link_write(u_int64_t pm_addr, u_int64_t target_addr, unsigned char *content, size_t size, size_t work_space)
{
    u_int64_t random = (rand() % work_space / size) * size;
    target_addr = pm_addr + random;

    memcpy((void *)target_addr, content, size);
    pmem_persist((const void *)target_addr, size);

    return;
}