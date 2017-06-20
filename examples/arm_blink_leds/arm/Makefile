ARCH = arm
CROSS_CC = arm-linux-gnueabihf-
CC = $(CROSS_CC)gcc
PWD = $(shell pwd)
CFLAGS = -Wall -g

SRCS = blink.c ../../../bridge_lib/bw_bridge.c
OBJS = $(SRCS: .c=.o)
MAIN = main

all: $(MAIN)

$(MAIN): $(OBJS)
	$(CC) $(CFLAGS) -o $(MAIN) $(OBJS)

clean:
	$(RM) *.o *~ $(MAIN)
