/*
 * Copyright (c) 2024 Harbin Institute of Technology, Shenzhen, Yanqi Pan
 * Copyright (c) 2018 Carnegie Mellon University.
 *
 * All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file. See the AUTHORS file for names of contributors.
 */

#include <errno.h>
#include <unistd.h>
#include <sys/stat.h>

#include "backend_driver.h"
#include <fcntl.h>
#include <vector>
#include <bitset>
#include <algorithm>
#include <iterator>
#include <cassert>
#include <iostream>
#include <unordered_map>
#include <string.h>

#define FUNC_TRACE
// printf("function trace: [%s]\n", __func__)

// [start_blk, end_blk)
struct range_node
{
    u_int64_t start_blk;
    u_int64_t end_blk;
};

enum pkg_type
{
    WRITE_PKG,
    CREATE_PKG,
    ATTR_PKG,
    UNLINK_PKG,
};

struct pkg_node
{
    u_int64_t start_blk;
    std::bitset<64> pkg_bitmap;
    enum pkg_type type;
};

struct package
{
    u_int64_t block;
    int offset; // 64~byte aligned
};

struct write_package
{
    package header;
    u_int64_t block;
    u_int64_t num_blocks;
};

struct inode
{
    const char *path;
    int fd;
    std::vector<write_package *> write_pkgs;
    package *create_pkg;
    package *attr_pkg;
};

struct tl_allocator
{
    std::vector<range_node *> free_ranges;

    std::vector<pkg_node *> write_pkg_nodes;
    std::vector<pkg_node *> create_pkg_nodes;
    std::vector<pkg_node *> attr_pkg_nodes;
    std::vector<pkg_node *> unlink_pkg_nodes;

    std::vector<pkg_node *> used_pkg_nodes;
};

// --------------------------------------------

static std::unordered_map<std::string, inode *> inode_table;
static std::unordered_map<u_int64_t, package *> order_map;

static void dump_inode_table(void)
{
    std::cout << "start dump inode table" << std::endl;
    for (auto &entry : inode_table)
    {
        std::cout << "path: " << entry.first << ", fd: " << entry.second->fd << std::endl;
    }
    std::cout << "end dump inode table" << std::endl;
}

static tl_allocator allocator;

// #define NUM_BLOCKS (256 * 1024L * 1024L * 1024L / 4096)
#define NUM_BLOCKS (256 * 1024L * 1024L * 1024L / 4096)

static void init_allocator(void)
{
    FUNC_TRACE;

    range_node *range = new range_node;
    range->start_blk = 1;
    range->end_blk = NUM_BLOCKS;

    allocator.free_ranges.push_back(range);
}

static u_int64_t allocate_blocks(u_int64_t *start_blk, u_int64_t *num_blocks)
{
    u_int64_t allocated = 0;
    range_node *first_range, *range;

    *start_blk = 0;
    
    // use find_if instead of for loop
    auto it = std::find_if(allocator.free_ranges.begin(), allocator.free_ranges.end(), // range_node
                           [&num_blocks](const range_node *range)
                           {
                               return range->end_blk - range->start_blk >= *num_blocks;
                           });

    if (it != allocator.free_ranges.end())
    {
        *start_blk = (*it)->start_blk;
        (*it)->start_blk += *num_blocks;
        allocated = *num_blocks;
        *num_blocks -= allocated;

        if ((*it)->start_blk == (*it)->end_blk)
        {
            delete (*it);
            allocator.free_ranges.erase(it);
        }
    }

    if (allocated == 0)
    {
        if (allocator.free_ranges.empty())
        {
            assert(0);
            return 0;
        }

        // allocate best effort
        
        first_range = allocator.free_ranges.front();

        // allocate the first range
        *start_blk = first_range->start_blk;
        allocated = first_range->end_blk - first_range->start_blk;
        *num_blocks -= allocated;

        // delete first_range;
        delete first_range;

        // remove the first range
        allocator.free_ranges.erase(allocator.free_ranges.begin());
    }

    // printf("%s: allocate %lu blocks at blk %lu\n", __func__, allocated, *start_blk);

    return allocated;
}

