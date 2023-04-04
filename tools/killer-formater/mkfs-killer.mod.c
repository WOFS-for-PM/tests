#include <linux/build-salt.h>
#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

BUILD_SALT;

MODULE_INFO(vermagic, VERMAGIC_STRING);
MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};

#ifdef CONFIG_RETPOLINE
MODULE_INFO(retpoline, "Y");
#endif

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0xd2d6ffbd, "module_layout" },
	{ 0x3186837a, "kmalloc_caches" },
	{ 0xeb233a45, "__kmalloc" },
	{ 0x1db7706b, "__copy_user_nocache" },
	{ 0x84f15016, "boot_cpu_data" },
	{ 0x7a2af7b4, "cpu_number" },
	{ 0xb15b4109, "crc32c" },
	{ 0x2cf868f0, "kthread_create_on_node" },
	{ 0xd9a5ea54, "__init_waitqueue_head" },
	{ 0x7fedd702, "param_ops_charp" },
	{ 0xc5850110, "printk" },
	{ 0x1edb69d6, "ktime_get_raw_ts64" },
	{ 0xa1c76e0a, "_cond_resched" },
	{ 0x952664c5, "do_exit" },
	{ 0xfe487975, "init_wait_entry" },
	{ 0x6958ae23, "dax_get_by_host" },
	{ 0xdecd0b29, "__stack_chk_fail" },
	{ 0x8ddd8aad, "schedule_timeout" },
	{ 0x1000e51, "schedule" },
	{ 0x3efd1889, "dax_direct_access" },
	{ 0x90abd77a, "wake_up_process" },
	{ 0xbdfb6dbb, "__fentry__" },
	{ 0xb1381ad5, "kmem_cache_alloc_trace" },
	{ 0x3eeb2322, "__wake_up" },
	{ 0x8c26d495, "prepare_to_wait_event" },
	{ 0x37a0cba, "kfree" },
	{ 0x92540fbf, "finish_wait" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=libcrc32c";


MODULE_INFO(srcversion, "D460EE8A8C4E998B54B994A");
