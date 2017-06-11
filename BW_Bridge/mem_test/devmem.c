#include <fcntl.h>
#include <sys/mman.h>
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>

int main(int argc, char const *argv[])
{
	const uint32_t mem_address = 0x01000000;
	const uint32_t mem_size = 0x20000;
	uint32_t alloc_mem_size, page_mask, page_size;
	void *mem_pointer, *virt_addr;

	printf ("Test memory \n");

	page_size = sysconf(_SC_PAGESIZE);
	alloc_mem_size = (((mem_size / page_size) + 1) * page_size);
	page_mask = (page_size - 1);

	int mem_dev = open("/dev/mem", O_RDWR | O_SYNC);

	mem_pointer = mmap(NULL,
                   alloc_mem_size,
                   PROT_READ | PROT_WRITE,
                   MAP_SHARED,
                   mem_dev,
                   (mem_address & ~page_mask)
                   ); 
	if(mem_pointer == MAP_FAILED)
	{  
	      perror("Error mmap");
	}

	virt_addr = (mem_pointer + (mem_address & page_mask));

	 int i;
	 unsigned char j;

	//j = *(unsigned char *)(virt_addr);
	
	*(uint16_t *)(virt_addr) = 1;
	
	*(uint16_t *)(virt_addr) = 2;
	//usleep(1000);

	*(uint16_t *)(virt_addr) = 3;
	//usleep(1000);

	*(uint16_t *)(virt_addr) = 0;

	if (munmap(mem_pointer, alloc_mem_size) == -1)
		perror("Error un-mmapping the file");
	
	close(mem_dev);

	return 0;
}
