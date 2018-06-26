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
	volatile uint16_t reset:1; // offset 0
	volatile uint16_t busy:1;
	volatile uint16_t rd_enable:1;
	volatile uint16_t wr_enable:1;
	volatile uint16_t rd_busy:1;

	volatile uint32_t addr; // 25 bits, offset 1
	volatile uint16_t wr_data; // 8 bits, offset 3
	volatile uint16_t rd_data; // 8 bits, offset 4
} bw_sdram_t;

int main()
{
	struct bridge br;
	if (bridge_init(&br, BW_BRIDGE_MEM_ADR, BW_BRIDGE_MEM_SIZE) < 0)
		return 1;

	bw_sdram_t * const sdram = br.virt_addr;

	// clr reset
	sdram->reset = 1;

	for (int i=0;i<100;i++) {
		//set sdram address
		sdram->addr = 0x120051 + i;

		//set sdram data
		sdram->wr_data = i;

		//set wr enable flag
		sdram->wr_enable = 1;

		//waiting for clr busy bit
		while (sdram->busy)
			;

		// clr we enable bit
		sdram->wr_enable = 0;
	}

	for (int i=0;i<100;i++) {
		//set sdra, address
		sdram->addr = 0x120051 + i;

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

		printf("data[%x]=%x\n", i, sdram->rd_data);
 	}

	bridge_close(&br);

	return 0;
}
