#
# Makefile for the pmem virtual address range detection module
#

obj-m += pm_range_detect.o

pm_range_detect-y := main.o

all:
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=`pwd`

clean:
	$(MAKE) -C /lib/modules/$(shell uname -r)/build M=`pwd` clean