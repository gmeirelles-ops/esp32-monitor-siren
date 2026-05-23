/**
 * @file pzem004t.c
 * @brief Implementação Modbus RTU PZEM-004T V3 (placeholder até biblioteca externa).
 */

#include "pzem004t.h"

#include <string.h>

#include "driver/gpio.h"
#include "driver/uart.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"

#define TAG                 "pzem004t"
#define PZEM_BAUD           9600
#define MODBUS_TIMEOUT_MS   2000
#define PZEM_MODBUS_ADDR    0xF8
#define PZEM_CMD_READ       0x04
#define PZEM_REG_POWER      0x0002
#define PZEM_REG_COUNT      1
#define MODBUS_REQ_LEN      8
#define MODBUS_RESP_MAX     32

static int s_uart_num = -1;

static uint16_t modbus_crc16(const uint8_t *data, size_t len)
{
    uint16_t crc = 0xFFFF;

    for (size_t i = 0; i < len; i++) {
        crc ^= (uint16_t)data[i];
        for (int bit = 0; bit < 8; bit++) {
            if (crc & 0x0001) {
                crc = (crc >> 1) ^ 0xA001;
            } else {
                crc >>= 1;
            }
        }
    }
    return crc;
}

esp_err_t pzem004t_init(int uart_num, int tx_gpio, int rx_gpio)
{
    const uart_config_t uart_cfg = {
        .baud_rate  = PZEM_BAUD,
        .data_bits  = UART_DATA_8_BITS,
        .parity     = UART_PARITY_DISABLE,
        .stop_bits  = UART_STOP_BITS_1,
        .flow_ctrl  = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };

    esp_err_t err = uart_driver_install(uart_num, 256, 256, 0, NULL, 0);
    if (err != ESP_OK) {
        return err;
    }

    ESP_ERROR_CHECK(uart_param_config(uart_num, &uart_cfg));
    ESP_ERROR_CHECK(uart_set_pin(uart_num, tx_gpio, rx_gpio,
                                 UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE));

    s_uart_num = uart_num;
    ESP_LOGI(TAG, "UART%d TX=%d RX=%d @ %d baud", uart_num, tx_gpio, rx_gpio, PZEM_BAUD);
    return ESP_OK;
}

esp_err_t pzem004t_read_active_power_w(float *power_w)
{
    if (power_w == NULL || s_uart_num < 0) {
        return ESP_ERR_INVALID_STATE;
    }

    uint8_t req[MODBUS_REQ_LEN];
    req[0] = PZEM_MODBUS_ADDR;
    req[1] = PZEM_CMD_READ;
    req[2] = (uint8_t)(PZEM_REG_POWER >> 8);
    req[3] = (uint8_t)(PZEM_REG_POWER & 0xFF);
    req[4] = (uint8_t)(PZEM_REG_COUNT >> 8);
    req[5] = (uint8_t)(PZEM_REG_COUNT & 0xFF);

    const uint16_t crc = modbus_crc16(req, 6);
    req[6] = (uint8_t)(crc & 0xFF);
    req[7] = (uint8_t)(crc >> 8);

    uart_flush(s_uart_num);
    const int sent = uart_write_bytes(s_uart_num, req, sizeof(req));
    if (sent != (int)sizeof(req)) {
        ESP_LOGE(TAG, "UART write falhou (%d/%d)", sent, (int)sizeof(req));
        return ESP_FAIL;
    }

    uint8_t resp[MODBUS_RESP_MAX] = {0};
    const int len = uart_read_bytes(s_uart_num, resp, sizeof(resp),
                                    pdMS_TO_TICKS(MODBUS_TIMEOUT_MS));
    if (len < 7) {
        ESP_LOGE(TAG, "timeout Modbus (%d bytes)", len);
        return ESP_ERR_TIMEOUT;
    }

    const uint16_t crc_rx = (uint16_t)((uint16_t)resp[len - 1] << 8 | resp[len - 2]);
    if (modbus_crc16(resp, (size_t)(len - 2)) != crc_rx) {
        ESP_LOGE(TAG, "CRC inválido");
        return ESP_FAIL;
    }

    if (resp[0] != PZEM_MODBUS_ADDR || resp[1] != PZEM_CMD_READ || resp[2] < 2) {
        ESP_LOGE(TAG, "resposta Modbus inválida");
        return ESP_FAIL;
    }

    const uint16_t reg = (uint16_t)(((uint16_t)resp[3] << 8) | resp[4]);
    *power_w = (float)reg * 0.1f;
    return ESP_OK;
}
