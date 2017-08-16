#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/i2c.h>
#include <linux/err.h>
#include <linux/io.h>

#define DRIVER_NAME "ice40-i2c"

struct ice40_i2c {
	struct i2c_adapter adapter;
	void *base;
	unsigned int size;
};

inline u16 ice40_i2c_read(void __iomem *base, u32 idx)
{
	return ioread16(base + idx);
}

inline void ice40_i2c_write(void __iomem *base,
		u32 idx, u16 val)
{
	iowrite16(val, base + idx);
}



static int ice40_i2c_probe(struct platform_device *pdev)
{
	struct ice40_i2c *ice40_i2c;
	struct i2c_adapter *adapter;
	int err;
	struct resource *res;

	ice40_i2c = devm_kzalloc(&pdev->dev, sizeof(*ice40_i2c), GFP_KERNEL);

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	ice40_i2c->base = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(ice40_i2c->base))
		return PTR_ERR(ice40_i2c->base);

	platform_set_drvdata(pdev, ice40_i2c);
	adapter = &ice40_i2c->adapter;
	strlcpy(adapter->name, "iCE40", sizeof(adapter->name));
	adapter->owner = THIS_MODULE;
	adapter->algo = &ice40_i2c_algo;
	adapter->dev.of_node = pdev->dev.of_node;
	i2c_set_adapdata(adapter, ice40_i2c);
	err = i2c_add_adapter(adapter);
	if (!(err)) {
		pr_info("I2C data not set");
		return err;
	}

	pr_info("ice40 i2c probe called");

	return 0;
}

static int ice40_i2c_remove(struct platform_device *pdev)
{
	struct ice40_i2c *ice40_i2c = platform_get_drvdata(pdev);

	i2c_del_adapter(&ice40_i2c->adapter);
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
