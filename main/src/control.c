/**
 * @file control.c
 */

#include "control.h"

#include "driver/gpio.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define BUTTON_PIN      GPIO_NUM_0
#define SSR_PIN         GPIO_NUM_2
#define DEBOUNCE_MS     50

static const char *TAG = "control";

void control_init(void)
{
    const gpio_config_t btn = {
        .pin_bit_mask = (1ULL << BUTTON_PIN),
        .mode         = GPIO_MODE_INPUT,
        .pull_up_en   = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type    = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&btn));

    const gpio_config_t ssr = {
        .pin_bit_mask = (1ULL << SSR_PIN),
        .mode         = GPIO_MODE_OUTPUT,
        .pull_up_en   = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type    = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&ssr));

    gpio_set_level(SSR_PIN, 0);
    ESP_LOGI(TAG, "GPIO OK – botão=%d SSR=%d", (int)BUTTON_PIN, (int)SSR_PIN);
}

void relay_set(bool state)
{
    gpio_set_level(SSR_PIN, state ? 1 : 0);
    ESP_LOGI(TAG, "SSR %s", state ? "LIGADO" : "DESLIGADO");
}

bool button_is_pressed(void)
{
    if (gpio_get_level(BUTTON_PIN) != 0) {
        return false;
    }

    vTaskDelay(pdMS_TO_TICKS(DEBOUNCE_MS));

    const bool pressed = (gpio_get_level(BUTTON_PIN) == 0);
    if (pressed) {
        ESP_LOGD(TAG, "botão confirmado (%d ms debounce)", DEBOUNCE_MS);
    }
    return pressed;
}
