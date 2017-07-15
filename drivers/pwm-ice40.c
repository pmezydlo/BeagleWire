#include <linux/module.h>
#include <linux/pwm.h>
#include <linux/slab.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/io.h>

#define DRIVER_NAME "ice40-pwm"

#define ICE40_PWM_SETUP_REG_EN_BIT BIT     (0)
#define ICE40_PWM_SETUP_REG_POL_BIT BIT    (1)
#define ICE40_PWM_SETUP_REG                0x0
#define ICE40_PWM_PERIOD_REG               0x2
#define ICE40_PWM_DUTY_CYCLE               0x4

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
