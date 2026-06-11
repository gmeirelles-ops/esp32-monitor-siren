#pragma once

#include <stdbool.h>
#include <stddef.h>

bool wifi_prov_has_credentials(void);
bool wifi_prov_load_credentials(char *ssid, size_t ssid_len, char *pass, size_t pass_len);
bool wifi_prov_save_credentials(const char *ssid, const char *pass);
void wifi_prov_start_softap_portal(void);
bool wifi_prov_connect_sta(void);
int wifi_prov_get_rssi(void);
