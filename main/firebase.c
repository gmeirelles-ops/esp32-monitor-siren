/**
 * @file firebase.c
 */

#include "firebase.h"

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

#include "esp_http_client.h"
#include "esp_log.h"
#include "esp_wifi.h"

#include "wifi_manager.h"

/* Substituir pela URL e token reais */
#define FIREBASE_PATCH_URL \
    "https://projeto-ficticio-default-rtdb.firebaseio.com/teste_atual.json?auth=TOKEN_FICTICIO"

static const char *TAG = "firebase";

static esp_err_t firebase_patch_json(const char *json_body)
{
    if (!wifi_manager_is_connected()) {
        ESP_LOGW(TAG, "Wi-Fi offline – PATCH ignorado");
        return ESP_ERR_WIFI_NOT_CONNECT;
    }

    const esp_http_client_config_t cfg = {
        .url        = FIREBASE_PATCH_URL,
        .method     = HTTP_METHOD_PATCH,
        .timeout_ms = 10000,
    };

    esp_http_client_handle_t client = esp_http_client_init(&cfg);
    if (client == NULL) {
        return ESP_FAIL;
    }

    esp_http_client_set_header(client, "Content-Type", "application/json");
    esp_http_client_set_post_field(client, json_body, (int)strlen(json_body));

    esp_err_t err = esp_http_client_perform(client);
    if (err == ESP_OK) {
        const int status = esp_http_client_get_status_code(client);
        ESP_LOGI(TAG, "PATCH HTTP %d", status);
        if (status < 200 || status >= 300) {
            err = ESP_FAIL;
        }
    } else {
        ESP_LOGE(TAG, "PATCH erro: %s", esp_err_to_name(err));
    }

    esp_http_client_cleanup(client);
    return err;
}

esp_err_t firebase_patch_aguardando(void)
{
    return firebase_patch_json(
        "{\"status\":\"AGUARDANDO_BOTAO\",\"corrente_lida\":0,\"potencia_lida\":0}");
}

esp_err_t firebase_patch_concluido(uint32_t corrente_raw, uint32_t potencia_raw)
{
    char body[192];
    snprintf(body, sizeof(body),
             "{\"status\":\"CONCLUIDO\",\"corrente_lida\":%" PRIu32
             ",\"potencia_lida\":%" PRIu32 "}",
             corrente_raw, potencia_raw);
    return firebase_patch_json(body);
}

esp_err_t firebase_patch_erro_sensor(void)
{
    return firebase_patch_json(
        "{\"status\":\"ERRO_SENSOR\",\"corrente_lida\":0,\"potencia_lida\":0}");
}
