#pragma once

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

bool mqtt_config_get_uri(char *uri, size_t uri_len);
bool mqtt_config_load(char *host, size_t host_len, uint32_t *port);
bool mqtt_config_load_auth(char *user, size_t user_len, char *pass, size_t pass_len);
bool mqtt_config_load_tls(bool *tls);
bool mqtt_config_save(const char *host, uint32_t port, const char *user, const char *pass, bool tls);
bool mqtt_config_clear(void);
bool mqtt_config_has_stored(void);
bool mqtt_config_broker_is_private_lan(void);
