ARCH = arm
CROSS_CC = arm-linux-gnueabihf-
CC = $(CROSS_CC)gcc
PWD = $(shell pwd)
CFLAGS = -Wall -g

SRCS = main.c BW_bridge.c
OBJS = $(SRCS: .c=.o)
MAIN = main

all: $(MAIN)

$(MAIN): $(OBJS)
	$(CC) $(CFLAGS) -o $(MAIN) $(OBJS)

clean:
	$(RM) *.o *~ $(MAIN)
