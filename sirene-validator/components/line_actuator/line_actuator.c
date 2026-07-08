#include "line_actuator.h"

#include "board_config.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "sdkconfig.h"

static const char *TAG = "line_actuator";

static esp_timer_handle_t s_reject_timer;
static esp_timer_handle_t s_approve_timer;

static int reject_gpio(void)
{
#if CONFIG_LINE_ACTUATOR_ENABLE
    return CONFIG_LINE_ACTUATOR_REJECT_GPIO;
#else
    return -1;
#endif
}

static int approve_gpio(void)
{
#if CONFIG_LINE_ACTUATOR_ENABLE
    return CONFIG_LINE_ACTUATOR_APPROVE_GPIO;
#else
    return -1;
#endif
}

static int active_level(void)
{
#if CONFIG_LINE_ACTUATOR_ENABLE && CONFIG_LINE_ACTUATOR_ACTIVE_HIGH
    return 1;
#elif CONFIG_LINE_ACTUATOR_ENABLE
    return 0;
#else
    return 0;
#endif
}

static int inactive_level(void)
{
    return active_level() ? 0 : 1;
}

static void gpio_pulse_off(void *arg)
{
    int gpio = (int)(intptr_t)arg;
    if (gpio >= 0) {
        gpio_set_level(gpio, inactive_level());
    }
}

static void configure_output_gpio(int gpio)
{
    if (gpio < 0) {
        return;
    }
    gpio_config_t cfg = {
        .pin_bit_mask = 1ULL << gpio,
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&cfg);
    gpio_set_level(gpio, inactive_level());
}

static void pulse_gpio(int gpio, uint32_t pulse_ms, esp_timer_handle_t timer)
{
    if (gpio < 0 || timer == NULL || pulse_ms == 0) {
        return;
    }
    esp_timer_stop(timer);
    gpio_set_level(gpio, active_level());
    esp_timer_start_once(timer, (uint64_t)pulse_ms * 1000ULL);
}

void line_actuator_init(void)
{
#if !CONFIG_LINE_ACTUATOR_ENABLE
    return;
#else
    configure_output_gpio(reject_gpio());
    configure_output_gpio(approve_gpio());

    const esp_timer_create_args_t reject_args = {
        .callback = gpio_pulse_off,
        .arg = (void *)(intptr_t)reject_gpio(),
        .dispatch_method = ESP_TIMER_TASK,
        .name = "reject_off",
    };
    esp_timer_create(&reject_args, &s_reject_timer);

    const esp_timer_create_args_t approve_args = {
        .callback = gpio_pulse_off,
        .arg = (void *)(intptr_t)approve_gpio(),
        .dispatch_method = ESP_TIMER_TASK,
        .name = "approve_off",
    };
    esp_timer_create(&approve_args, &s_approve_timer);

    ESP_LOGI(TAG, "reject_gpio=%d approve_gpio=%d pulse_reject=%dms",
             reject_gpio(), approve_gpio(), CONFIG_LINE_ACTUATOR_REJECT_PULSE_MS);
#endif
}

void line_actuator_safe_all(void)
{
#if CONFIG_LINE_ACTUATOR_ENABLE
    int rej = reject_gpio();
    int app = approve_gpio();
    if (s_reject_timer) {
        esp_timer_stop(s_reject_timer);
    }
    if (s_approve_timer) {
        esp_timer_stop(s_approve_timer);
    }
    if (rej >= 0) {
        gpio_set_level(rej, inactive_level());
    }
    if (app >= 0) {
        gpio_set_level(app, inactive_level());
    }
#endif
}

void line_actuator_on_approved(bool allow_physical)
{
#if !CONFIG_LINE_ACTUATOR_ENABLE
    (void)allow_physical;
    return;
#else
    if (!allow_physical) {
        return;
    }
    pulse_gpio(approve_gpio(), CONFIG_LINE_ACTUATOR_APPROVE_PULSE_MS, s_approve_timer);
#endif
}

void line_actuator_on_rejected(void)
{
#if CONFIG_LINE_ACTUATOR_ENABLE
    pulse_gpio(reject_gpio(), CONFIG_LINE_ACTUATOR_REJECT_PULSE_MS, s_reject_timer);
#endif
}

int line_actuator_reject_gpio(void)
{
    return reject_gpio();
}

uint16_t line_actuator_reject_pulse_ms(void)
{
#if CONFIG_LINE_ACTUATOR_ENABLE
    return (uint16_t)CONFIG_LINE_ACTUATOR_REJECT_PULSE_MS;
#else
    return 0;
#endif
}
