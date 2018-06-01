#include <linux/of.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/fpga/fpga-mgr.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Michael Welling");
MODULE_DESCRIPTION("FPGA loader module");

static char *path = "ice40-firmware.bin";
module_param(path, charp, S_IRUGO);
MODULE_PARM_DESC(path, "Bitstream to load");

static int __init fpga_load_init(void)
{
	struct device_node *mgr_node;
	struct fpga_image_info fpga_info;
	struct fpga_manager *mgr;
	int ret;

	pr_info("Starting FPGA loader\n");

	mgr_node = of_find_node_by_name(NULL, "fpga");
	if (!mgr_node) {
		pr_info("Cannot find manager node\n");
		return -ENODEV;
	}

	mgr = of_fpga_mgr_get(mgr_node);
	fpga_info.flags = 0;

	if (IS_ERR(mgr)) {
		pr_info("Cannot get manager\n");
		return -ENODEV;
	}

	ret = fpga_mgr_firmware_load(mgr, &fpga_info, path);
	if (ret) {
		pr_info("Cannot load FPGA firmware\n");
		return -ENODEV;
	}

	fpga_mgr_put(mgr);

	return 0;
}

static void __exit fpga_load_cleanup(void)
{
	pr_info("Stopping FPGA loader\n");
}

module_init(fpga_load_init);
module_exit(fpga_load_cleanup);
