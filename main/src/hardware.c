/**
 * @file hardware.c
 */

#include "hardware.h"

#include "esp_log.h"
#include "freertos/task.h"
#include "driver/gpio.h"

#include "firebase.h"
#include "pzem_sensor.h"

#define BOTAO_PIN      GPIO_NUM_0
#define SSR_RELE_PIN   GPIO_NUM_4

static const char *TAG = "hardware";

static const TickType_t s_debounce_ticks =
    pdMS_TO_TICKS(HARDWARE_DEBOUNCE_MS);

static const TickType_t s_inrush_ticks =
    pdMS_TO_TICKS(HARDWARE_INRUSH_DELAY_MS);

esp_err_t hardware_init(void)
{
    const gpio_config_t btn_cfg = {
        .pin_bit_mask = (1ULL << BOTAO_PIN),
        .mode         = GPIO_MODE_INPUT,
        .pull_up_en   = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type    = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&btn_cfg));

    const gpio_config_t ssr_cfg = {
        .pin_bit_mask = (1ULL << SSR_RELE_PIN),
        .mode         = GPIO_MODE_OUTPUT,
        .pull_up_en   = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type    = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&ssr_cfg));

    gpio_set_level(SSR_RELE_PIN, 0);
    ESP_LOGI(TAG, "GPIO OK – botão %d, SSR %d", (int)BOTAO_PIN, (int)SSR_RELE_PIN);
    return ESP_OK;
}

void hardware_ssr_set(bool on)
{
    gpio_set_level(SSR_RELE_PIN, on ? 1 : 0);
}

bool hardware_botao_debounce(void)
{
    if (gpio_get_level(BOTAO_PIN) != 0) {
        return false;
    }

    vTaskDelay(s_debounce_ticks);

    return (gpio_get_level(BOTAO_PIN) == 0);
}

static void executar_ciclo_teste(void)
{
    ESP_LOGI(TAG, "ciclo de teste iniciado");

    hardware_ssr_set(true);
    ESP_LOGI(TAG, "SSR ON – inrush %d ms", HARDWARE_INRUSH_DELAY_MS);
    vTaskDelay(s_inrush_ticks);

    pzem_reading_t reading = {0};
    const esp_err_t err = pzem_sensor_read(&reading);

    hardware_ssr_set(false);
    ESP_LOGI(TAG, "SSR OFF");

    if (err != ESP_OK) {
        firebase_patch_erro_sensor();
        return;
    }

    firebase_patch_concluido(reading.corrente_raw, reading.potencia_raw);
}

void hardware_test_task(void *pv_parameters)
{
    (void)pv_parameters;

    ESP_LOGI(TAG, "Task_Teste no core %d", xPortGetCoreID());

    firebase_patch_aguardando();

    for (;;) {
        if (hardware_botao_debounce()) {
            ESP_LOGI(TAG, "botão confirmado (%d ms debounce)", HARDWARE_DEBOUNCE_MS);
            executar_ciclo_teste();
            firebase_patch_aguardando();
        }
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}
