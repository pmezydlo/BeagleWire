ARCH := arm
COMPILER := arm-linux-gnueabihf-
COMPILER_V := gcc
PWD := $(shell pwd)
KERN_V=4.4.30
BUILD_V=-ti-r64
SOURCE=KERNEL

KDIR := $(PWD)/../image/bb-kernel/KERNEL

obj-m+= spi-ice40.o

all:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(COMPILER) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) clean
