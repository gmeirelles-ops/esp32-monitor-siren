/**
 * @file pzem004t.h
 * @brief Driver PZEM-004T V3 (Modbus RTU). Substitua por biblioteca de terceiros
 *        clonada em `components/pzem004t` quando disponível.
 */

#pragma once

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Inicializa UART e driver Modbus para o PZEM-004T V3. */
esp_err_t pzem004t_init(int uart_num, int tx_gpio, int rx_gpio);

/**
 * Lê potência ativa em Watts.
 * @param power_w Saída em W (float).
 * @return ESP_OK ou erro (timeout/CRC).
 */
esp_err_t pzem004t_read_active_power_w(float *power_w);

#ifdef __cplusplus
}
#endif
