#include "pzem.h"

#include <stdio.h>
#include <string.h>

#include "board_config.h"
#include "driver/uart.h"
#include "esp_log.h"
#include "esp_random.h"
#include "esp_task_wdt.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#if CONFIG_DEV_MOCK_PZEM
static float mock_sample_power_w(void)
{
    /* ~70% in 18–22 W, ~30% out of range for exercising approve/reject paths */
    if ((esp_random() % 100) < 70) {
        return 18.0f + (float)(esp_random() % 401) / 100.0f;
    }
    return (esp_random() % 2) == 0 ? 12.0f + (float)(esp_random() % 300) / 100.0f
                                   : 23.0f + (float)(esp_random() % 500) / 100.0f;
}
#endif

static const char *TAG = "pzem";
static pzem_fault_cb_t s_fault_cb;
static bool s_fault;
static uint32_t s_consecutive_errors;

static uint16_t modbus_crc(const uint8_t *data, size_t len)
{
    uint16_t crc = 0xFFFF;
    for (size_t i = 0; i < len; i++) {
        crc ^= data[i];
        for (int j = 0; j < 8; j++) {
            if (crc & 1) {
                crc = (crc >> 1) ^ 0xA001;
            } else {
                crc >>= 1;
            }
        }
    }
    return crc;
}

static void report_fault(bool fault)
{
    if (s_fault == fault) {
        return;
    }
    s_fault = fault;
    if (s_fault_cb) {
        s_fault_cb(fault);
    }
}

static void pzem_log_rx_fail(const char *reason, const uint8_t *data, int len)
{
    if (len <= 0) {
        ESP_LOGW(TAG, "leitura falhou: %s (timeout, len=0)", reason);
        return;
    }

    char hex[49];
    int n = len < 16 ? len : 16;
    int pos = 0;
    for (int i = 0; i < n && pos < (int)sizeof(hex) - 4; i++) {
        pos += snprintf(hex + pos, sizeof(hex) - pos, "%02x ", data[i]);
    }
    ESP_LOGW(TAG, "leitura falhou: %s len=%d rx=[%s]", reason, len, hex);
}

static bool pzem_send_read_power(float *power_w)
{
    uint8_t req[8] = {PZEM_SLAVE_ADDR, 0x04, 0x00, 0x00, 0x00, PZEM_READ_ALL_REGS, 0, 0};
    uint16_t crc = modbus_crc(req, 6);
    req[6] = crc & 0xFF;
    req[7] = (crc >> 8) & 0xFF;

    uart_flush_input(PZEM_UART_NUM);
    if (uart_write_bytes(PZEM_UART_NUM, (const char *)req, sizeof(req)) < 0) {
        ESP_LOGW(TAG, "leitura falhou: write");
        return false;
    }
    if (uart_wait_tx_done(PZEM_UART_NUM, pdMS_TO_TICKS(100)) != ESP_OK) {
        ESP_LOGW(TAG, "leitura falhou: tx_timeout");
        return false;
    }
    vTaskDelay(pdMS_TO_TICKS(PZEM_RESPONSE_DELAY_MS));

    uint8_t resp[PZEM_RESPONSE_ALL_LEN];
    int len = uart_read_bytes(PZEM_UART_NUM, resp, sizeof(resp), pdMS_TO_TICKS(PZEM_READ_TIMEOUT_MS));
    if (len != PZEM_RESPONSE_ALL_LEN) {
        pzem_log_rx_fail("len", resp, len);
        return false;
    }
    if (resp[0] != PZEM_SLAVE_ADDR) {
        pzem_log_rx_fail("addr", resp, len);
        return false;
    }
    if (resp[1] != 0x04) {
        pzem_log_rx_fail("func", resp, len);
        return false;
    }
    if (resp[2] != PZEM_READ_ALL_REGS * 2) {
        pzem_log_rx_fail("bytecount", resp, len);
        return false;
    }

    uint16_t recv_crc = resp[len - 2] | (resp[len - 1] << 8);
    if (modbus_crc(resp, len - 2) != recv_crc) {
        pzem_log_rx_fail("crc", resp, len);
        return false;
    }

    /* Potência ativa: regs 0x0003–0x0004 (32-bit), 1 LSB = 0.1 W */
    uint32_t raw_power = ((uint32_t)resp[11] << 24) | ((uint32_t)resp[12] << 16) |
                         ((uint32_t)resp[9] << 8) | resp[10];
    *power_w = (float)raw_power / 10.0f;
    return true;
}

