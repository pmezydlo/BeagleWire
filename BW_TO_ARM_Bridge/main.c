#include <stdio.h>
#include "BW_bridge.h"

int main()
{
	void *mem = bw_bridge_init();

	printf("BeagleWire");
	return 0;
}
