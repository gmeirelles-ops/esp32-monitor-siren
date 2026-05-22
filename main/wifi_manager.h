/**
 * @file wifi_manager.h
 * @brief Wi-Fi STA com credenciais em NVS e fallback SoftAP + portal cativo.
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

/** Inicializa netif, event loop e driver Wi-Fi (chamar após nvs_flash_init). */
esp_err_t wifi_manager_init(void);

/**
 * Provisionamento: tenta STA (NVS, timeout 10 s); se falhar, abre SoftAP + portal cativo.
 * Bloqueia enquanto o portal estiver ativo (até esp_restart após salvar credenciais).
 */
esp_err_t wifi_manager_run(void);

/** Bloqueia até a estação estar conectada (IP obtido). */
void wifi_manager_wait_connected(void);

bool wifi_manager_is_connected(void);

EventGroupHandle_t wifi_manager_get_event_group(void);

/** Task opcional: monitora reconexão após STA estabelecida. */
void wifi_manager_supervisor_task(void *pv_parameters);

#ifdef __cplusplus
}
#endif
