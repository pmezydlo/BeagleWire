#include <linux/platform_device.h>
#include <linux/serial.h>
#include <linux/console.h>
#include <linux/module.h>

static int __init ice40_uart_init(void)
{

	return 0;
}

static void __exit ice40_uart_exit(void)
{


}

module_init(ice40_uart_init);
module_exit(ice40_uart_exit);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Patryk Mezydlo, <mezydlo.p@gmail.com>");
MODULE_DESCRIPTION("Driver for UART controller on the ice40 FPGA");
MODULE_VERSION("1.0");
