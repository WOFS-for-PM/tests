#include <linux/bitops.h>
#include <linux/cred.h>
#include <linux/ctype.h>
#include <linux/dax.h>
#include <linux/exportfs.h>
#include <linux/init.h>
#include <linux/io.h>
#include <linux/kernel.h> /* Needed for KERN_INFO */
#include <linux/kthread.h>
#include <linux/list.h>
#include <linux/magic.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/parser.h>
#include <linux/pfn_t.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/time.h>
#include <linux/uaccess.h>

#define FORMATER_NUM 4

static char *disk_name = "pmem0";
module_param(disk_name, charp, S_IRUGO | S_IWUSR);
MODULE_PARM_DESC(disk_name, "The name of raw pmem block device (e.g., pmem0)");

typedef struct timespec timing_t;

void *virt_addr = NULL;
u64 size;

int cpus;

typedef struct formater_param {
    u32 formater_id;
    u32 total_formaters;
} formater_param_t;

wait_queue_head_t finish_wq;
int *finished;

static void wait_to_finish(int cpus)
{
    int i;

    for (i = 0; i < cpus; i++) {
        while (finished[i] == 0) {
            wait_event_interruptible_timeout(finish_wq, false,
                                             msecs_to_jiffies(1));
        }
    }
}

/* assumes the length to be 4-byte aligned */
static inline void memset_nt(void *dest, uint32_t dword, size_t length)
{
    uint64_t dummy1, dummy2;
    uint64_t qword = ((uint64_t)dword << 32) | dword;

    BUG_ON(length > ((u64)1 << 32));

    asm volatile("movl %%edx,%%ecx\n"
                 "andl $63,%%edx\n"
                 "shrl $6,%%ecx\n"
                 "jz 9f\n"
                 "1:	 movnti %%rax,(%%rdi)\n"
                 "2:	 movnti %%rax,1*8(%%rdi)\n"
                 "3:	 movnti %%rax,2*8(%%rdi)\n"
                 "4:	 movnti %%rax,3*8(%%rdi)\n"
                 "5:	 movnti %%rax,4*8(%%rdi)\n"
                 "8:	 movnti %%rax,5*8(%%rdi)\n"
                 "7:	 movnti %%rax,6*8(%%rdi)\n"
                 "8:	 movnti %%rax,7*8(%%rdi)\n"
                 "leaq 64(%%rdi),%%rdi\n"
                 "decl %%ecx\n"
                 "jnz 1b\n"
                 "9:	movl %%edx,%%ecx\n"
                 "andl $7,%%edx\n"
                 "shrl $3,%%ecx\n"
                 "jz 11f\n"
                 "10:	 movnti %%rax,(%%rdi)\n"
                 "leaq 8(%%rdi),%%rdi\n"
                 "decl %%ecx\n"
                 "jnz 10b\n"
                 "11:	 movl %%edx,%%ecx\n"
                 "shrl $2,%%ecx\n"
                 "jz 12f\n"
                 "movnti %%eax,(%%rdi)\n"
                 "12:\n"
                 : "=D"(dummy1), "=d"(dummy2)
                 : "D"(dest), "a"(qword), "d"(length)
                 : "memory", "rcx");
}

typedef struct formater_work {
    u32 start_blk;
    u32 blks;
} formater_work_t;

void __assign_formater_work(u32 formater_id, u32 total_formaters, formater_work_t *work)
{
    u32 total_blks = (size >> PAGE_SHIFT);
    u32 blks_per_formater = total_blks / total_formaters;
    u32 start_blk = formater_id * blks_per_formater;
    u32 end_blk = (formater_id + 1) * blks_per_formater;
    u32 blks = blks_per_formater;

    if (formater_id == total_formaters - 1) {
        end_blk = total_blks;
        blks = end_blk - start_blk;
    }

    work->start_blk = start_blk;
    work->blks = blks;
}

void *killer_formater(void *args)
{
    formater_param_t *param = (formater_param_t *)args;
    u32 formater_id = param->formater_id;
    u32 total_formaters = param->total_formaters;
    formater_work_t work;
    u32 cur_blk;
    u64 addr;

    __assign_formater_work(formater_id, total_formaters, &work);
    pr_info(KBUILD_MODNAME ": formater %d start blk %d, end blk %d, probe blks %d\n", formater_id, work.start_blk, work.start_blk + work.blks - 1, work.blks);

    /* start clean */
    for (cur_blk = work.start_blk; cur_blk < work.start_blk + work.blks; cur_blk++) {
        addr = (u64)virt_addr + (u64)cur_blk * PAGE_SIZE;
        memset_nt((void *)addr, 0, PAGE_SIZE);
        /* be nice */
        schedule();
    }

    finished[formater_id] = 1;
    wake_up_interruptible(&finish_wq);
    pr_info(KBUILD_MODNAME ": formater %d finish\n", formater_id);
    kfree(args);
    do_exit(0);

    return NULL;
}

