ARCH = arm
CROSS_CC = arm-linux-gnueabihf-
CC = $(CROSS_CC)gcc
PWD = $(shell pwd)
CFLAGS = -Wall -g

SRCS = i2c_br.c bw_bridge.c
OBJS = $(SRCS: .c=.o)
MAIN = i2c_br

all: $(MAIN)

$(MAIN): $(OBJS)
	$(CC) $(CFLAGS) -o $(MAIN) $(OBJS)

clean:
	$(RM) *.o *~ $(MAIN)
