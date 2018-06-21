SUBDIRS += test
SUBDIRS += blink_leds
SUBDIRS += gpio
SUBDIRS += hd44780
SUBDIRS += i2c
SUBDIRS += lcd
SUBDIRS += lcd_game
SUBDIRS += pwm
SUBDIRS += sdram
SUBDIRS += spi
SUBDIRS += stepper_motor
SUBDIRS += uart
#SUBDIRS += arm_blink_leds

all: $(foreach d,$(SUBDIRS),$d/$d.bin)

%.bin:
	$(MAKE) -C $(dir $@)
