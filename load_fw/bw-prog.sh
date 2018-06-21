#!/bin/bash

DIR=$(dirname $0)

cp "$1" /lib/firmware
insmod "$DIR/fpga-load.ko" path=${1##*/}
rmmod fpga-load.ko
