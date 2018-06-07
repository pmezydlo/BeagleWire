
#include <stdio.h>
#include <stdlib.h>

#include <fcntl.h>
#include <sys/mman.h>
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>

#define BW_BRIDGE_MEM_ADR 0x01000000
#define BW_BRIDGE_MEM_SIZE 0x20000

struct bridge {
	void		*virt_addr;
	int		mem_dev;
	uint32_t	alloc_mem_size;
	void		*mem_pointer;
};

int bridge_init(struct bridge *br, uint32_t mem_address, uint32_t mem_size) {
	uint32_t page_mask;
	uint32_t page_size;

	page_size = sysconf(_SC_PAGESIZE);
	br->alloc_mem_size = (((mem_size / page_size) + 1) * page_size);
	page_mask = (page_size - 1);

	br->mem_dev = open("/dev/mem", O_RDWR | O_SYNC);
	if (br->mem_dev < 0)
		return -EPERM;

	br->mem_pointer = mmap(NULL,
		               br->alloc_mem_size,
			       PROT_READ | PROT_WRITE,
                               MAP_SHARED,
                               br->mem_dev,
                               (mem_address & ~page_mask));

	if(br->mem_pointer == MAP_FAILED) {
	      return -ENOMEM;
	}

	br->virt_addr = (br->mem_pointer + (mem_address & page_mask));

	return 0;
}

void bridge_close(struct bridge *br) {
	if (munmap(br->mem_pointer, br->alloc_mem_size) == -1)
		perror("Error un-mmapping the file");

	close(br->mem_dev);
}

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
