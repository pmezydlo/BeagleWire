outdir=out/
name="counter"

.PHONY: all
all: synth load

.PHONY: synth
synth:	$(outdir)counter.bin

$(outdir)counter.bin: counter.v counter.pcf $(src)
	@mkdir -p $(outdir)
	yosys -q -p "synth_ice40 -blif $(outdir)$(name).blif" $(name).v $(src)
	arachne-pnr -d 8k -P tq144:4k -p $(name).pcf $(outdir)$(name).blif -o $(outdir)$(name).txt
	icepack $(outdir)$(name).txt $(outdir)$(name).bin

.PHONY: load
load:
	dd if=$(outdir)$(name).bin of=/dev/spidev1.0

.PHONY: clean
clean:
	@rm -r ./out/
