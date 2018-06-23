ARCH := arm
PWD := $(shell pwd)
SOURCE_BRANCH="4.14"
SOURCE_VERSION="rc1"
KDIR := $(PWD)/../linux-stable-rcn-ee-$(SOURCE_BRANCH)-$(SOURCE_VERSION)
#KDIR := $(PWD)/../image/bb-kernel/KERNEL/

obj-m+= spi-ice40.o pwm-ice40.o i2c-ice40.o


all:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=${CC} modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) clean