static void free_blocks(u_int64_t start_blk, u_int64_t num_blocks)
{
    auto it = std::find_if(allocator.free_ranges.begin(), allocator.free_ranges.end(),
                           [&start_blk, &num_blocks](const range_node *range)
                           {
                               return range->start_blk == start_blk + num_blocks || range->end_blk == start_blk;
                           });
    if (it != allocator.free_ranges.end())
    {
        if ((*it)->start_blk == start_blk + num_blocks)
        {
            (*it)->start_blk = start_blk;
        }
        else if ((*it)->end_blk == start_blk)
        {
            (*it)->end_blk = start_blk + num_blocks;
        }
    }
    else
    {
        range_node *range = new range_node;
        range->start_blk = start_blk;
        range->end_blk = start_blk + num_blocks;
        
        // sort by start_blk
        auto it = std::lower_bound(allocator.free_ranges.begin(), allocator.free_ranges.end(), range,
                                   [](const range_node *a, const range_node *b)
                                   {
                                       return a->start_blk < b->start_blk;
                                   });

        allocator.free_ranges.insert(it, range);
    }
}

static int pkg_type_to_num_metablks(pkg_type type)
{
    switch (type)
    {
    case WRITE_PKG:
        return 1;
    case CREATE_PKG:
        return 4;
    case ATTR_PKG:
        return 1;
    case UNLINK_PKG:
        return 1;
    default:
        return 0;
    }
}

const char *pkg_type_to_str(pkg_type type)
{
    switch (type)
    {
    case WRITE_PKG:
        return "WRITE_PKG";
    case CREATE_PKG:
        return "CREATE_PKG";
    case ATTR_PKG:
        return "ATTR_PKG";
    case UNLINK_PKG:
        return "UNLINK_PKG";
    default:
        return "UNKNOWN";
    }
}

static std::vector<pkg_node *> *pkg_type_to_pkg_nodes(pkg_type type)
{
    switch (type)
    {
    case WRITE_PKG:
        return &allocator.write_pkg_nodes;
    case CREATE_PKG:
        return &allocator.create_pkg_nodes;
    case ATTR_PKG:
        return &allocator.attr_pkg_nodes;
    case UNLINK_PKG:
        return &allocator.unlink_pkg_nodes;
    default:
        return nullptr;
    }
}

static int allocate_pkg(pkg_type type, u_int64_t *start_blk, int *offset)
{
    pkg_node *first_node;
    std::vector<pkg_node *> *pkg_nodes = pkg_type_to_pkg_nodes(type);
    int num_metablks = pkg_type_to_num_metablks(type);
    bool need_allocate = false;

retry:
    if (need_allocate)
    {
        u_int64_t num_blocks = 1;
        u_int64_t start_blk = 0;
        pkg_node *node;

        allocate_blocks(&start_blk, &num_blocks);

        if (start_blk == 0)
        {
            assert(0);
            return -ENOSPC;
        }

        // allocate a new node
        node = new pkg_node;
        node->start_blk = start_blk;
        node->pkg_bitmap = std::bitset<64>();
        node->type = type;

        pkg_nodes->push_back(node);
        allocator.used_pkg_nodes.push_back(node);

        // output node memory address
        // is this allocated or on stack?
        // std::cout << "node address: " << node << std::endl;
    }

    // iterate pkg_nodes in a backward way
    for (auto it = pkg_nodes->rbegin(); it != pkg_nodes->rend(); it++)
    {
        pkg_node *node = *it;
        int i;
        for (i = 0; i < 64; i++)
        {
            if (!node->pkg_bitmap.test(i))
            {
                *start_blk = node->start_blk;
                *offset = i;
                for (int j = 0; j < num_metablks; j++)
                {
                    node->pkg_bitmap.set(i + j);
                }
                break;
            }
        }

        if (i != 64)
        {
            // allocated
            return 0;
        }
    }

    // no available space, retry
    need_allocate = true;
    goto retry;
}

static void free_pkg(pkg_type type, u_int64_t start_blk, int offset)
{
    std::vector<pkg_node *> *pkg_nodes = pkg_type_to_pkg_nodes(type);
    int num_metablks = pkg_type_to_num_metablks(type);
    bool is_in_unused = false;

    auto used_it = std::find_if(allocator.used_pkg_nodes.begin(), allocator.used_pkg_nodes.end(),
                                [&start_blk, &offset](const pkg_node *node)
                                {
                                    return node->start_blk == start_blk;
                                });

    if (used_it != allocator.used_pkg_nodes.end())
    {
        for (int i = 0; i < num_metablks; i++)
        {
            (*used_it)->pkg_bitmap.reset(offset + i);
        }
    }
    else
    {
        // error
        assert(0);
    }
}

