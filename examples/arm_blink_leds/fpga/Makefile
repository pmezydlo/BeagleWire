PROJ = GPMC
BUILD = ./out
DEVICE = 8k
FOOTPRNT = tq144:4k

SRC = top.v
SRC += ../../../components/gpmc-sync.v
PIN_SRC = pinmap.pcf

.PHONY: all load clean

all:
	mkdir -p $(BUILD)
	yosys -p "synth_ice40 -top top -blif $(BUILD)/$(PROJ).blif" $(SRC)
	arachne-pnr -d $(DEVICE) -P $(FOOTPRNT) -p $(PIN_SRC) -o $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).blif
	icepack $(BUILD)/$(PROJ).asc $(BUILD)/$(PROJ).bin
	echo -e "\x0\x0\x0\x0\x0\x0\x0" >> $(BUILD)/$(PROJ).bin
	
load:
	dd if= $(BUILD)/$(PROJ).bin of=/dev/spidev1.0

clean:
	rm -rf ./$(BUILD)/
