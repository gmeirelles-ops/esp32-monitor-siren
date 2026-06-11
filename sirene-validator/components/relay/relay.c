#include "relay.h"

#include "board_config.h"
#include "driver/gpio.h"

static bool s_on = false;

void relay_init_safe(void)
{
    gpio_config_t cfg = {
        .pin_bit_mask = 1ULL << GPIO_RELAY,
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&cfg);
    gpio_set_level(GPIO_RELAY, 0);
    s_on = false;
}

void relay_set(bool on)
{
    gpio_set_level(GPIO_RELAY, on ? 1 : 0);
    s_on = on;
}

bool relay_is_on(void)
{
    return s_on;
}
