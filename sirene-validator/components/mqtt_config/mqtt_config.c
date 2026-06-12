#include "mqtt_config.h"

#include <stdio.h>
#include <string.h>

#include "board_config.h"
#include "nvs.h"

bool mqtt_config_load(char *host, size_t host_len, uint32_t *port)
{
    nvs_handle_t handle;
    if (nvs_open(MQTT_NVS_NAMESPACE, NVS_READONLY, &handle) != ESP_OK) {
        return false;
    }
    size_t len = host_len;
    if (nvs_get_str(handle, MQTT_NVS_HOST_KEY, host, &len) != ESP_OK || host[0] == '\0') {
        nvs_close(handle);
        return false;
    }
    if (nvs_get_u32(handle, MQTT_NVS_PORT_KEY, port) != ESP_OK || *port == 0) {
        nvs_close(handle);
        return false;
    }
    nvs_close(handle);
    return true;
}

bool mqtt_config_save(const char *host, uint32_t port)
{
    nvs_handle_t handle;
    if (nvs_open(MQTT_NVS_NAMESPACE, NVS_READWRITE, &handle) != ESP_OK) {
        return false;
    }
    nvs_set_str(handle, MQTT_NVS_HOST_KEY, host);
    nvs_set_u32(handle, MQTT_NVS_PORT_KEY, port);
    esp_err_t err = nvs_commit(handle);
    nvs_close(handle);
    return err == ESP_OK;
}

bool mqtt_config_has_stored(void)
{
    char host[65];
    uint32_t port = 0;
    return mqtt_config_load(host, sizeof(host), &port);
}

bool mqtt_config_get_uri(char *uri, size_t uri_len)
{
    char host[65] = {0};
    uint32_t port = 0;
    if (mqtt_config_load(host, sizeof(host), &port)) {
        snprintf(uri, uri_len, "mqtt://%s:%lu", host, (unsigned long)port);
        return true;
    }
    strncpy(uri, MQTT_BROKER_URI, uri_len - 1);
    uri[uri_len - 1] = '\0';
    return false;
}
