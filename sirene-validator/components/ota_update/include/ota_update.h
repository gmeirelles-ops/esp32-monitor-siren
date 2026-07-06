#pragma once

#include <stdbool.h>

typedef void (*ota_status_cb_t)(const char *json);
typedef bool (*ota_smoke_test_fn_t)(void);

bool ota_update_init(ota_status_cb_t status_cb);
void ota_update_set_smoke_test(ota_smoke_test_fn_t fn);
/** Apaga NVS + SPIFFS no primeiro boot após OTA (se Kconfig habilitado). Chamar logo após nvs_flash_init(). */
bool ota_update_erase_factory_data_if_pending(void);
bool ota_update_mark_valid_on_boot(void);
bool ota_update_start(const char *url);
bool ota_update_is_active(void);
