/**
 * @file comm.h
 * @brief Wi-Fi, MQTT (telemetria) e Firebase RTDB (config/resultado).
 */

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

void comm_init(void);
void mqtt_publish_power(float power);

/** Tempo de teste em segundos; retorna -1 em caso de erro. */
int firebase_get_test_time(void);

void firebase_send_result(float max_power_read);

#ifdef __cplusplus
}
#endif
