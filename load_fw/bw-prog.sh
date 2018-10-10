#!/bin/bash

# USAGE
#     sudo sh bw-prog.sh bw-fpga.bin

echo "$PWD"

# copy .bin file to kernel location
cp -av $1 /lib/firmware

# determine directory of this running script
DIR=$(dirname $0)

# turn on command tracing
set -o xtrace

# change working directory to directory of this running script
cd "${DIR}"

# turn off command tracing
set +o xtrace
if [ -f fpga-load.ko ] ; then
    echo Found fpga-load.ko
else
    echo ERROR: Did not find fpga-load.ko - You may need to run
    echo ""
    echo cd $(pwd)
    echo make
    echo ""
    echo Exiting with ERROR
    exit 1
fi

# turn on command tracing
set -o xtrace
insmod fpga-load.ko path=${1##*/}
rmmod  fpga-load.ko
