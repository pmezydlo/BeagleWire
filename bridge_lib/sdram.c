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
		//set sdram address
		sdram->addr_hi = 0x12;
		sdram->addr_lo = 0x51 + i;

		//set sdram data
		sdram->wr_data = i ^ xor;

		//set wr enable flag
		sdram->wr_enable = 1;

		//waiting for clr busy bit
		while (sdram->busy)
			;

		// clr we enable bit
		sdram->wr_enable = 0;
	}

	printf("reading....\n");
	for (size_t i=0;i<100;i++) {
		//set sdra, address
		sdram->addr_hi = 0x12;
		sdram->addr_lo = 0x51 + i;

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

		const uint16_t data = sdram->rd_data;

		printf("data[%x]=%x%s\n",
			i,
			data,
			data == (i ^ xor) ? "" : " BAD"
		);
 	}

	bridge_close(&br);

	return 0;
}
