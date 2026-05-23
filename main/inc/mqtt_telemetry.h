/**
 * @file mqtt_telemetry.h
 * @brief Wi-Fi STA e publicação MQTT de telemetria em tempo real.
 */

#pragma once

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

#define MQTT_TOPIC_POTENCIA  "diponto/bancada1/potencia"

esp_err_t mqtt_telemetry_init(void);

/** Bloqueia até a estação Wi-Fi obter IP. */
void mqtt_telemetry_wait_connected(void);

bool mqtt_telemetry_is_connected(void);

/**
 * Publica potência (W) no tópico diponto/bancada1/potencia.
 * @return ESP_OK se a mensagem foi enfileirada/publicada com sucesso.
 */
esp_err_t mqtt_publish_power(float power);

#ifdef __cplusplus
}
#endif
