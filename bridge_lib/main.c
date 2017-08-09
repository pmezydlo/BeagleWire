#include <stdio.h>
#include "bw_bridge.h"

#define BW_BRIDGE_MEM_ADR 0x01000000
#define BW_BRIDGE_MEM_SIZE 0x20000

int main()
{
	struct bridge br;

	if (bridge_init(&br, BW_BRIDGE_MEM_ADR, BW_BRIDGE_MEM_SIZE) < 0)
		return 1;

	char tab[] = "HELLO WORD";
	set_fpga_mem(&br, 0, &tab[0], sizeof(tab));

	bridge_close(&br);

	return 0;
}
