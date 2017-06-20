#include <stdio.h>
#include "bw_bridge.h"

int main()
{
	if (bw_init() < 0)
		return 1;


	bw_close();

	return 0;
}
