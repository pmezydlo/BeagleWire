#include <stdio.h>
#include "bw_bridge.h"

#define BW_BRIDGE_MEM_ADR 0x01000000
#define BW_BRIDGE_MEM_SIZE 0x20000

int main()
{
	struct bridge br;
	int i;
	void *ptr;
	char text[] = {0x0, 0x0};
	char rd_text[11];

	if (bridge_init(&br, BW_BRIDGE_MEM_ADR, BW_BRIDGE_MEM_SIZE) < 0)
		return 1;

	ptr = br.virt_addr;

	/* clr reset (enable controler)*/
	*(uint16_t *)(ptr) &= ~1;
	*(uint16_t *)(ptr) &= ~4;
	*(uint16_t *)(ptr) |= (0x50 << 6);
	*(uint16_t *)(ptr) |= (1<<5);
	*(uint16_t *)(ptr) |= 2;

	for (i=0;i<sizeof(text);i++) {

		*(uint16_t *)(ptr + 2) = text[i];

	// set write mode

	// set read mode
	*(uint16_t *)(ptr) |= 4;

	// set enable bit
		//wait for start
		while (!(*(uint16_t *)(ptr) & (1 << 3)));


	// clr enable bit
	*(uint16_t *)(ptr) &= ~2;

		// wait for end
		while (*(uint16_t *)(ptr) & (1 << 3));
	}

	*(uint16_t *)(ptr) |= 4;

	for (int i=0;i<10;i++) {

	*(uint16_t *)(ptr) &= ~2;

	while (!(*(uint16_t *)(ptr) & (1 << 3)));

	// clr enable bit
	*(uint16_t *)(ptr) &= ~2;

	// wait for busy
	while (*(uint16_t *)(ptr) & (1 << 3));
	rd_text[i] = (*(uint16_t *)(ptr) >> 8);
	}

	for (i=0;i<sizeof(rd_text);i++)
		printf("%c", rd_text[i]);


	bridge_close(&br);

	return 0;
}
