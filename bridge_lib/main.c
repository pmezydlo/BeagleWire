#include <stdio.h>
#include "bw_bridge.h"

int main()
{
	struct bridge br;

	if (bridge_init(&br, BW_BRIDGE_MEM_ADR, BW_BRIDGE_MEM_SIZE) < 0)
		return 1;

	void *ptr = br.virt_addr;

	while (1)
		*(uint16_t *)(ptr) = *(uint16_t *)(ptr)>>4;



	bridge_close(&br);

	return 0;
}
