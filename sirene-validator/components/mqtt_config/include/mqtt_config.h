#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

bool mqtt_config_get_uri(char *uri, size_t uri_len);
bool mqtt_config_load(char *host, size_t host_len, uint32_t *port);
bool mqtt_config_save(const char *host, uint32_t port);
bool mqtt_config_has_stored(void);
