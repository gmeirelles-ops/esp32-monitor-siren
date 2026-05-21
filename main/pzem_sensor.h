/**
 * @file pzem_sensor.h
 * @brief UART1 e leitura Modbus RTU do PZEM-004T v3.0 (valores inteiros brutos).
 */

#pragma once

#include <stdint.h>

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Valores brutos dos registradores Modbus (sem escala decimal). */
typedef struct {
    uint32_t corrente_raw;
    uint32_t potencia_raw;
} pzem_reading_t;

esp_err_t pzem_sensor_init(void);
esp_err_t pzem_sensor_read(pzem_reading_t *reading);

#ifdef __cplusplus
}
#endif
