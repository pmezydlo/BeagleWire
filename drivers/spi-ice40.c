/*
 * ice40 SPI driver
 *
 * Copyright (c) 2017 Patryk Mezydlo <mezydlo.p@gmail.com
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/io.h>
#include <linux/of.h>
#include <linux/ioport.h>
#include <linux/slab.h>
#include <linux/spi/spi.h>
#include <linux/platform_device.h>
#include <linux/err.h>
#include <linux/delay.h>

#define DRIVER_NAME "ice40-spi"

struct ice40_spi {
	struct spi_master *master;
	void __iomem      *base;

};


inline unsigned int ice40_spi_read_reg(void __iomem *base, u32 idx)
{
	return ioread16(base + idx);
}

inline void ice40_spi_write_reg(void __iomem *base,
		u32 idx, u16 val)
{
	iowrite16(val, base + idx);
}

int ice40_spi_wait_for_bit(void __iomem *reg, u16 bit)
{
	unsigned long timeout;

	timeout = jiffies + msecs_to_jiffies(1000);
	while (!(ioread16(reg) & bit)) {
		if (time_after(jiffies, timeout))
			return -ETIMEDOUT;
		else
			return 0;

		cpu_relax();
	}
	return 0;
}

static int ice40_spi_transfer_one(struct spi_master *master,
				  struct spi_device *spi,
				  struct spi_transfer *t)
{

	return 0;
}

static int ice40_spi_setup(struct spi_device *spi)
{

	return 0;
}

static int ice40_spi_probe(struct platform_device *pdev)
{
	struct spi_master *master;
	struct ice40_spi  *ice40_spi;
	struct resource *res;
	int err;
	int i = 0;

	pr_info("ice40 spi probe");

	master = spi_alloc_master(&pdev->dev, sizeof(struct ice40_spi));

	if (!master)
		return -ENODEV;

	master->bus_num = pdev->id;
	master->num_chipselect = 1;
	master->mode_bits = SPI_CS_HIGH | SPI_CPOL | SPI_CPHA;
	//master->max_speed_hz =
	master->setup = ice40_spi_setup;
	master->transfer_one = ice40_spi_transfer_one;
	master->dev.of_node = pdev->dev.of_node;

	platform_set_drvdata(pdev, master);
	ice40_spi = spi_master_get_devdata(master);

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	ice40_spi->base = devm_ioremap_resource(&pdev->dev, res);

	if (IS_ERR(ice40_spi->base)) {
		err = PTR_ERR(ice40_spi->base);
		goto exit;
	}

	for (i = 0; i <= 4; i++) {
		pr_info("leds write: %d", 1 << i);
		*(u16 *)(ice40_spi->base) = 1 << i;
		msleep(1000);
	}


	return 0;
exit:
	spi_master_put(master);
	return err;
}

static int ice40_spi_remove(struct platform_device *pdev)
{

	return 0;
}

const struct of_device_id ice40_spi_of_match[] = {
	{.compatible = "beagle,ice40-spi", },
	{ }
};
MODULE_DEVICE_TABLE(of, ice40_spi_of_match);

static struct platform_driver ice40_spi_driver = {
	.probe	= ice40_spi_probe,
	.remove = ice40_spi_remove,
	.driver = {
		.name =	DRIVER_NAME,
		.of_match_table = of_match_ptr(ice40_spi_of_match),
	},
};

module_platform_driver(ice40_spi_driver);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Patryk Mezydlo, <mezydlo.p@gmail.com>");
MODULE_DESCRIPTION("Driver for SPI controller on the ice40 FPGA");
MODULE_VERSION("1.0");
