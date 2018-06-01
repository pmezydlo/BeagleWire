#!/bin/bash

cp $1 /lib/firmware
insmod /home/debian/load/fpga-load.ko path=${1##*/}
rmmod  fpga-load.ko
