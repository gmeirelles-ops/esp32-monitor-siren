#include "ota_update.h"

#include <stdio.h>
#include <string.h>

#include "esp_https_ota.h"
#include "esp_log.h"
#include "esp_ota_ops.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "relay.h"

static const char *TAG = "ota";
static ota_status_cb_t s_status_cb;
static volatile bool s_active;

static void publish_status(const char *tipo, const char *detail)
{
    if (!s_status_cb) {
        return;
    }
    char json[256];
    snprintf(json, sizeof(json), "{\"tipo\":\"ota\",\"evento\":\"%s\",\"detalhe\":\"%s\"}", tipo, detail);
    s_status_cb(json);
}

static void ota_task(void *arg)
{
    char *url = (char *)arg;
    s_active = true;
    relay_set(false);
    publish_status("inicio", url);

    esp_http_client_config_t http_cfg = {
        .url = url,
        .timeout_ms = 30000,
        .keep_alive_enable = true,
    };
    esp_https_ota_config_t ota_cfg = {
        .http_config = &http_cfg,
    };

    esp_err_t err = esp_https_ota(&ota_cfg);
    free(url);

    if (err == ESP_OK) {
        publish_status("sucesso", "reiniciando");
        vTaskDelay(pdMS_TO_TICKS(500));
        esp_restart();
    } else {
        ESP_LOGE(TAG, "OTA falhou: %s", esp_err_to_name(err));
        publish_status("falha", esp_err_to_name(err));
        s_active = false;
    }
    vTaskDelete(NULL);
}

bool ota_update_init(ota_status_cb_t status_cb)
{
    s_status_cb = status_cb;
    s_active = false;
    return true;
}

bool ota_update_mark_valid_on_boot(void)
{
    const esp_partition_t *running = esp_ota_get_running_partition();
    esp_ota_img_states_t state;
    if (esp_ota_get_state_partition(running, &state) != ESP_OK) {
        return true;
    }
    if (state == ESP_OTA_IMG_PENDING_VERIFY) {
        ESP_LOGI(TAG, "confirmando imagem OTA");
        return esp_ota_mark_app_valid_cancel_rollback() == ESP_OK;
    }
    return true;
}

bool ota_update_start(const char *url)
{
    if (!url || url[0] == '\0' || s_active) {
        return false;
    }
    char *url_copy = strdup(url);
    if (!url_copy) {
        return false;
    }
    if (xTaskCreate(ota_task, "ota_task", 8192, url_copy, 5, NULL) != pdPASS) {
        free(url_copy);
        return false;
    }
    return true;
}

bool ota_update_is_active(void)
{
    return s_active;
}
