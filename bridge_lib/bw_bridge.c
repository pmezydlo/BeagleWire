#include "bw_bridge.h"

int bw_init() {
	uint32_t mem_address = BW_BRIDGE_MEM_ADR;
	uint32_t mem_size = BW_BRIDGE_MEM_SIZE;
	uint32_t page_mask, page_size;

	page_size = sysconf(_SC_PAGESIZE);
	alloc_mem_size = (((mem_size / page_size) + 1) * page_size);
	page_mask = (page_size - 1);

	mem_dev = open("/dev/mem", O_RDWR | O_SYNC);
	if (mem_dev < 0)
		return -EPERM;

	mem_pointer = mmap(NULL,
                   alloc_mem_size,
                   PROT_READ | PROT_WRITE,
                   MAP_SHARED,
                   mem_dev,
                   (mem_address & ~page_mask)
                   );

	if(mem_pointer == MAP_FAILED) {
	      return -ENOMEM;
	}

	virt_addr = (mem_pointer + (mem_address & page_mask));

	return 0;
}

void bw_close() {
	if (munmap(mem_pointer, alloc_mem_size) == -1)
		perror("Error un-mmapping the file");

	close(mem_dev);
}

uint16_t bw_get_word(uint16_t reg_addr) {
	return *(uint16_t *)(virt_addr + reg_addr);
}

void bw_set_word(uint16_t reg_addr, uint16_t word) {
	*(uint16_t *)(virt_addr + reg_addr) = word;
}

void bw_set_fpga_mem(uint16_t reg_addr, const void* source, size_t reg_num) {
	unsigned int c;
	uint16_t *usrc = (uint16_t *)source;
	for (c = 0; c < reg_num; c++)
		*(uint16_t *)(virt_addr + reg_addr + c*2) = usrc[c];
}

void bw_get_fpga_mem(uint16_t reg_addr, void* destination, size_t reg_num) {
	unsigned int c;
	uint16_t *udst = (uint16_t *)destination;
	for (c = 0; c < reg_num; c++)
		udst[c] = *(uint16_t *)(virt_addr + reg_addr + c*2);
}
