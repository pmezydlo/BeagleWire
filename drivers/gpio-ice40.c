/*
 * Driver for memory mapped GPIO controller on ice40 FPGA
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

#include <linux/io.h>
#include <linux/module.h>
#include <linux/of_gpio.h>
#include <linux/platform_device.h>

#define DRIVER_NAME                   "ice40-gpio"

#define ICE40_GPIO_MAX_NGPIO          64

#define ICE40_GPIO_DIR_47_32          0x0
#define ICE40_GPIO_DIR_31_15          0x2
#define ICE40_GPIO_DIR_15_0           0x4

#define ICE40_GPIO_DATA_47_32         0x8
#define ICE40_GPIO_DATA_31_16         0x10
#define ICE40_GPIO_DATA_15_0          0x12

struct ice40_gpio_chip {
	struct of_mm_gpio_chip mmchip;
};

inline u16 ice40_gpio_read(void __iomem *base, u32 idx)
{
	return ioread16(base + idx);
}

inline void ice40_gpio_write(void __iomem *base,
		u32 idx, u16 val)
{
	iowrite16(val, base + idx);
}

static int ice40_gpio_get(struct gpio_chip *gc, unsigned int offset)
{
	pr_info("ice40_gpio: get");

	pr_info("offset:0x%x", offset);

	return 0;
}

static void ice40_gpio_set(struct gpio_chip *gc, unsigned int offset, int value)
{
	struct of_mm_gpio_chip *mm_gc;
	struct ice40_gpio_chip *ice40_gpio;

	mm_gc = to_of_mm_gpio_chip(gc);
	ice40_gpio = gpiochip_get_data(gc);

	pr_info("offset:0x%x  value: 0x%x", offset, value);
}

static int ice40_gpio_dir_input(struct gpio_chip *gc, unsigned int offset)
{

	pr_info("ice40_gpio: dir input");

	pr_info("offset:0x%x", offset);

	return 0;
}

static int ice40_gpio_dir_output(struct gpio_chip *gc, unsigned int offset,
				       int value)
{
	pr_info("ice40_gpio: dir output");
	pr_info("offset:0x%x  value: 0x%x", offset, value);

	return 0;
}

static int ice40_gpio_probe(struct platform_device *pdev)
{
	struct device_node *node = pdev->dev.of_node;
	int ret;
	int reg;
	struct ice40_gpio_chip *ice40_gpio;

	ice40_gpio = devm_kzalloc(&pdev->dev, sizeof(*ice40_gpio),
				       GFP_KERNEL);

	if (!ice40_gpio)
		return -ENOMEM;

	if (of_property_read_u32(node, "ice40-gpio,ngpio", &reg))
		ice40_gpio->mmchip.gc.ngpio = ICE40_GPIO_MAX_NGPIO;

	if (reg <= ICE40_GPIO_MAX_NGPIO)
		ice40_gpio->mmchip.gc.ngpio = reg;

	pr_info("reg: %d", reg);

	ice40_gpio->mmchip.gc.direction_input    = ice40_gpio_dir_input;
	ice40_gpio->mmchip.gc.direction_output   = ice40_gpio_dir_output;
	ice40_gpio->mmchip.gc.get                = ice40_gpio_get;
	ice40_gpio->mmchip.gc.set                = ice40_gpio_set;
	ice40_gpio->mmchip.gc.owner              = THIS_MODULE;
	ice40_gpio->mmchip.gc.parent             = &pdev->dev;

	ret = of_mm_gpiochip_add_data(node, &ice40_gpio->mmchip, ice40_gpio);
	if (ret) {
		pr_err("ice40-gpio: failed adding memory mapped gpiochip");
		return ret;
	}

	platform_set_drvdata(pdev, ice40_gpio);
	pr_info("ice40_gpio: base: 0x%p", ice40_gpio->mmchip.regs);
	pr_info("ice40_gpio: probe");

	return 0;
}

static int ice40_gpio_remove(struct platform_device *pdev)
{
	struct ice40_gpio_chip *ice40_gpio = platform_get_drvdata(pdev);

	pr_info("ice40_gpio: remove");

	of_mm_gpiochip_remove(&ice40_gpio->mmchip);

	return 0;
}

const struct of_device_id ice40_gpio_of_match[] = {
	{.compatible = "beagle,ice40-gpio", },
	{ }
};
MODULE_DEVICE_TABLE(of, ice40_gpio_of_match);

static struct platform_driver ice40_gpio_driver = {
	.probe	= ice40_gpio_probe,
	.remove = ice40_gpio_remove,
	.driver = {
		.name =	DRIVER_NAME,
		.of_match_table = of_match_ptr(ice40_gpio_of_match),
	},
};

module_platform_driver(ice40_gpio_driver);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Patryk Mezydlo, <mezydlo.p@gmail.com>");
MODULE_DESCRIPTION("Driver for GPIO controller on the ice40 FPGA");
MODULE_VERSION("1.0");
