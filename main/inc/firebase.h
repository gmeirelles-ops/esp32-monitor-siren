/**
 * @file firebase.h
 * @brief Cliente HTTP PATCH para Firebase Realtime Database (payload JSON com inteiros).
 */

#pragma once

#include <stdint.h>

#include "esp_err.h"

#ifdef __cplusplus
extern "C" {
#endif

esp_err_t firebase_patch_aguardando(void);
esp_err_t firebase_patch_concluido(uint32_t corrente_raw, uint32_t potencia_raw);
esp_err_t firebase_patch_erro_sensor(void);

#ifdef __cplusplus
}
#endif
