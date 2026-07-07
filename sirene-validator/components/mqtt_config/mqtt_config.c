#include "mqtt_config.h"

#include <stdio.h>
#include <string.h>

#include "board_config.h"
#include "nvs.h"
#include "pure_logic.h"

static bool open_ro(nvs_handle_t *handle)
{
    return nvs_open(MQTT_NVS_NAMESPACE, NVS_READONLY, handle) == ESP_OK;
}

static const char *mqtt_scheme_for(bool tls, uint32_t port)
{
    if (!tls) {
        return "mqtt";
    }
    if (port == MQTT_DEFAULT_PORT_TLS || port == 443) {
        return "wss";
    }
    return "mqtts";
}

bool mqtt_config_load(char *host, size_t host_len, uint32_t *port)
{
    nvs_handle_t handle;
    if (!open_ro(&handle)) {
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

bool mqtt_config_load_tls(bool *tls)
{
    if (tls) {
        *tls = false;
    }
    nvs_handle_t handle;
    if (!open_ro(&handle)) {
        return false;
    }
    uint8_t flag = 0;
    if (nvs_get_u8(handle, MQTT_NVS_TLS_KEY, &flag) == ESP_OK && tls) {
        *tls = flag != 0;
    }
    nvs_close(handle);
    return true;
}

bool mqtt_config_load_auth(char *user, size_t user_len, char *pass, size_t pass_len)
{
    if (user && user_len > 0) {
        user[0] = '\0';
    }
    if (pass && pass_len > 0) {
        pass[0] = '\0';
    }

    nvs_handle_t handle;
    if (!open_ro(&handle)) {
        goto defaults;
    }

    bool has_user = false;
    if (user && user_len > 0) {
        size_t len = user_len;
        if (nvs_get_str(handle, MQTT_NVS_USER_KEY, user, &len) == ESP_OK && user[0] != '\0') {
            has_user = true;
        }
    }
    if (pass && pass_len > 0) {
        size_t len = pass_len;
        nvs_get_str(handle, MQTT_NVS_PASS_KEY, pass, &len);
    }
    nvs_close(handle);
    if (has_user) {
        return true;
    }

defaults:
    if (user && user_len > 0) {
        strncpy(user, MQTT_DEFAULT_USER, user_len - 1);
        user[user_len - 1] = '\0';
    }
    if (pass && pass_len > 0) {
        strncpy(pass, MQTT_DEFAULT_PASS, pass_len - 1);
        pass[pass_len - 1] = '\0';
    }
    return MQTT_DEFAULT_USER[0] != '\0';
}

bool mqtt_config_save(const char *host, uint32_t port, const char *user, const char *pass, bool tls)
{
    nvs_handle_t handle;
    if (nvs_open(MQTT_NVS_NAMESPACE, NVS_READWRITE, &handle) != ESP_OK) {
        return false;
    }
    esp_err_t err = nvs_set_str(handle, MQTT_NVS_HOST_KEY, host);
    if (err == ESP_OK) {
        err = nvs_set_u32(handle, MQTT_NVS_PORT_KEY, port);
    }
    if (err == ESP_OK) {
        err = nvs_set_u8(handle, MQTT_NVS_TLS_KEY, tls ? 1 : 0);
    }
    if (err == ESP_OK) {
        if (user && user[0] != '\0') {
            err = nvs_set_str(handle, MQTT_NVS_USER_KEY, user);
            if (err == ESP_OK) {
                err = nvs_set_str(handle, MQTT_NVS_PASS_KEY, pass ? pass : "");
            }
        } else {
            nvs_erase_key(handle, MQTT_NVS_USER_KEY);
            nvs_erase_key(handle, MQTT_NVS_PASS_KEY);
        }
    }
    if (err == ESP_OK) {
        err = nvs_commit(handle);
    }
    nvs_close(handle);
    return err == ESP_OK;
}

bool mqtt_config_clear(void)
{
    nvs_handle_t handle;
    if (nvs_open(MQTT_NVS_NAMESPACE, NVS_READWRITE, &handle) != ESP_OK) {
        return false;
    }
    esp_err_t err = nvs_erase_all(handle);
    if (err == ESP_OK) {
        err = nvs_commit(handle);
    }
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
    bool tls = false;
    if (mqtt_config_load(host, sizeof(host), &port)) {
        mqtt_config_load_tls(&tls);
        if (tls && port == MQTT_DEFAULT_PORT && pure_host_is_private_lan(host)) {
            tls = false;
        }
        snprintf(uri, uri_len, "%s://%s:%lu", mqtt_scheme_for(tls, port), host, (unsigned long)port);
        return true;
    }
    strncpy(uri, MQTT_BROKER_URI, uri_len - 1);
    uri[uri_len - 1] = '\0';
    return false;
}

bool mqtt_config_broker_is_private_lan(void)
{
    char host[65] = {0};
    uint32_t port = 0;
    if (!mqtt_config_load(host, sizeof(host), &port)) {
        return false;
    }
    return pure_host_is_private_lan(host);
}
