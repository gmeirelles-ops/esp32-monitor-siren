/**
 * @file pzem_sensor.c
 */

#include "pzem_sensor.h"

#include <inttypes.h>
#include <string.h>

#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "driver/gpio.h"
#include "driver/uart.h"

#define PZEM_UART_TX_PIN    GPIO_NUM_17
#define PZEM_UART_RX_PIN    GPIO_NUM_16
#define UART_PZEM_NUM       UART_NUM_1
#define UART_PZEM_BAUD      9600

#define MODBUS_TIMEOUT_MS   2000
#define PZEM_MODBUS_ADDR    0xF8
#define PZEM_REG_POWER      0x0002
#define PZEM_REG_COUNT      1

#define MODBUS_REQ_LEN      8
#define MODBUS_RESP_MAX     32

static const char *TAG = "pzem";

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

esp_err_t pzem_sensor_init(void)
{
    const uart_config_t uart_cfg = {
        .baud_rate  = UART_PZEM_BAUD,
        .data_bits  = UART_DATA_8_BITS,
        .parity     = UART_PARITY_DISABLE,
        .stop_bits  = UART_STOP_BITS_1,
        .flow_ctrl  = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };

    ESP_ERROR_CHECK(uart_driver_install(UART_PZEM_NUM, 256, 256, 0, NULL, 0));
    ESP_ERROR_CHECK(uart_param_config(UART_PZEM_NUM, &uart_cfg));
    ESP_ERROR_CHECK(uart_set_pin(UART_PZEM_NUM,
                                 PZEM_UART_TX_PIN,
                                 PZEM_UART_RX_PIN,
                                 UART_PIN_NO_CHANGE,
                                 UART_PIN_NO_CHANGE));

    ESP_LOGI(TAG, "UART1 TX=%d RX=%d @ %d baud (PZEM_CMD_READ_POWER=0x%02X)",
             (int)PZEM_UART_TX_PIN, (int)PZEM_UART_RX_PIN, UART_PZEM_BAUD,
             PZEM_CMD_READ_POWER);
    return ESP_OK;
}

esp_err_t pzem_sensor_read_power(uint32_t *potencia_raw)
{
    if (potencia_raw == NULL) {
        return ESP_ERR_INVALID_ARG;
    }

    uint8_t req[MODBUS_REQ_LEN];
    req[0] = PZEM_MODBUS_ADDR;
    req[1] = PZEM_CMD_READ_POWER;
    req[2] = (uint8_t)(PZEM_REG_POWER >> 8);
    req[3] = (uint8_t)(PZEM_REG_POWER & 0xFF);
    req[4] = (uint8_t)(PZEM_REG_COUNT >> 8);
    req[5] = (uint8_t)(PZEM_REG_COUNT & 0xFF);

    const uint16_t crc = modbus_crc16(req, 6);
    req[6] = (uint8_t)(crc & 0xFF);
    req[7] = (uint8_t)(crc >> 8);

    uart_flush(UART_PZEM_NUM);
    const int sent = uart_write_bytes(UART_PZEM_NUM, req, sizeof(req));
    if (sent != (int)sizeof(req)) {
        ESP_LOGE(TAG, "UART write falhou (%d/%d)", sent, (int)sizeof(req));
        return ESP_FAIL;
    }

    uint8_t resp[MODBUS_RESP_MAX] = {0};
    const int len = uart_read_bytes(UART_PZEM_NUM, resp, sizeof(resp),
                                    pdMS_TO_TICKS(MODBUS_TIMEOUT_MS));
    if (len < 7) {
        ESP_LOGE(TAG, "timeout Modbus potência (%d bytes)", len);
        return ESP_ERR_TIMEOUT;
    }

    const uint16_t crc_rx = (uint16_t)((uint16_t)resp[len - 1] << 8 | resp[len - 2]);
    if (modbus_crc16(resp, (size_t)(len - 2)) != crc_rx) {
        ESP_LOGE(TAG, "CRC inválido");
        return ESP_FAIL;
    }

    if (resp[0] != PZEM_MODBUS_ADDR || resp[1] != PZEM_CMD_READ_POWER) {
        ESP_LOGE(TAG, "resposta inesperada addr=0x%02X fc=0x%02X", resp[0], resp[1]);
        return ESP_FAIL;
    }

    if (resp[2] < 2) {
        ESP_LOGE(TAG, "payload Modbus curto (%d bytes)", resp[2]);
        return ESP_FAIL;
    }

    const uint16_t reg_potencia = (uint16_t)(((uint16_t)resp[3] << 8) | resp[4]);
    /* Registrador PZEM: 0,1 W → centésimos de W para o ecossistema Diponto (×10). */
    *potencia_raw = (uint32_t)reg_potencia * 10U;

    ESP_LOGD(TAG, "potência reg=%u → raw=%" PRIu32 " (%.2f W)",
             reg_potencia, *potencia_raw, *potencia_raw / 100.0f);
    return ESP_OK;
}
