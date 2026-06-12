#include "led_feedback.h"

#include "board_config.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static TaskHandle_t s_task;

static void feedback_task(void *arg)
{
    feedback_signal_t signal = (feedback_signal_t)(intptr_t)arg;
    switch (signal) {
    case FEEDBACK_APPROVED:
        gpio_set_level(GPIO_LED_STATUS, 1);
        gpio_set_level(GPIO_BUZZER, 0);
        vTaskDelay(pdMS_TO_TICKS(300));
        gpio_set_level(GPIO_LED_STATUS, 0);
        break;
    case FEEDBACK_REJECTED:
        for (int i = 0; i < 3; i++) {
            gpio_set_level(GPIO_BUZZER, 1);
            vTaskDelay(pdMS_TO_TICKS(100));
            gpio_set_level(GPIO_BUZZER, 0);
            vTaskDelay(pdMS_TO_TICKS(100));
        }
        break;
    case FEEDBACK_FAULT:
    case FEEDBACK_QUEUE_FULL:
        gpio_set_level(GPIO_LED_STATUS, 1);
        gpio_set_level(GPIO_BUZZER, 1);
        vTaskDelay(pdMS_TO_TICKS(1000));
        gpio_set_level(GPIO_LED_STATUS, 0);
        gpio_set_level(GPIO_BUZZER, 0);
        break;
    default:
        break;
    }
    s_task = NULL;
    vTaskDelete(NULL);
}

void led_feedback_init(void)
{
    gpio_config_t cfg = {
        .pin_bit_mask = (1ULL << GPIO_LED_STATUS) | (1ULL << GPIO_BUZZER),
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&cfg);
    gpio_set_level(GPIO_LED_STATUS, 0);
    gpio_set_level(GPIO_BUZZER, 0);
}

void led_feedback_signal(feedback_signal_t signal)
{
    if (s_task != NULL) {
        return;
    }
    xTaskCreate(feedback_task, "feedback", 2048, (void *)(intptr_t)signal, 5, &s_task);
}
