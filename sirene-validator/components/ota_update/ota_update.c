#include "ota_update.h"

#include <stdio.h>
#include <string.h>

#include "esp_https_ota.h"
#include "esp_log.h"
#include "esp_ota_ops.h"
#include "esp_partition.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "nvs_flash.h"
#include "relay.h"
#include "sdkconfig.h"

static const char *TAG = "ota";
static ota_status_cb_t s_status_cb;
static ota_smoke_test_fn_t s_smoke_test;
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
        .timeout_ms = 120000,
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
        char detail[96];
        if (err == ESP_ERR_INVALID_ARG) {
            snprintf(detail, sizeof(detail),
                     "ESP_ERR_INVALID_ARG (HTTP OTA desabilitado no firmware — grave 1.4.5+ por USB)");
        } else if (err == ESP_FAIL) {
            snprintf(detail, sizeof(detail),
                     "ESP_FAIL (servidor inacessivel, 404 ou firewall em :8080)");
        } else {
            snprintf(detail, sizeof(detail), "%s", esp_err_to_name(err));
        }
        ESP_LOGE(TAG, "OTA falhou: %s", detail);
        publish_status("falha", detail);
        s_active = false;
    }
    vTaskDelete(NULL);
}

bool ota_update_init(ota_status_cb_t status_cb)
{
    s_status_cb = status_cb;
    s_smoke_test = NULL;
    s_active = false;
    return true;
}

void ota_update_set_smoke_test(ota_smoke_test_fn_t fn)
{
    s_smoke_test = fn;
}

static bool ota_image_pending_verify(void)
{
    const esp_partition_t *running = esp_ota_get_running_partition();
    if (!running) {
        return false;
    }
    esp_ota_img_states_t state;
    if (esp_ota_get_state_partition(running, &state) != ESP_OK) {
        return false;
    }
    return state == ESP_OTA_IMG_PENDING_VERIFY;
}

bool ota_update_erase_factory_data_if_pending(void)
{
#if !CONFIG_OTA_ERASE_NVS_ON_BOOT
    return false;
#else
    if (!ota_image_pending_verify()) {
        return false;
    }

    ESP_LOGW(TAG, "OTA concluido — apagando NVS e storage (reprovisionamento)");

    esp_err_t err = nvs_flash_deinit();
    if (err != ESP_OK && err != ESP_ERR_NVS_NOT_INITIALIZED) {
        ESP_LOGE(TAG, "nvs_flash_deinit: %s", esp_err_to_name(err));
        return false;
    }

    err = nvs_flash_erase_partition("nvs");
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "nvs_flash_erase_partition(nvs): %s", esp_err_to_name(err));
        ESP_ERROR_CHECK(nvs_flash_init());
        return false;
    }

    const esp_partition_t *storage =
        esp_partition_find_first(ESP_PARTITION_TYPE_DATA, ESP_PARTITION_SUBTYPE_DATA_SPIFFS, "storage");
    if (storage) {
        err = esp_partition_erase_range(storage, 0, storage->size);
        if (err != ESP_OK) {
            ESP_LOGE(TAG, "esp_partition_erase_range(storage): %s", esp_err_to_name(err));
        }
    }

    ESP_ERROR_CHECK(nvs_flash_init());
    ESP_LOGI(TAG, "dados de fabrica apagados — aguardando provisionamento Wi-Fi");
    return true;
#endif
}

bool ota_update_mark_valid_on_boot(void)
{
    const esp_partition_t *running = esp_ota_get_running_partition();
    esp_ota_img_states_t state;
    if (esp_ota_get_state_partition(running, &state) != ESP_OK) {
        return true;
    }
    if (state == ESP_OTA_IMG_PENDING_VERIFY) {
        if (s_smoke_test && !s_smoke_test()) {
            ESP_LOGE(TAG, "smoke test falhou — rollback OTA");
            esp_ota_mark_app_invalid_rollback_and_reboot();
            return false;
        }
        ESP_LOGI(TAG, "smoke test OK — confirmando imagem OTA");
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
