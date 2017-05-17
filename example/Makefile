outdir=_out/
src=

synthesize: $(outdir)counter.bin

$(outdir)counter.bin: counter.v counter.pcf $(src)
	mkdir -p $(outdir)
	yosys -q -p "synth_ice40 -blif $(outdir)counter.blif" counter.v $(src)
	arachne-pnr -d 8k -p ../beaglewire_pinmap.pcf $(outdir)counter.blif -o $(outdir)counter.txt
	icepack $(outdir)counter.txt $(outdir)counter.bin

.PHONY: synthesize
