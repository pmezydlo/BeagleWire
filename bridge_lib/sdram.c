#include <stdio.h>
#include <stdlib.h>

#include <fcntl.h>
#include <sys/mman.h>
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>

#include "bw_bridge.h"

typedef struct __attribute__((__packed__))
{
	volatile uint8_t reset:1; // offset 0
	volatile uint8_t busy:1;
	volatile uint8_t rd_enable:1;
	volatile uint8_t wr_enable:1;
	volatile uint8_t rd_busy:1;
	uint8_t unused;

	volatile uint16_t addr_lo; // 16 bits, offset 1
	volatile uint16_t addr_hi; //  9 bits, offset 1
	volatile uint16_t wr_data; //  8 bits, offset 3
	volatile uint16_t rd_data; //  8 bits, offset 4
} bw_sdram_t;


void
sdram_write(
	bw_sdram_t * const sdram,
	uint32_t addr,
	uint8_t value
) {
	//set sdram address
	sdram->addr_hi = (addr >> 16) & 0x01FF;
	sdram->addr_lo = (addr >>  0) & 0xFFFF;

	//set sdram data
	sdram->wr_data = value;

	//set wr enable flag
	sdram->wr_enable = 1;

	//waiting for clr busy bit
	while (sdram->busy)
		;

	// clr we enable bit
	sdram->wr_enable = 0;
}

uint8_t
sdram_read(
	bw_sdram_t * const sdram,
	uint32_t addr
)
{
	//set sdra, address
	sdram->addr_hi = (addr >> 16) & 0x01FF;
	sdram->addr_lo = (addr >>  0) & 0xFFFF;

	//set rd enable flag
	sdram->rd_enable = 1;

	// waiting for clr busy bit
	while (sdram->busy)
		;

	// waiting for clr rd ready bit
	while (sdram->rd_busy)
		;

	// clr rd enable bit
	sdram->rd_enable = 0;

	return sdram->rd_data;
}


int main(int argc, char **argv)
{
	uint16_t xor = argc > 1 ? strtol(argv[1], NULL, 0) : 0;

	struct bridge br;
	if (bridge_init(&br, BW_BRIDGE_MEM_ADR, BW_BRIDGE_MEM_SIZE) < 0)
	{
		perror("mmap");
		return 1;
	}

	bw_sdram_t * const sdram = br.virt_addr;
	printf("sdram=%p\n", sdram);
	printf("addr=%p %p\n", &sdram->addr_lo, &sdram->addr_hi);
	printf("rd_data=%p\n", &sdram->rd_data);


	// clr reset
	sdram->reset = 1;

	printf("writing....\n");
	for (size_t i=0;i<100;i++) {
		sdram_write(sdram, 0x120051 + i, i ^ xor);
	}

	printf("reading....\n");
	for (size_t i=0;i<100;i++) {
		for(int j = 0 ; j < 4 ; j++)
		{
			uint8_t data = sdram_read(sdram, 0x120051 + i);
			if (data == (i ^ xor))
				break;

			printf("try %d data[%x]=%x%s\n",
				j,
				i,
				data,
				data == (i ^ xor) ? "" : " BAD"
			);
		}
 	}

	bridge_close(&br);

	return 0;
}
