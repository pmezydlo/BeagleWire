#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/i2c.h>
#include <linux/err.h>

#define DRIVER_NAME "ice40-i2c"

static int ice40_i2c_probe(struct platform_device *pdev)
{

	return 0;
}

static int ice40_i2c_remove(struct platform_device *pdev)
{

	return 0;
}

const struct of_device_id ice40_i2c_of_match[] = {
	{.compatible = "beagle,ice40-i2c", },
	{ }
};
MODULE_DEVICE_TABLE(of, ice40_i2c_of_match);

static struct platform_driver ice40_i2c_driver = {
	.probe = ice40_i2c_probe,
	.remove = ice40_i2c_remove,
	.driver = {
		.name = DRIVER_NAME,
		.owner = THIS_MODULE,
		.of_match_table = of_match_ptr(ice40_i2c_of_match),
	},
};

module_platform_driver(ice40_i2c_driver);

MODULE_LICENSE("GPL v2");  
MODULE_AUTHOR("Patryk Mezydlo, <mezydlo.p@gmail.com>");
MODULE_DESCRIPTION("Driver for I2C controller on the ice40 FPGA");
MODULE_VERSION("1.0");
