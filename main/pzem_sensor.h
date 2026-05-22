/**
 * @file pzem_sensor.h
 * @brief UART1 e leitura Modbus RTU do PZEM-004T v3.0 (potência em W brutos).
 */

#pragma once

#include <stdint.h>

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Comando: leitura do registrador de potência ativa (W × 0,1 no chip → escala app). */
#define PZEM_CMD_READ_POWER  0x04

/** Potência em centésimos de watt (ex.: 1000 = 10,00 W), alinhado ao app Flutter. */
typedef struct {
    uint32_t potencia_raw;
} pzem_power_t;

esp_err_t pzem_sensor_init(void);
esp_err_t pzem_sensor_read_power(uint32_t *potencia_raw);

#ifdef __cplusplus
}
#endif