static void bench_end(ssize_t total_disk_capacity)
{
    FUNC_TRACE;
    u_int64_t data_locality[513] = {0};
    u_int64_t meta_locality[5] = {0};
    u_int64_t total_blocks = total_disk_capacity / 4096;
    printf("total_blocks: %lu\n", total_blocks);
    // output allocator info
    std::cout << "free_ranges: " << std::endl;

    for (auto &range : allocator.free_ranges)
    {
        std::cout << "start_blk: " << range->start_blk << ", end_blk: " << range->end_blk << std::endl;
        u_int64_t num_blocks = range->end_blk - range->start_blk;

        // NOTE: regulate the last ranges
        if (range == allocator.free_ranges.back())
        {
            if (range->end_blk > total_blocks && range->start_blk < total_blocks) {
                num_blocks = total_blocks - range->start_blk;
            } else {
                continue;
            }
        }

        if (num_blocks >= 512)
        {
            data_locality[512] += num_blocks;
        }
        else
        {
            data_locality[num_blocks] += num_blocks;
        }
    }

    // output allocated metadata
    std::cout << "meta avaible (WTF?): " << std::endl;
    for (auto &node : allocator.used_pkg_nodes)
    {
        if (node->pkg_bitmap.count() != 64)
        {
            std::cout << "start_blk: " << node->start_blk << ", pkg_bitmap (" << node->type << "): " << node->pkg_bitmap << std::endl;
        }

        if (node->type != CREATE_PKG && node->type != UNLINK_PKG) {
            // iterate pkg_bitmap
            int counter = 0;
            for (int i = 0; i < 64; i++)
            {
                if (!node->pkg_bitmap.test(i))
                {
                    counter++;
                }

                if (i % 4 == 3)
                {
                    meta_locality[counter] += counter;
                    counter = 0;
                }
            }
        }
    }

    // clear inodes
    for (auto &inode : inode_table)
    {
        // std::cout << "final clear path: " << inode.first << ", fd: " << inode.second->fd << std::endl;
        for (auto pkg : inode.second->write_pkgs)
        {
            delete pkg;
        }
        inode.second->write_pkgs.clear();
        delete inode.second->create_pkg;
        delete inode.second->attr_pkg;
    }
    // clear inode table
    inode_table.clear();

    // clear allocator
    for (auto node : allocator.used_pkg_nodes)
    {
        delete node;
    }
    allocator.used_pkg_nodes.clear();

    allocator.attr_pkg_nodes.clear();
    allocator.create_pkg_nodes.clear();
    allocator.write_pkg_nodes.clear();
    allocator.unlink_pkg_nodes.clear();

    for (auto node : allocator.free_ranges)
    {
        delete node;
    }
    allocator.free_ranges.clear();

    // clear order map
    for (auto &order : order_map)
    {
        delete order.second;
    }
    order_map.clear();

    // output data_locality
    std::cout << "data_locality: " << std::endl;
    u_int64_t total_data_blocks = 0;
    for (int i = 1; i < 512; i++)
    {
        total_data_blocks += data_locality[i];
    }
    for (int i = 1; i < 512; i++)
    {
        if (data_locality[i] == 0)
        {
            continue;
        }
        std::cout << "data_locality[" << i << "]: " << float(data_locality[i]) / total_data_blocks << std::endl;
    }

    // output meta_locality
    std::cout << "meta_locality: " << std::endl;
    u_int64_t total_meta_blocks = 0;
    for (int i = 1; i < 5; i++)
    {
        total_meta_blocks += meta_locality[i];
    }
    for (int i = 1; i < 5; i++)
    {
        std::cout << "meta_locality[" << i << "]: " << float(meta_locality[i]) / total_meta_blocks << std::endl;
    }
}

static int dback_open(const char *path, int flags, ...)
{
    FUNC_TRACE;

    package *create_pkg;
    inode *inode;
    int fd;

    fd = open(path, flags, 0600);
    // if create
    if (flags & O_CREAT)
    {
        u_int64_t unlink_key;
        package *unlink_pkg;

        create_pkg = new package;
        inode = new struct inode;

        allocate_pkg(CREATE_PKG, &create_pkg->block, &create_pkg->offset);
        unlink_key = create_pkg->block << 6 | create_pkg->offset;
        // check order_map
        auto pair = order_map.find(unlink_key);
        if (pair != order_map.end())
        {
            unlink_pkg = pair->second;
            free_pkg(UNLINK_PKG, unlink_pkg->block, unlink_pkg->offset);
            delete unlink_pkg;
            order_map.erase(unlink_key);
        }

        inode->path = path;
        inode->create_pkg = create_pkg;
        inode->attr_pkg = NULL;
        inode->write_pkgs.clear();

        inode_table[path] = inode;
        // dump_inode_table();
    }
    return fd;
}

static int dback_access(const char *path, int mode)
{
    FUNC_TRACE;

    return access(path, mode);
}

static int dback_close(int fd)
{
    FUNC_TRACE;

    return close(fd);
}

