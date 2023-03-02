#include <linux/bitops.h>
#include <linux/cred.h>
#include <linux/ctype.h>
#include <linux/dax.h>
#include <linux/exportfs.h>
#include <linux/init.h>
#include <linux/io.h>
#include <linux/kernel.h> /* Needed for KERN_INFO */
#include <linux/list.h>
#include <linux/magic.h>
#include <linux/mm.h>
#include <linux/module.h>
#include <linux/parser.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/uaccess.h>
#include <linux/pfn_t.h>

static char *disk_name = "pmem0";
module_param(disk_name, charp, S_IRUGO | S_IWUSR); 
MODULE_PARM_DESC(disk_name, "The name of raw pmem block device (e.g., pmem0)");

void *virt_addr = NULL;

static int get_nvmm_info(void)
{
    pfn_t __pfn_t;
    long size;
    struct dax_device *dax_dev;
    phys_addr_t phys_addr;

    dax_dev = fs_dax_get_by_host(disk_name);
    if (!dax_dev) {
        pr_err(KBUILD_MODNAME ": "" Couldn't retrieve DAX device.\n");
        return -EINVAL;
    }

    size = PAGE_SIZE * dax_direct_access(dax_dev, 0, LONG_MAX / PAGE_SIZE,
                                         &virt_addr, &__pfn_t);
    if (size <= 0) {
        pr_err("direct_access failed\n");
        return -EINVAL;
    }

    phys_addr = pfn_t_to_pfn(__pfn_t) << PAGE_SHIFT;

    pr_info(KBUILD_MODNAME ": ""%s: dev %s, phys_addr 0x%llx, virt_addr 0x%lx - 0x%lx, size %ld\n",
            __func__, disk_name, phys_addr, (unsigned long)virt_addr, (unsigned long)(virt_addr + size),
            size);

    return 0;
}

int __init init_pm_range_detector(void)
{
    printk(KERN_INFO "%s\n", disk_name);
    get_nvmm_info();
    return 0;
}

void __exit exit_pm_range_detector(void)
{
    printk(KERN_INFO "Goodbye world 1.\n");
}

MODULE_AUTHOR("Yanqi Pan <deadpoolmine@qq.com>");
MODULE_DESCRIPTION("PM Virtual Memory Range Detector");
MODULE_LICENSE("GPL");

module_init(init_pm_range_detector)
module_exit(exit_pm_range_detector)