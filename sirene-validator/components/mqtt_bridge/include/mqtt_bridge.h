#pragma once

#include <stdbool.h>

typedef void (*mqtt_command_cb_t)(const char *payload, int len);
typedef void (*mqtt_connected_cb_t)(void);

bool mqtt_bridge_init(mqtt_command_cb_t cmd_cb, mqtt_connected_cb_t connected_cb);
bool mqtt_bridge_is_connected(void);
bool mqtt_bridge_publish(const char *topic_suffix, const char *json);
bool mqtt_bridge_publish_status(const char *json);
bool mqtt_bridge_publish_alerta(const char *json);
bool mqtt_bridge_publish_calibracao(const char *json);
bool mqtt_bridge_publish_rejection(const char *reason);