static int dback_unlink(const char *path)
{
    FUNC_TRACE;

    // printf("unlink path: %s\n", path);
    int ret;
    auto pair = inode_table.find(path);
    if (pair == inode_table.end())
    {
        // printf("unlink path: %s, inode not found\n", path);
        return unlink(path);
    }

    package *unlink_pkg;
    inode *inode = pair->second;
    u_int64_t unlink_key;

    unlink_pkg = new package;
    
    allocate_pkg(UNLINK_PKG, &unlink_pkg->block, &unlink_pkg->offset);
    unlink_key = inode->create_pkg->block << 6 | inode->create_pkg->offset;
    // from create_pkg to unlink_pkg
    order_map[unlink_key] = unlink_pkg;

    free_pkg(CREATE_PKG, inode->create_pkg->block, inode->create_pkg->offset);
    
    if (inode->attr_pkg)
        free_pkg(ATTR_PKG, inode->attr_pkg->block, inode->attr_pkg->offset);

    for (auto &pkg : inode->write_pkgs)
    {
        free_blocks(pkg->block, pkg->num_blocks);
        free_pkg(WRITE_PKG, pkg->header.block, pkg->header.offset);
    }

    // erase inode_table
    ret = inode_table.erase(path);
    assert(ret == 1);

    return unlink(path);
}

static int dback_mkdir(const char *path, mode_t mode)
{
    // FUNC_TRACE;

    int ret = mkdir(path, mode);
    if (ret == 0)
    {
        package *unlink_pkg;
        package *create_pkg = new package;
        inode *inode = new struct inode;
        u_int64_t unlink_key;

        allocate_pkg(CREATE_PKG, &create_pkg->block, &create_pkg->offset);
        unlink_key = create_pkg->block << 6 | create_pkg->offset;
        
        // check order_map
        auto pair = order_map.find(unlink_key);
        if (pair != order_map.end())
        {
            unlink_pkg = pair->second;
            free_pkg(UNLINK_PKG, unlink_pkg->block, unlink_pkg->offset);
            delete unlink_pkg;
            order_map.erase(unlink_key);
        }

        inode->path = path;
        inode->create_pkg = create_pkg;
        inode->attr_pkg = NULL;

        inode_table[path] = inode;
    }

    return ret;
}

static int dback_stat(const char *path, struct stat *st)
{
    // FUNC_TRACE;

    return stat(path, st);
}

static int dback_chmod(const char *path, mode_t mode)
{
    FUNC_TRACE;

    inode *inode = inode_table[path];
    assert(inode != NULL);
    free_pkg(ATTR_PKG, inode->attr_pkg->block, inode_table[path]->attr_pkg->offset);
    allocate_pkg(ATTR_PKG, &inode->attr_pkg->block, &inode->attr_pkg->offset);
    return chmod(path, mode);
}

/*
 * deltafs version of fake posix_fallocate... (XXX could make shared
 * version of this, but too small to bother with?)
 */
static int dback_fallocate(int fd, off_t offset, off_t len)
{
    FUNC_TRACE;

    // round up to block size
    u_int64_t num_blocks = (len + 4095) / 4096;
    u_int64_t start_blk = 0;
    write_package *write_pkg;
    pid_t pid = getpid();
    const char *path = NULL;
    int meta_offset = 0;
    int ret = 0;

    // get file path from fd using file system interface /proc/self/fd
    char fd_path[64];
    sprintf(fd_path, "/proc/%d/fd/%d", pid, fd);
    char link_path[256];
    ssize_t link_len = readlink(fd_path, link_path, 256);
    assert(link_len != -1);
    if (link_len != -1)
    {
        link_path[link_len] = '\0';
        path = link_path;
    }


    // printf("fallocate: offset %ld, len %ld, num_blocks %lu, path %s\n", offset, len, num_blocks, path);

    while (num_blocks > 0)
    {
        write_pkg = new write_package;

        ret = allocate_blocks(&write_pkg->block, &num_blocks);
        assert(ret > 0);

        write_pkg->num_blocks = ret;

        ret = allocate_pkg(WRITE_PKG, &write_pkg->header.block, &write_pkg->header.offset);
        assert(ret == 0);

        inode_table[path]->write_pkgs.push_back(write_pkg);
    }
    // printf("done fallocate\n");
    return 0;
}

/*
 * here is the main driver structure....
 */
struct backend_driver killer_backend_driver = {
    dback_open,
    dback_close,
    dback_access,
    dback_unlink,
    dback_mkdir,
    dback_fallocate,
    dback_stat,
    dback_chmod,
    bench_end,
    init_allocator,
};
