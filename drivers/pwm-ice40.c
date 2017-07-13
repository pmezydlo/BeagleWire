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

	return 0;
}

static void ice40_pwm_disable(struct pwm_chip *chip, struct pwm_device *pwm)
{


}

static int ice40_pwm_config(struct pwm_chip *chip, struct pwm_device *pwm,
			    int duty_ns, int period_ns)
{

	return 0;
}

static const struct pwm_ops ice40_pwm_ops = {
	.config = ice40_pwm_config,
	.enable = ice40_pwm_enable,
	.disable = ice40_pwm_disable,
	.owner = THIS_MODULE,
};

static int ice40_pwm_probe(struct platform_device *pdev)
{

	return 0;
}

static int ice40_pwm_remove(struct platform_device *pdev)
{

	return 0;
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
MODULE_DESCRIPTION("Driver for SPI controller on the ice40 FPGA");
MODULE_VERSION("1.0");
