/**
 * @file wifi_manager.h
 * @brief Gerenciamento de conexão Wi-Fi STA (ESP-IDF).
 */

#pragma once

#include <stdbool.h>

#include "esp_err.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"

#ifdef __cplusplus
extern "C" {
#endif

#define WIFI_MANAGER_CONNECTED_BIT  BIT0

esp_err_t wifi_manager_init(void);
bool wifi_manager_is_connected(void);
EventGroupHandle_t wifi_manager_get_event_group(void);
void wifi_manager_task(void *pv_parameters);

#ifdef __cplusplus
}
#endif
