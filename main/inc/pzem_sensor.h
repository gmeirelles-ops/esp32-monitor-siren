/**
 * @file pzem_sensor.h
 * @brief Wrapper do sensor PZEM-004T V3 (isola biblioteca em components/pzem004t).
 */

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/** Inicializa UART e driver do PZEM via componente externo. */
void pzem_sensor_init(void);

/**
 * Lê potência ativa em Watts.
 * @return Potência em W, ou -1.0 em caso de falha (timeout/CRC).
 */
float pzem_get_power(void);

#ifdef __cplusplus
}
#endif
