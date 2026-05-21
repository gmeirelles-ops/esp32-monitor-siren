/**
 * @file hardware.h
 * @brief GPIO (botão e SSR) e task de ciclo de teste.
 */

#pragma once

#include <stdbool.h>

#include "esp_err.h"
#include "freertos/FreeRTOS.h"

#ifdef __cplusplus
extern "C" {
#endif

#define HARDWARE_DEBOUNCE_MS       50
#define HARDWARE_INRUSH_DELAY_MS   1000

esp_err_t hardware_init(void);
void hardware_ssr_set(bool on);
bool hardware_botao_debounce(void);
void hardware_test_task(void *pv_parameters);

#ifdef __cplusplus
}
#endif
