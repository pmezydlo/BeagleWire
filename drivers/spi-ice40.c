/*
 * Driver for memory mapped SPI ip core on ice40 FPGA
 *
 * Copyright (C) 2017 Patryk Mezydlo <mezydlo.p@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
#define ICE40_SPI_TX_REG_32                0x4
#define ICE40_SPI_TX_REG_16		   0x6
#define ICE40_SPI_RX_REG_32	           0x8
#define ICE40_SPI_RX_REG_16                0xA

#define ICE40_SPI_SETUP_REG_RESET_BIT      BIT(0)
#define ICE40_SPI_SETUP_REG_START_BIT      BIT(1)
#define ICE40_SPI_SETUP_REG_CPOL_BIT       BIT(2)
#define ICE40_SPI_SETUP_REG_CPHA_BIT       BIT(3)
#define ICE40_SPI_SETUP_REG_CS_BIT         BIT(4)
#define ICE40_SPI_SETUP_REG_BIT_PER_WORD   (0x1F << 5)
#define ICE40_SPI_SETUP_REG_CLK_DIV        (0x3F << 10)

#define ICE40_SPI_STATUS_REG_BUSY_BIT      BIT(0)
#define ICE40_SPI_STATUS_REG_NEW_DATA_BIT  BIT(1)

struct ice40_spi {
	struct spi_master *master;
	void __iomem      *base;

};

inline u16 ice40_spi_read(void __iomem *base, u32 idx)
{
	return ioread16(base + idx);
}

inline void ice40_spi_write(void __iomem *base,
		u32 idx, u16 val)
{
	iowrite16(val, base + idx);
}

int ice40_spi_wait_for_bit(void __iomem *reg, u16 bit)
{
	unsigned long timeout;

	timeout = jiffies + msecs_to_jiffies(1000);
	while (!(ioread16(reg) & bit)) {
		pr_info("tick");
		if (time_after(jiffies, timeout))
			return -ETIMEDOUT;
		else
			return 0;

		cpu_relax();
	}
	return 0;
}

static void ice40_spi_send_start(void __iomem *base)
{
	u16 setup_reg_cache;

	/*set start flag*/
	setup_reg_cache = ice40_spi_read(base, ICE40_SPI_SETUP_REG);
	setup_reg_cache |= ICE40_SPI_SETUP_REG_START_BIT;
	ice40_spi_write(base, ICE40_SPI_SETUP_REG, setup_reg_cache);

	/*clear start flag*/
	setup_reg_cache = ice40_spi_read(base, ICE40_SPI_SETUP_REG);
	setup_reg_cache &= ~ICE40_SPI_SETUP_REG_START_BIT;
	ice40_spi_write(base, ICE40_SPI_SETUP_REG, setup_reg_cache);
}

static int ice40_spi_bytes_per_word(unsigned int word_len_bits)
{
	if (word_len_bits <= 8)
		return 1;
	else if (word_len_bits <= 16)
		return 2;
	else
		return 4;
}

static int ice40_spi_pio_transfer(struct spi_master *master,
				  struct spi_device *spi,
				  struct spi_transfer *t)
{
	struct ice40_spi *ice40_spi;

	unsigned int count;
	unsigned int c;
	u16 setup_reg_cache;
	u8 word_len;

	ice40_spi = spi_master_get_devdata(spi->master);
	count     = t->len;
	c         = t->len;
	word_len  = t->bits_per_word;

	/*set cs line to 0*/
	setup_reg_cache = ice40_spi_read(ice40_spi->base,
					     ICE40_SPI_SETUP_REG);
	setup_reg_cache &= ~ICE40_SPI_SETUP_REG_CS_BIT;
	ice40_spi_write(ice40_spi->base, ICE40_SPI_SETUP_REG,
			    setup_reg_cache);

	udelay(100);

