/**
 * @file pzem_sensor.c
 * @brief Casca (wrapper) sobre o componente pzem004t.
 */

#include "pzem_sensor.h"

#include "driver/uart.h"
#include "esp_err.h"
#include "esp_log.h"
#include "pzem004t.h"

#define PZEM_UART_NUM       UART_NUM_1
#define PZEM_UART_TX_PIN    17
#define PZEM_UART_RX_PIN    16

static const char *TAG = "pzem_sensor";

void pzem_sensor_init(void)
{
    const esp_err_t err = pzem004t_init(PZEM_UART_NUM, PZEM_UART_TX_PIN, PZEM_UART_RX_PIN);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "pzem004t_init falhou: %s", esp_err_to_name(err));
        return;
    }
    ESP_LOGI(TAG, "PZEM OK – UART%d TX=GPIO%d RX=GPIO%d",
             PZEM_UART_NUM, PZEM_UART_TX_PIN, PZEM_UART_RX_PIN);
}

float pzem_get_power(void)
{
    float power_w = 0.0f;
    const esp_err_t err = pzem004t_read_active_power_w(&power_w);

    if (err != ESP_OK) {
        ESP_LOGW(TAG, "leitura falhou: %s", esp_err_to_name(err));
        return -1.0f;
    }

    ESP_LOGD(TAG, "potência=%.2f W", power_w);
    return power_w;
}