bool pzem_init(pzem_fault_cb_t fault_cb)
{
    s_fault_cb = fault_cb;
    s_fault = false;
    s_consecutive_errors = 0;

    uart_config_t cfg = {
        .baud_rate = PZEM_BAUD_RATE,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };
    ESP_ERROR_CHECK(uart_driver_install(PZEM_UART_NUM, 256, 0, 0, NULL, 0));
    ESP_ERROR_CHECK(uart_param_config(PZEM_UART_NUM, &cfg));
    ESP_ERROR_CHECK(uart_set_pin(PZEM_UART_NUM, PZEM_TX_PIN, PZEM_RX_PIN, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE));
    return true;
}

bool pzem_probe_read(float *power_w)
{
#if CONFIG_DEV_MOCK_PZEM
    if (power_w != NULL) {
        *power_w = mock_sample_power_w();
    }
    return true;
#else
    float local = 0;
    if (power_w == NULL) {
        power_w = &local;
    }
    return pzem_send_read_power(power_w);
#endif
}

bool pzem_boot_self_test(void)
{
#if CONFIG_DEV_MOCK_PZEM
    ESP_LOGI(TAG, "autoteste PZEM OK (mock)");
    return true;
#else
    float power = 0;
    for (int i = 0; i < PZEM_SAMPLE_READ_RETRIES; i++) {
        if (pzem_send_read_power(&power)) {
            ESP_LOGI(TAG, "autoteste PZEM OK: %.1f W", power);
            return true;
        }
        if (i + 1 < PZEM_SAMPLE_READ_RETRIES) {
            vTaskDelay(pdMS_TO_TICKS(50));
        }
    }
    ESP_LOGW(TAG, "autoteste PZEM falhou após %d tentativas", PZEM_SAMPLE_READ_RETRIES);
    return false;
#endif
}

bool pzem_read_power_w(float *power_w)
{
    if (pzem_send_read_power(power_w)) {
        s_consecutive_errors = 0;
        report_fault(false);
        return true;
    }
    s_consecutive_errors++;
    if (s_consecutive_errors >= 3) {
        report_fault(true);
    }
    return false;
}

bool pzem_is_fault(void)
{
    return s_fault;
}

void pzem_clear_fault(void)
{
    s_consecutive_errors = 0;
    float dummy;
    if (pzem_send_read_power(&dummy)) {
        report_fault(false);
    }
}

bool pzem_measure_cycle(uint32_t duration_sec, uint32_t inrush_discard_ms, pzem_cycle_result_t *out,
                        pzem_sample_cb_t sample_cb, void *sample_ctx)
{
    out->average_w = 0;
    out->sample_count = 0;
    out->uart_error = false;

    TickType_t start = xTaskGetTickCount();
    TickType_t inrush_end = start + pdMS_TO_TICKS(inrush_discard_ms);
    TickType_t cycle_end = start + pdMS_TO_TICKS(duration_sec * 1000);
    uint32_t last_sample_ms = 0;

    double sum = 0;
    while (xTaskGetTickCount() < cycle_end) {
        esp_task_wdt_reset();
        float power = 0;
        bool read_ok = false;
#if CONFIG_DEV_MOCK_PZEM
        power = mock_sample_power_w();
        read_ok = true;
        vTaskDelay(pdMS_TO_TICKS(100));
#else
        for (int attempt = 0; attempt < PZEM_SAMPLE_READ_RETRIES; attempt++) {
            if (pzem_read_power_w(&power)) {
                read_ok = true;
                break;
            }
            if (attempt + 1 < PZEM_SAMPLE_READ_RETRIES) {
                vTaskDelay(pdMS_TO_TICKS(10));
            }
        }
        if (!read_ok) {
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }
#endif
        if (xTaskGetTickCount() >= inrush_end) {
            sum += power;
            out->sample_count++;
            if (sample_cb != NULL) {
                uint32_t elapsed_ms = (uint32_t)((xTaskGetTickCount() - start) * portTICK_PERIOD_MS);
                if (elapsed_ms - last_sample_ms >= CALIBRATION_SAMPLE_MS) {
                    sample_cb(power, elapsed_ms, sample_ctx);
                    last_sample_ms = elapsed_ms;
                }
            }
        }
        vTaskDelay(pdMS_TO_TICKS(100));
    }

    if (out->sample_count == 0) {
        out->uart_error = true;
        return false;
    }

    out->average_w = (float)(sum / out->sample_count);
    return true;
}