	switch (ice40_spi_bytes_per_word(word_len)) {
	case 1: {
		u8 *rx;
		const u8 *tx;

		rx = t->rx_buf;
		tx = t->tx_buf;
		do {
			c -= 1;

			if (tx != NULL)
				ice40_spi_write(ice40_spi->base,
						ICE40_SPI_TX_REG_16, *tx++);
			/*send start sequence*/
			ice40_spi_send_start(ice40_spi->base);

			/*wait for end of one byte transfer*/
			if (ice40_spi_wait_for_bit(ice40_spi->base
						   + ICE40_SPI_STATUS_REG,
				ICE40_SPI_STATUS_REG_NEW_DATA_BIT) < 0) {
				pr_err("Timed out");
				goto out;
			}

			if (rx != NULL)
				*rx++ = (u8)ice40_spi_read(ice40_spi->base,
						       ICE40_SPI_TX_REG_16);
		} while (c);
	} break;

	case 2: {
		u16 *rx;
		const u16 *tx;

		rx = t->rx_buf;
		tx = t->tx_buf;
		do {
			c -= 2;

			if (tx != NULL)
				ice40_spi_write(ice40_spi->base,
						ICE40_SPI_TX_REG_16, *tx++);
			/*sned start sequence*/
			ice40_spi_send_start(ice40_spi->base);

			/*wait for end of one byte transfer*/
			if (ice40_spi_wait_for_bit(ice40_spi->base
						   + ICE40_SPI_STATUS_REG,
				ICE40_SPI_STATUS_REG_NEW_DATA_BIT) < 0) {
				pr_err("Timed out");
				goto out;
			}

			if (rx != NULL)
				*rx++ = ice40_spi_read(ice40_spi->base,
						       ICE40_SPI_TX_REG_16);
		} while (c >= 2);

	} break;

	case 4: {
		u16 *rx;
		const u16 *tx;

		rx = t->rx_buf;
		tx = t->tx_buf;
		do {
			c -= 4;

			if (tx != NULL) {
				ice40_spi_write(ice40_spi->base,
						ICE40_SPI_TX_REG_32, *tx++);
				ice40_spi_write(ice40_spi->base,
						ICE40_SPI_TX_REG_16, *tx++);
			}
			/*sned start sequence*/
			ice40_spi_send_start(ice40_spi->base);

			/*wait for end of one byte transfer*/
			if (ice40_spi_wait_for_bit(ice40_spi->base
						   + ICE40_SPI_STATUS_REG,
				ICE40_SPI_STATUS_REG_NEW_DATA_BIT) < 0) {
				pr_err("Timed out");
				goto out;
			}

			if (rx != NULL) {
				*rx++ = ice40_spi_read(ice40_spi->base,
						       ICE40_SPI_TX_REG_32);
				*rx++ = ice40_spi_read(ice40_spi->base,
						       ICE40_SPI_TX_REG_16);
			}
		} while (c >= 4);
	} break;
	}
	udelay(100);
out:
	/*set cs line to 1*/
	setup_reg_cache = ice40_spi_read(ice40_spi->base,
					 ICE40_SPI_SETUP_REG);
	setup_reg_cache |= ICE40_SPI_SETUP_REG_CS_BIT;
	ice40_spi_write(ice40_spi->base, ICE40_SPI_SETUP_REG,
			setup_reg_cache);

	return count - c;
}


static int ice40_spi_transfer_one(struct spi_master *master,
				  struct spi_device *spi,
				  struct spi_transfer *t)
{
	struct ice40_spi *ice40_spi;
	int ret;
	u8 word_len;
	u16 setup_reg_cache;

	ice40_spi = spi_master_get_devdata(spi->master);
	word_len = t->bits_per_word;

	setup_reg_cache = ice40_spi_read(ice40_spi->base,
					     ICE40_SPI_SETUP_REG);
	/* set cpol and cpha bit */
	if (spi->mode & SPI_CPOL)
		setup_reg_cache |= ICE40_SPI_SETUP_REG_CPOL_BIT;
	else
		setup_reg_cache &= ~ICE40_SPI_SETUP_REG_CPOL_BIT;

	if (spi->mode & SPI_CPHA)
		setup_reg_cache |= ICE40_SPI_SETUP_REG_CPHA_BIT;
	else
		setup_reg_cache &= ~ICE40_SPI_SETUP_REG_CPHA_BIT;

	/* wordlength */
	setup_reg_cache &= ~ICE40_SPI_SETUP_REG_BIT_PER_WORD;
	setup_reg_cache |= (word_len-1) << 5;

	ice40_spi_write(ice40_spi->base, ICE40_SPI_SETUP_REG,
			    setup_reg_cache);

	pr_info("setup transfer: 0x%x", ice40_spi_read(ice40_spi->base,
						  ICE40_SPI_SETUP_REG));

	ret = ice40_spi_pio_transfer(master, spi, t);

	return 0;
}

static int ice40_spi_setup(struct spi_device *spi)
{
	struct ice40_spi *ice40_spi;
	u16 setup_reg_cache;
	u8 clk_div = 4;

	ice40_spi = spi_master_get_devdata(spi->master);


	setup_reg_cache = ice40_spi_read(ice40_spi->base,
					     ICE40_SPI_SETUP_REG);

	/* set cs line */
	setup_reg_cache |= ICE40_SPI_SETUP_REG_CS_BIT;

	/* clr reset bit */
	setup_reg_cache &= ~ICE40_SPI_SETUP_REG_RESET_BIT;

	/* set clk div */
	setup_reg_cache &= ~ICE40_SPI_SETUP_REG_CLK_DIV;
	setup_reg_cache |= clk_div << 10;


	ice40_spi_write(ice40_spi->base, ICE40_SPI_SETUP_REG,
			    setup_reg_cache);

	pr_info("setup: 0x%x", ice40_spi_read(ice40_spi->base,
						  ICE40_SPI_SETUP_REG));

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
	master->mode_bits = SPI_CPHA | SPI_CPOL | SPI_CS_HIGH;
	master->setup = ice40_spi_setup;
	master->transfer_one = ice40_spi_transfer_one;
	master->dev.of_node = pdev->dev.of_node;
	master->max_speed_hz = 10000000;
	master->bits_per_word_mask = SPI_BPW_RANGE_MASK(2, 32);

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
		pr_err("SPI master registration failed");
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
	setup_reg_cache = ice40_spi_read(ice40_spi->base,
					     ICE40_SPI_SETUP_REG);
	setup_reg_cache |= ICE40_SPI_SETUP_REG_RESET_BIT;
	ice40_spi_write(ice40_spi->base, ICE40_SPI_SETUP_REG,
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