static int killer_format(void)
{
    /* multiple thread erase pm */
    struct task_struct **formater_threads;
    int i, ret = 0;
    timing_t timer = {0}, timer_end = {0};

    cpus = FORMATER_NUM;

    getrawmonotonic(&timer);
    pr_info(KBUILD_MODNAME ": format killer using %d threads\n", cpus);

    init_waitqueue_head(&finish_wq);
    formater_threads = (struct task_struct **)kzalloc(sizeof(struct task_struct) * cpus, GFP_KERNEL);
    if (!formater_threads) {
        pr_info(KBUILD_MODNAME ": Allocate formater threads failed\n");
        ret = -ENOMEM;
        goto out;
    }

    finished = kcalloc(cpus, sizeof(int), GFP_KERNEL);
    if (!finished) {
        pr_info(KBUILD_MODNAME ": Allocate finished array failed\n");
        ret = -ENOMEM;
        goto out;
    }
    memset(finished, 0, sizeof(int) * cpus);

    for (i = 0; i < cpus; i++) {
        formater_param_t *param = (formater_param_t *)kzalloc(sizeof(formater_param_t), GFP_KERNEL);
        if (!param) {
            pr_info(KBUILD_MODNAME ": Allocate formater param failed\n");
            ret = -ENOMEM;
            goto out;
        }
        param->formater_id = i;
        param->total_formaters = cpus;

        formater_threads[i] = kthread_create((void *)killer_formater, (void *)param, "killer_formater%d", i);
        if (IS_ERR(formater_threads[i])) {
            pr_info(KBUILD_MODNAME ": Create formater thread %d failed\n", i);
            ret = PTR_ERR(formater_threads[i]);
            goto out;
        }
        wake_up_process(formater_threads[i]);

        if (ret) {
            pr_info(KBUILD_MODNAME ": Create formater thread %d failed\n", i);
            goto out;
        }
    }

    wait_to_finish(cpus);
    kfree(finished);
    kfree(formater_threads);

    getrawmonotonic(&timer_end);

    u64 time = (timer_end.tv_sec - timer.tv_sec) * 1000000000 + (timer_end.tv_nsec - timer.tv_nsec);
    pr_info(KBUILD_MODNAME ": format killer using %d threads, time %llu ns (%llu s)\n", cpus, time, time / 1000000000);

out:
    return 0;
}

static int get_nvmm_info(void)
{
    pfn_t __pfn_t;
    struct dax_device *dax_dev;
    phys_addr_t phys_addr;

    dax_dev = fs_dax_get_by_host(disk_name);
    if (!dax_dev) {
        pr_err(KBUILD_MODNAME ": "
                              " Couldn't retrieve DAX device.\n");
        return -EINVAL;
    }

    size = PAGE_SIZE * dax_direct_access(dax_dev, 0, LONG_MAX / PAGE_SIZE,
                                         &virt_addr, &__pfn_t);
    if (size <= 0) {
        pr_err("direct_access failed\n");
        return -EINVAL;
    }

    phys_addr = pfn_t_to_pfn(__pfn_t) << PAGE_SHIFT;

    pr_info(KBUILD_MODNAME ": "
                           "%s: dev %s, phys_addr 0x%llx, virt_addr 0x%lx - 0x%lx, size %ld\n",
            __func__, disk_name, phys_addr, (unsigned long)virt_addr, (unsigned long)(virt_addr + size),
            size);
    return 0;
}

int __init init_killer_formater(void)
{
    printk(KERN_INFO "%s\n", disk_name);
    get_nvmm_info();
    killer_format();
    return 0;
}

void __exit exit_killer_formater(void)
{
    printk(KERN_INFO "Goodbye world 1.\n");
}

MODULE_AUTHOR("Yanqi Pan <deadpoolmine@qq.com>");
MODULE_DESCRIPTION("A PM formater for KILLER");
MODULE_LICENSE("GPL");

module_init(init_killer_formater);
module_exit(exit_killer_formater);