#ifndef _KILLER_FORMATER_INCLUDE_H_
#define _KILLER_FORMATER_INCLUDE_H_

#include <linux/bitops.h>
#include <linux/crc32c.h>
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

#define KILLER_HDR_MAGIC      0x4b4c5244 /* "KLRD" */
#define KILLER_HINT_EMPTY_BLK 0x0f0f0f0f

typedef struct killer_bhint_hdr {
    u32 magic;
    u32 hint;
    u32 hcrc32;
    u32 bcrc32;
} __attribute__((__packed__));

#endif /* _KILLER_FORMATER_INCLUDE_H_ */