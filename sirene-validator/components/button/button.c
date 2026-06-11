#include "button.h"

#include "board_config.h"
#include "driver/gpio.h"
#include "esp_timer.h"

static QueueHandle_t s_queue;
static volatile bool s_test_in_progress;
static int64_t s_last_press_us;

static void IRAM_ATTR button_isr(void *arg)
{
    (void)arg;
    int64_t now = esp_timer_get_time();
    if (now - s_last_press_us < (BUTTON_DEBOUNCE_MS * 1000)) {
        return;
    }
    s_last_press_us = now;
    if (gpio_get_level(GPIO_BUTTON) == 0 && s_queue && !s_test_in_progress) {
        uint8_t ev = 1;
        BaseType_t hp = pdFALSE;
        xQueueSendFromISR(s_queue, &ev, &hp);
        if (hp) {
            portYIELD_FROM_ISR();
        }
    }
}

void button_init(QueueHandle_t event_queue)
{
    s_queue = event_queue;
    s_test_in_progress = false;

    gpio_config_t cfg = {
        .pin_bit_mask = 1ULL << GPIO_BUTTON,
        .mode = GPIO_MODE_INPUT,
        .pull_up_en = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_NEGEDGE,
    };
    gpio_config(&cfg);
    gpio_install_isr_service(0);
    gpio_isr_handler_add(GPIO_BUTTON, button_isr, NULL);
}

bool button_is_test_in_progress(void)
{
    return s_test_in_progress;
}

void button_set_test_in_progress(bool in_progress)
{
    s_test_in_progress = in_progress;
}
