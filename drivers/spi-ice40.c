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
#include <asm/io.h>
#include <linux/of.h>
#include <linux/ioport.h>
#include <linux/slab.h>
#include <linux/spi/spi.h>
#include <linux/platform_device.h>
#include <linux/err.h>

#define DRIVER_NAME "ice40-spi"

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

	return 0;
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
