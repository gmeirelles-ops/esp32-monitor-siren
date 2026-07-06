#include "mqtt_topics.h"

#include <stdio.h>
#include <string.h>

#include "board_config.h"
#include "nvs.h"

static uint8_t s_bancada;
static char s_site[32];

bool mqtt_topics_init(void)
{
    s_bancada = 0;
    strncpy(s_site, MQTT_DEFAULT_SITE, sizeof(s_site) - 1);
    s_site[sizeof(s_site) - 1] = '\0';

    nvs_handle_t handle;
    if (nvs_open(STATION_NVS_NAMESPACE, NVS_READONLY, &handle) != ESP_OK) {
        return false;
    }

    uint8_t bancada = 0;
    if (nvs_get_u8(handle, STATION_NVS_BANCADA_KEY, &bancada) == ESP_OK && bancada >= 1 && bancada <= 99) {
        s_bancada = bancada;
    }

    size_t site_len = sizeof(s_site);
    char site[32] = {0};
    if (nvs_get_str(handle, STATION_NVS_SITE_KEY, site, &site_len) == ESP_OK && site[0] != '\0') {
        strncpy(s_site, site, sizeof(s_site) - 1);
        s_site[sizeof(s_site) - 1] = '\0';
    }

    nvs_close(handle);
    return mqtt_topics_is_configured();
}

bool mqtt_topics_is_configured(void)
{
    return s_bancada >= 1 && s_bancada <= 99 && s_site[0] != '\0';
}

bool mqtt_topics_build(char *buf, size_t len, const char *suffix)
{
    if (!buf || len == 0 || !suffix || !mqtt_topics_is_configured()) {
        return false;
    }
    int written = snprintf(buf, len, "%s/bancada-%02u/%s", s_site, (unsigned)s_bancada, suffix);
    return written > 0 && (size_t)written < len;
}

bool mqtt_topics_save(uint8_t bancada, const char *site)
{
    if (bancada < 1 || bancada > 99) {
        return false;
    }
    const char *site_str = (site && site[0] != '\0') ? site : MQTT_DEFAULT_SITE;

    nvs_handle_t handle;
    if (nvs_open(STATION_NVS_NAMESPACE, NVS_READWRITE, &handle) != ESP_OK) {
        return false;
    }
    nvs_set_u8(handle, STATION_NVS_BANCADA_KEY, bancada);
    nvs_set_str(handle, STATION_NVS_SITE_KEY, site_str);
    esp_err_t err = nvs_commit(handle);
    nvs_close(handle);
    if (err != ESP_OK) {
        return false;
    }

    s_bancada = bancada;
    strncpy(s_site, site_str, sizeof(s_site) - 1);
    s_site[sizeof(s_site) - 1] = '\0';
    return true;
}

uint8_t mqtt_topics_get_bancada(void)
{
    return s_bancada;
}

const char *mqtt_topics_get_site(void)
{
    return s_site;
}

bool mqtt_topics_clear(void)
{
    nvs_handle_t handle;
    if (nvs_open(STATION_NVS_NAMESPACE, NVS_READWRITE, &handle) != ESP_OK) {
        return false;
    }
    esp_err_t err = nvs_erase_all(handle);
    if (err == ESP_OK) {
        err = nvs_commit(handle);
    }
    nvs_close(handle);
    s_bancada = 0;
    strncpy(s_site, MQTT_DEFAULT_SITE, sizeof(s_site) - 1);
    return err == ESP_OK;
}
