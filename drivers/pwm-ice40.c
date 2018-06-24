/*
 * Driver for memory mapped PWM controller on ice40 FPGA
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

#include <linux/module.h>
#include <linux/pwm.h>
#include <linux/slab.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/io.h>

#define DRIVER_NAME "ice40-pwm"

#define ICE40_PWM_SETUP_REG_EN_BIT         BIT(0)
#define ICE40_PWM_SETUP_REG_POL_BIT        BIT(1)
#define ICE40_PWM_SETUP_REG                0x0

#define ICE40_PWM_PERIOD_MSB               0x2
#define ICE40_PWM_PERIOD_LSB               0x4
#define ICE40_PWM_DUTY_CYCLE_MSB           0x6
#define ICE40_PWM_DUTY_CYCLE_LSB           0x8

#define ICE40_PWM_CLK_PERIOD		   5

struct ice40_pwm {
	struct pwm_chip chip;
	struct device *dev;
	struct clk *clk;
	void __iomem *base;
};

inline u16 ice40_pwm_read_reg(void __iomem *base, u32 idx)
{
	return ioread16(base + idx);
}

inline void ice40_pwm_write_reg(void __iomem *base,
		u32 idx, u16 val)
{
	iowrite16(val, base + idx);
}

static inline struct ice40_pwm *to_ice40_pwm(struct pwm_chip *chip)
{
	return container_of(chip, struct ice40_pwm, chip);
}

static int ice40_pwm_enable(struct pwm_chip *chip, struct pwm_device *pwm)
{
	struct ice40_pwm *ice40_pwm = to_ice40_pwm(chip);
	u16 setup_reg_cache;

	setup_reg_cache = ice40_pwm_read_reg(ice40_pwm->base,
					     ICE40_PWM_SETUP_REG);
	setup_reg_cache |= ICE40_PWM_SETUP_REG_EN_BIT;
	ice40_pwm_write_reg(ice40_pwm->base, ICE40_PWM_SETUP_REG,
			    setup_reg_cache);

	return 0;
}

static void ice40_pwm_disable(struct pwm_chip *chip, struct pwm_device *pwm)
{
	struct ice40_pwm *ice40_pwm = to_ice40_pwm(chip);
	u16 setup_reg_cache;

	setup_reg_cache = ice40_pwm_read_reg(ice40_pwm->base,
					     ICE40_PWM_SETUP_REG);
	setup_reg_cache &= ~ICE40_PWM_SETUP_REG_EN_BIT;
	ice40_pwm_write_reg(ice40_pwm->base, ICE40_PWM_SETUP_REG,
			    setup_reg_cache);
}

static int ice40_pwm_config(struct pwm_chip *chip, struct pwm_device *pwm,
			    int duty_ns, int period_ns)
{
	struct ice40_pwm *ice40_pwm = to_ice40_pwm(chip);
	u32 clk_counter;
	u32 duty_counter;

	clk_counter = (u32)div_u64(period_ns, ICE40_PWM_CLK_PERIOD) - 1;
	duty_counter = (u32)div_u64(duty_ns, ICE40_PWM_CLK_PERIOD) - 1;

	ice40_pwm_write_reg(ice40_pwm->base, ICE40_PWM_PERIOD_MSB,
			    (u16)(clk_counter >> 16));

	ice40_pwm_write_reg(ice40_pwm->base, ICE40_PWM_PERIOD_LSB,
			    (u16)clk_counter);

	ice40_pwm_write_reg(ice40_pwm->base, ICE40_PWM_DUTY_CYCLE_MSB,
			    (u16)(duty_counter >> 16));

	ice40_pwm_write_reg(ice40_pwm->base, ICE40_PWM_DUTY_CYCLE_LSB,
			    (u16)duty_counter);

	return 0;
}

static int ice40_pwm_set_poleaity(struct pwm_chip *chip, struct pwm_device *pwm,
				  enum pwm_polarity polarity)
{
	struct ice40_pwm *ice40_pwm = to_ice40_pwm(chip);
	u16 setup_reg_cache;

	setup_reg_cache = ice40_pwm_read_reg(ice40_pwm->base,
					     ICE40_PWM_SETUP_REG);

	if (polarity == PWM_POLARITY_INVERSED)
		setup_reg_cache |= ICE40_PWM_SETUP_REG_POL_BIT;
	else
		setup_reg_cache &= ~ICE40_PWM_SETUP_REG_POL_BIT;

	ice40_pwm_write_reg(ice40_pwm->base, ICE40_PWM_SETUP_REG,
			    setup_reg_cache);
	return 0;
}

static const struct pwm_ops ice40_pwm_ops = {
	.config = ice40_pwm_config,
	.enable = ice40_pwm_enable,
	.disable = ice40_pwm_disable,
	.set_polarity = ice40_pwm_set_poleaity,
	.owner = THIS_MODULE,
};

static int ice40_pwm_probe(struct platform_device *pdev)
{
	struct ice40_pwm *ice40_pwm;
	struct resource *res;
	int ret;

	ice40_pwm = devm_kzalloc(&pdev->dev, sizeof(*ice40_pwm), GFP_KERNEL);
	if (!ice40_pwm)
		return -ENOMEM;

	res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	ice40_pwm->base = devm_ioremap_resource(&pdev->dev, res);
	if (IS_ERR(ice40_pwm->base))
		return PTR_ERR(ice40_pwm->base);

	ice40_pwm->chip.dev = &pdev->dev;
	ice40_pwm->chip.ops = &ice40_pwm_ops;
	ice40_pwm->chip.base = -1;
	ice40_pwm->chip.npwm = 1;

	ret = pwmchip_add(&ice40_pwm->chip);
	if (ret < 0)
		return ret;

	platform_set_drvdata(pdev, ice40_pwm);

	return 0;
}

static int ice40_pwm_remove(struct platform_device *pdev)
{
	struct ice40_pwm *ice40_pwm = platform_get_drvdata(pdev);

	return pwmchip_remove(&ice40_pwm->chip);
}

static const struct of_device_id ice40_pwm_of_match[] = {
	{ .compatible = "beagle,ice40-pwm", },
	{}
};
MODULE_DEVICE_TABLE(of, ice40_pwm_of_match);

static struct platform_driver ice40_pwm_driver = {
	.driver = {
		.name = DRIVER_NAME,
		.of_match_table = ice40_pwm_of_match,
	},
	.probe = ice40_pwm_probe,
	.remove = ice40_pwm_remove,
};

module_platform_driver(ice40_pwm_driver);

MODULE_LICENSE("GPL v2");
MODULE_AUTHOR("Patryk Mezydlo, <mezydlo.p@gmail.com>");
MODULE_DESCRIPTION("Driver for PWM controller on the ice40 FPGA");
MODULE_VERSION("1.0");
