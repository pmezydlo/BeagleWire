#include <stdio.h>
#include "../../../bridge_lib/bw_bridge.h"

int main()
{
	if (bw_init() < 0)
		return 1;

	int i;
	for (i=0; i<=4; i++) {
		printf("leds write %d\n", 1<<i);
		bw_set_word(0, 1<<i);
		usleep(500000);
	}

	bw_close();

	return 0;
}
