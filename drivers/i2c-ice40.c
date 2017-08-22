#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/i2c.h>
#include <linux/err.h>
#include <linux/io.h>

#define DRIVER_NAME "ice40-i2c"

#define ICE40_I2C_SETUP_REG		0x0
#define ICE40_I2C_DATA_TX_REG		0x2
#define ICE40_I2C_DATA_RX_REG		0x4

#define ICE40_I2C_RESET_BIT		BIT(0)
#define ICE40_I2C_ENABLE_BIT		BIT(1)
#define ICE40_I2C_RW_BIT		BIT(2)
#define ICE40_I2C_BUSY_BIT		BIT(3)
#define ICE40_I2C_ACK_ERR_BIT		BIT(4)
#define ICE40_I2C_FAST_MODE_BIT		BIT(5)
#define ICE40_I2C_ADDR(x)		(x << 6)

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

static int ice40_i2c_xfer_one_msg(void *base, struct i2c_msg *msg)
{
	uint16_t setup;
	int xfer_len = 0;

	setup = ioread16(base + ICE40_I2C_SETUP_REG);
	if (msg->addr)
		setup |= ICE40_I2C_ADDR(msg->addr);

	if (msg->flags & I2C_M_RD)
		setup |= ICE40_I2C_RW_BIT;
	else
		setup &= ~ICE40_I2C_RW_BIT;

	while (xfer_len < msg->len) {

		if (!(msg->flags & I2C_M_RD))
			iowrite16(msg->buf[xfer_len],
				base + ICE40_I2C_DATA_TX_REG);

		setup |= ICE40_I2C_ENABLE_BIT;
		iowrite16(setup, base + ICE40_I2C_SETUP_REG);

		while (!(ioread16(base + ICE40_I2C_SETUP_REG)
		       & ICE40_I2C_BUSY_BIT))
			;


		setup &= ~ICE40_I2C_ENABLE_BIT;
		iowrite16(setup, base + ICE40_I2C_SETUP_REG);

		while (ioread16(base + ICE40_I2C_SETUP_REG)
		       & ICE40_I2C_BUSY_BIT)
			;

		if (msg->flags & I2C_M_RD)
			msg->buf[xfer_len] = ioread16(base +
						      ICE40_I2C_DATA_RX_REG);

		xfer_len++;
	}

	return 0;
}

static int ice40_i2c_xfer(struct i2c_adapter *adap, struct i2c_msg msgs[],
			  int num)
{
	struct ice40_i2c *ice40_i2c = i2c_get_adapdata(adap);
	int msg_num;
	int err;

	for (msg_num = 0; msg_num < num; msg_num++) {
		err = ice40_i2c_xfer_one_msg(ice40_i2c->base, &msgs[msg_num]);
		if (err)
			return err;
	}

	return msg_num;
}

static u32 ice40_i2c_functionality(struct i2c_adapter *adap)
{
	return I2C_FUNC_I2C;
}

static const struct i2c_algorithm ice40_i2c_algo = {
	.master_xfer = ice40_i2c_xfer,
	.functionality = ice40_i2c_functionality,
};

static int ice40_i2c_probe(struct platform_device *pdev)
{
	struct device *dev = &pdev->dev;
	struct ice40_i2c *ice40_i2c;
	int err = 0;
	struct resource *res;
	uint16_t setup;

	ice40_i2c = devm_kzalloc(dev, sizeof(*ice40_i2c), GFP_KERNEL);
	if (!ice40_i2c)
		return -ENOMEM;

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	ice40_i2c->base = devm_ioremap_resource(dev, res);
	if (IS_ERR(ice40_i2c->base))
		return PTR_ERR(ice40_i2c->base);

	ice40_i2c->adapter.owner = THIS_MODULE;
	ice40_i2c->adapter.algo = &ice40_i2c_algo;
	ice40_i2c->adapter.dev.parent = dev;
	strlcpy(ice40_i2c->adapter.name, pdev->name,
		sizeof(ice40_i2c->adapter.name));
	i2c_set_adapdata(&ice40_i2c->adapter, ice40_i2c);
	platform_set_drvdata(pdev, ice40_i2c);

	err = i2c_add_adapter(&ice40_i2c->adapter);
	if (err) {
		pr_info("I2C data not set");
		return err;
	}

	setup = ice40_i2c_read(ice40_i2c->base, ICE40_I2C_SETUP_REG);
	setup &= ~ICE40_I2C_RESET_BIT;
	setup |= ICE40_I2C_FAST_MODE_BIT;
	ice40_i2c_write(ice40_i2c->base, ICE40_I2C_SETUP_REG, setup);

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
