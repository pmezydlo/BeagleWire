ARCH := arm
COMPILER := arm-linux-gnueabihf-
COMPILER_V := gcc
PWD := $(shell pwd)
SOURCE_BRANCH="4.12"
SOURCE_VERSION="rc7"
KDIR := $(PWD)/../linux-stable-rcn-ee-$(SOURCE_BRANCH)-$(SOURCE_VERSION)

obj-m+= spi-ice40.o pwm-ice40.o

all:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(COMPILER) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) ARCH=$(ARCH) clean
