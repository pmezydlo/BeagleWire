#!/bin/bash

echo "$PWD"
cp -av $1 /lib/firmware

# turn on command tracing
set -o xtrace

# change working directory to directory of this running script
cd "${0%/*}"

# turn off command tracing
set +o xtrace
if [ -f fpga-load.ko ] ; then
    echo Found fpga-load.ko
else
    echo ERROR: Did not find fpga-load.ko - You may need to run
    echo ""
    echo cd `pwd`
    echo make
    echo ""
    echo Exiting with ERROR
    exit 1
fi

# turn on command tracing
set -o xtrace
insmod fpga-load.ko path=${1##*/}
rmmod  fpga-load.ko
