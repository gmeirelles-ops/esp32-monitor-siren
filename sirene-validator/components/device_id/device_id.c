#include "device_id.h"

#include <stdio.h>
#include <string.h>

#include "esp_mac.h"

static char s_device_id[13];

void device_id_init(void)
{
    uint8_t mac[6];
    esp_read_mac(mac, ESP_MAC_WIFI_STA);
    snprintf(s_device_id, sizeof(s_device_id), "%02x%02x%02x%02x%02x%02x",
             mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
}

const char *device_id_get(void)
{
    return s_device_id;
}

void device_id_topic(char *buf, size_t buflen, const char *suffix)
{
    snprintf(buf, buflen, "sirene/%s/%s", s_device_id, suffix);
}
