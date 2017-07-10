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

#define ICE40_SPI_SETUP_REG	           0x0
#define ICE40_SPI_STATUS_REG	           0x2
#define ICE40_SPI_TX_REG                   0x4
#define ICE40_SPI_RX_REG	           0x6
#define ICE40_SPI_CS_REG                   0x8

#define ICE40_SPI_SETUP_REG_RESET_BIT      BIT(0)
#define ICE40_SPI_SETUP_REG_START_BIT      BIT(1)
#define ICE40_SPI_STATUS_REG_BUSY_BIT      BIT(0)
#define ICE40_SPI_STATUS_REG_NEW_DATA_BIT  BIT(1)

struct ice40_spi {
	struct spi_master *master;
	void __iomem      *base;

};

inline u16 ice40_spi_read_reg(void __iomem *base, u32 idx)
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
	struct ice40_spi *ice40_spi;
	unsigned int count;
	u8 *rx;
	const u8 *tx;
	u16 setup_reg_cache;

	ice40_spi = spi_master_get_devdata(spi->master);
	count = t->len;
	rx = t->rx_buf;
	tx = t->tx_buf;
	/*set cs line to 0*/
	ice40_spi_write_reg(ice40_spi->base, ICE40_SPI_CS_REG, 0);
	udelay(100);
	do {
		count -= 1;

		if (tx != NULL)
			ice40_spi_write_reg(ice40_spi->base, ICE40_SPI_TX_REG,
					    *tx++);

		/*delay between next byte*/
		udelay(20);

		/*set start flag*/
		setup_reg_cache = ice40_spi_read_reg(ice40_spi->base,
						     ICE40_SPI_SETUP_REG);
		setup_reg_cache |= ICE40_SPI_SETUP_REG_START_BIT;
		ice40_spi_write_reg(ice40_spi->base, ICE40_SPI_SETUP_REG,
				    setup_reg_cache);

		/*wait for end of one byte transfer*/
		if (ice40_spi_wait_for_bit(ice40_spi->base
					   + ICE40_SPI_STATUS_REG,
			ICE40_SPI_STATUS_REG_NEW_DATA_BIT) < 0) {
			pr_err("Timed out");
			goto out;
		}

		if (rx != NULL)
			*rx++ = (u8)ice40_spi_read_reg(ice40_spi->base,
						       ICE40_SPI_RX_REG);

		/*clear start flag*/
		setup_reg_cache = ice40_spi_read_reg(ice40_spi->base,
						     ICE40_SPI_SETUP_REG);
		setup_reg_cache &= ~ICE40_SPI_SETUP_REG_START_BIT;
		ice40_spi_write_reg(ice40_spi->base, ICE40_SPI_SETUP_REG,
				    setup_reg_cache);

	} while (count);
	udelay(100);

out:
	/*set cs line to 1*/
	ice40_spi_write_reg(ice40_spi->base, ICE40_SPI_CS_REG, 1);
	return 0;
}

static int ice40_spi_setup(struct spi_device *spi)
{
	struct ice40_spi *ice40_spi;
	u16 setup_reg_cache;

	ice40_spi = spi_master_get_devdata(spi->master);

	/*set cs line */
	ice40_spi_write_reg(ice40_spi->base, ICE40_SPI_CS_REG, 1);

	/*clr reset bit*/
	setup_reg_cache = ice40_spi_read_reg(ice40_spi->base,
					     ICE40_SPI_SETUP_REG);
	setup_reg_cache &= ~ICE40_SPI_SETUP_REG_RESET_BIT;
	ice40_spi_write_reg(ice40_spi->base, ICE40_SPI_SETUP_REG,
			    setup_reg_cache);

	pr_info("spi setup");
	return 0;
}

static int ice40_spi_probe(struct platform_device *pdev)
{
	struct spi_master *master;
	struct ice40_spi  *ice40_spi;
	struct resource *res;
	int status;

	pr_info("ice40 spi probe");

	master = spi_alloc_master(&pdev->dev, sizeof(struct ice40_spi));
	if (!master)
		return -ENOMEM;

	master->bus_num = pdev->id;
	master->num_chipselect = 1;
	master->mode_bits = SPI_CS_HIGH;
	master->setup = ice40_spi_setup;
	master->transfer_one = ice40_spi_transfer_one;
	master->dev.of_node = pdev->dev.of_node;
	master->max_speed_hz = 10000000;
	master->bits_per_word_mask = SPI_BPW_RANGE_MASK(8, 8);

	platform_set_drvdata(pdev, master);
	ice40_spi = spi_master_get_devdata(master);

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	ice40_spi->base = devm_ioremap_resource(&pdev->dev, res);

	if (IS_ERR(ice40_spi->base)) {
		status = PTR_ERR(ice40_spi->base);
		goto exit;
	}

	status = devm_spi_register_master(&pdev->dev, master);
	if (status < 0) {
		pr_info("SPI master registration failed");
		goto  exit;
	}

	return status;
exit:
	spi_master_put(master);
	return status;
}

static int ice40_spi_remove(struct platform_device *pdev)
{
	struct spi_master *master = platform_get_drvdata(pdev);
	struct ice40_spi  *ice40_spi = spi_master_get_devdata(master);
	u16 setup_reg_cache;

	/*set reset bit - stop spi controller*/
	setup_reg_cache = ice40_spi_read_reg(ice40_spi->base,
					     ICE40_SPI_SETUP_REG);
	setup_reg_cache |= ICE40_SPI_SETUP_REG_RESET_BIT;
	ice40_spi_write_reg(ice40_spi->base, ICE40_SPI_SETUP_REG,
			    setup_reg_cache);

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
