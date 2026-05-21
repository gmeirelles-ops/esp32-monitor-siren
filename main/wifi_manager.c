/**
 * @file wifi_manager.c
 */

#include "wifi_manager.h"

#include <string.h>

#include "esp_event.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "esp_wifi.h"
#include "freertos/task.h"

/* Substituir pelos valores reais do ambiente */
#define WIFI_SSID  "SUA_REDE_WIFI"
#define WIFI_PASS  "SUA_SENHA_WIFI"

static const char *TAG = "wifi_mgr";

static EventGroupHandle_t s_event_group;
static bool s_connected;

static void wifi_event_handler(void *arg, esp_event_base_t event_base,
                               int32_t event_id, void *event_data)
{
    (void)arg;

    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        s_connected = false;
        xEventGroupClearBits(s_event_group, WIFI_MANAGER_CONNECTED_BIT);
        ESP_LOGW(TAG, "desconectado – reconectando");
        esp_wifi_connect();
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        const ip_event_got_ip_t *event = (const ip_event_got_ip_t *)event_data;
        ESP_LOGI(TAG, "IP: " IPSTR, IP2STR(&event->ip_info.ip));
        s_connected = true;
        xEventGroupSetBits(s_event_group, WIFI_MANAGER_CONNECTED_BIT);
    }
}

esp_err_t wifi_manager_init(void)
{
    s_event_group = xEventGroupCreate();
    if (s_event_group == NULL) {
        return ESP_ERR_NO_MEM;
    }

    s_connected = false;

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_sta();

    const wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    esp_event_handler_instance_t instance_any_id;
    esp_event_handler_instance_t instance_got_ip;
    ESP_ERROR_CHECK(esp_event_handler_instance_register(
        WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL, &instance_any_id));
    ESP_ERROR_CHECK(esp_event_handler_instance_register(
        IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_event_handler, NULL, &instance_got_ip));

    wifi_config_t wifi_config = {0};
    strncpy((char *)wifi_config.sta.ssid, WIFI_SSID, sizeof(wifi_config.sta.ssid) - 1);
    strncpy((char *)wifi_config.sta.password, WIFI_PASS, sizeof(wifi_config.sta.password) - 1);
    wifi_config.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "STA iniciado – SSID: %s", WIFI_SSID);
    return ESP_OK;
}

bool wifi_manager_is_connected(void)
{
    return s_connected;
}

EventGroupHandle_t wifi_manager_get_event_group(void)
{
    return s_event_group;
}

void wifi_manager_task(void *pv_parameters)
{
    (void)pv_parameters;

    ESP_LOGI(TAG, "Task_WiFi no core %d", xPortGetCoreID());

    for (;;) {
        if (!s_connected) {
            xEventGroupWaitBits(s_event_group, WIFI_MANAGER_CONNECTED_BIT,
                                pdFALSE, pdTRUE, pdMS_TO_TICKS(5000));
        }
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
