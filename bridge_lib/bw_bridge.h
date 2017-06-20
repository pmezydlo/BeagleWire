#ifndef _BW_BRIDGE_H_
#define _BW_BRIDGE_H_

#include <fcntl.h>
#include <sys/mman.h>
#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>
#include <errno.h>

#define BW_BRIDGE_MEM_ADR 0x01000000
#define BW_BRIDGE_MEM_SIZE 0x20000

void *virt_addr;
int mem_dev;
uint32_t alloc_mem_size;
void *mem_pointer;

int bw_init();
void bw_close();
uint16_t bw_get_word(uint16_t reg_addr);
void bw_set_word(uint16_t reg_addr, uint16_t word);
void bw_set_fpga_mem(uint16_t reg_addr, const void* source, size_t reg_num);
void bw_get_fpga_mem(uint16_t reg_addr, void* destination, size_t reg_num);

#endif
