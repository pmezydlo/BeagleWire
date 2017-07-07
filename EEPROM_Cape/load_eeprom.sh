#!/bin/bash
cat BW_EEPROM.bin > /sys/bus/i2c/devices/i2c-2/2-0054/eeprom
cat /sys/bus/i2c/devices/i2c-2/2-0054/eeprom | hexdump -C

