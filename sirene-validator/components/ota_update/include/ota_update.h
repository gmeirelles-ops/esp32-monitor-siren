#pragma once

#include <stdbool.h>

typedef void (*ota_status_cb_t)(const char *json);

bool ota_update_init(ota_status_cb_t status_cb);
bool ota_update_mark_valid_on_boot(void);
bool ota_update_start(const char *url);
bool ota_update_is_active(void);
