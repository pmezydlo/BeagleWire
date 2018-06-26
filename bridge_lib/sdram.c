
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

int main()
{
	struct bridge br;
	int i, j;
	void *ptr;


	if (bridge_init(&br, BW_BRIDGE_MEM_ADR, BW_BRIDGE_MEM_SIZE) < 0)
		return 1;

	ptr = br.virt_addr;

	// clr reset
	*(uint16_t *)(ptr) |= 1;

	for (i=0;i<100;i++) {
		//set sdram address
		*(uint16_t *)(ptr + 2) = 0x51+i;
		*(uint16_t *)(ptr + 4) = 0x12;

		//set sdram data
		*(uint16_t *)(ptr + 6) = i;

		//set wr enable flag
		*(uint16_t *)(ptr) |= 8;

		//waiting for clr busy bit
		while ((*(uint16_t *)(ptr) & 2));

		// clr we enable bit
		*(uint16_t *)(ptr) &= ~8;
	}

	for (i=0;i<100;i++) {
		//set sdra, address
                *(uint16_t *)(ptr + 2) = 0x51+i;
                *(uint16_t *)(ptr + 4) = 0x12;

		//set rd enable flag
		*(uint16_t *)(ptr) |= 4;

		// waiting for clr busy bit
                while ((*(uint16_t *)(ptr) & 2));

		// waiting for clr rd ready bit
	       	while ((*(uint16_t *)(ptr) & 16));

		// clr rd enable bit
		*(uint16_t *)(ptr) &= ~4;

		printf("data: %x  %x\n", *(uint16_t *)(ptr + 8), i);
 	}
	bridge_close(&br);

	return 0;
}
