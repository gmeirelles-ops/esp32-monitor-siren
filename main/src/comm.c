/**
 * @file comm.c
 * @brief Wi-Fi STA, MQTT e Firebase RTDB centralizados.
 */

#include "comm.h"

#include <stdio.h>
#include <string.h>

#include "cJSON.h"
#include "esp_event.h"
#include "esp_http_client.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "esp_wifi.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "freertos/task.h"
#include "mqtt_client.h"
#include "nvs_flash.h"

/* Credenciais mock – substituir por NVS ou menuconfig em produção */
#define WIFI_SSID           "SUA_REDE_WIFI"
#define WIFI_PASS           "SUA_SENHA_WIFI"
#define WIFI_MAX_RETRY      5

#define MQTT_BROKER_URI     "mqtt://broker.hivemq.com:1883"
#define MQTT_TOPIC_POWER    "diponto/bancada/potencia"

#define FIREBASE_URL \
    "https://sistema-sirenes-qa-default-rtdb.firebaseio.com/teste_atual.json"

#define FIREBASE_DEFAULT_SEC  5
#define HTTP_BUF_SIZE           1024
#define WIFI_CONNECTED_BIT      BIT0

static const char *TAG = "comm";

static EventGroupHandle_t s_wifi_events;
static esp_mqtt_client_handle_t s_mqtt_client;
static bool s_mqtt_connected;

/* -------------------------------------------------------------------------- */
/* Wi-Fi                                                                      */
/* -------------------------------------------------------------------------- */

static void wifi_event_handler(void *arg, esp_event_base_t base,
                               int32_t event_id, void *event_data)
{
    (void)arg;
    (void)event_data;

    if (base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        xEventGroupClearBits(s_wifi_events, WIFI_CONNECTED_BIT);
        ESP_LOGW(TAG, "Wi-Fi desconectado – reconectando…");
        esp_wifi_connect();
    } else if (base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        xEventGroupSetBits(s_wifi_events, WIFI_CONNECTED_BIT);
        ESP_LOGI(TAG, "Wi-Fi conectado (IP obtido)");
    }
}

static esp_err_t wifi_init_sta(void)
{
    s_wifi_events = xEventGroupCreate();

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID,
                                               &wifi_event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP,
                                               &wifi_event_handler, NULL));

    wifi_config_t wifi_cfg = {0};
    strncpy((char *)wifi_cfg.sta.ssid, WIFI_SSID, sizeof(wifi_cfg.sta.ssid) - 1);
    strncpy((char *)wifi_cfg.sta.password, WIFI_PASS, sizeof(wifi_cfg.sta.password) - 1);
    wifi_cfg.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_cfg));
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "Wi-Fi STA iniciado – SSID mock: %s", WIFI_SSID);

    const EventBits_t bits = xEventGroupWaitBits(s_wifi_events, WIFI_CONNECTED_BIT,
                                                 pdFALSE, pdTRUE,
                                                 pdMS_TO_TICKS(15000));
    if ((bits & WIFI_CONNECTED_BIT) == 0) {
        ESP_LOGE(TAG, "Timeout aguardando Wi-Fi");
        return ESP_ERR_TIMEOUT;
    }
    return ESP_OK;
}

/* -------------------------------------------------------------------------- */
/* MQTT                                                                       */
/* -------------------------------------------------------------------------- */

static void mqtt_event_handler(void *handler_args, esp_event_base_t base,
                               int32_t event_id, void *event_data)
{
    (void)handler_args;
    (void)base;
    esp_mqtt_event_handle_t event = (esp_mqtt_event_handle_t)event_data;

    switch ((esp_mqtt_event_id_t)event_id) {
    case MQTT_EVENT_CONNECTED:
        s_mqtt_connected = true;
        ESP_LOGI(TAG, "MQTT conectado ao broker");
        break;
    case MQTT_EVENT_DISCONNECTED:
        s_mqtt_connected = false;
        ESP_LOGW(TAG, "MQTT desconectado");
        break;
    case MQTT_EVENT_ERROR:
        ESP_LOGE(TAG, "MQTT erro");
        break;
    default:
        break;
    }
}

static esp_err_t mqtt_init_client(void)
{
    const esp_mqtt_client_config_t cfg = {
        .broker.address.uri = MQTT_BROKER_URI,
    };

    s_mqtt_client = esp_mqtt_client_init(&cfg);
    if (s_mqtt_client == NULL) {
        return ESP_FAIL;
    }

    esp_mqtt_client_register_event(s_mqtt_client, ESP_EVENT_ANY_ID,
                                   mqtt_event_handler, NULL);
    ESP_ERROR_CHECK(esp_mqtt_client_start(s_mqtt_client));

    for (int i = 0; i < 50 && !s_mqtt_connected; i++) {
        vTaskDelay(pdMS_TO_TICKS(100));
    }

    if (!s_mqtt_connected) {
        ESP_LOGW(TAG, "MQTT ainda não conectado – publicações podem falhar");
    }
    return ESP_OK;
}

void mqtt_publish_power(float power)
{
    if (s_mqtt_client == NULL) {
        ESP_LOGW(TAG, "MQTT não inicializado");
        return;
    }

    char payload[32];
    snprintf(payload, sizeof(payload), "%.2f", power);

    const int msg_id = esp_mqtt_client_publish(s_mqtt_client, MQTT_TOPIC_POWER,
                                               payload, 0, 1, 0);
    if (msg_id < 0) {
        ESP_LOGW(TAG, "MQTT publish falhou (potência=%.2f)", power);
    } else {
        ESP_LOGD(TAG, "MQTT %s → %.2f W", MQTT_TOPIC_POWER, power);
    }
}

/* -------------------------------------------------------------------------- */
/* Firebase HTTP                                                              */
/* -------------------------------------------------------------------------- */

typedef struct {
    char   buffer[HTTP_BUF_SIZE];
    int    length;
} http_buf_t;

static esp_err_t http_collect(esp_http_client_event_t *evt)
{
    http_buf_t *buf = (http_buf_t *)evt->user_data;
    if (buf == NULL || evt->event_id != HTTP_EVENT_ON_DATA) {
        return ESP_OK;
    }

    if (buf->length + evt->data_len >= (int)sizeof(buf->buffer) - 1) {
        return ESP_OK;
    }

    memcpy(buf->buffer + buf->length, evt->data, evt->data_len);
    buf->length += evt->data_len;
    buf->buffer[buf->length] = '\0';
    return ESP_OK;
}

static esp_err_t firebase_http(esp_http_client_method_t method, const char *body,
                              http_buf_t *resp_out)
{
    http_buf_t local = {0};
    http_buf_t *resp = resp_out != NULL ? resp_out : &local;

    const esp_http_client_config_t cfg = {
        .url           = FIREBASE_URL,
        .method        = method,
        .timeout_ms    = 10000,
        .event_handler = http_collect,
        .user_data     = resp,
    };

    esp_http_client_handle_t client = esp_http_client_init(&cfg);
    if (client == NULL) {
        return ESP_FAIL;
    }

    esp_http_client_set_header(client, "Content-Type", "application/json");
    if (body != NULL) {
        esp_http_client_set_post_field(client, body, (int)strlen(body));
    }

    esp_err_t err = esp_http_client_perform(client);
    const int status = esp_http_client_get_status_code(client);

    if (err == ESP_OK && (status < 200 || status >= 300)) {
        ESP_LOGE(TAG, "Firebase HTTP %d", status);
        err = ESP_FAIL;
    }

    esp_http_client_cleanup(client);
    return err;
}

int firebase_get_test_time(void)
{
    http_buf_t resp = {0};

    if (firebase_http(HTTP_METHOD_GET, NULL, &resp) != ESP_OK) {
        ESP_LOGE(TAG, "GET Firebase falhou");
        return -1;
    }

    ESP_LOGI(TAG, "Firebase GET: %s", resp.buffer);

    cJSON *root = cJSON_Parse(resp.buffer);
    if (root == NULL) {
        ESP_LOGE(TAG, "JSON inválido no GET");
        return -1;
    }

    int tempo = FIREBASE_DEFAULT_SEC;
    const cJSON *item = cJSON_GetObjectItem(root, "tempo_teste");
    if (cJSON_IsNumber(item) && item->valuedouble > 0) {
        tempo = (int)item->valuedouble;
    } else {
        ESP_LOGW(TAG, "tempo_teste ausente – fallback %d s", FIREBASE_DEFAULT_SEC);
    }

    cJSON_Delete(root);
    ESP_LOGI(TAG, "tempo_teste=%d s", tempo);
    return tempo;
}

void firebase_send_result(float max_power_read)
{
    char body[128];
    snprintf(body, sizeof(body),
             "{\"status\":\"CONCLUIDO\",\"potencia_lida\":%.2f}", max_power_read);

    if (firebase_http(HTTP_METHOD_PATCH, body, NULL) == ESP_OK) {
        ESP_LOGI(TAG, "Firebase PATCH OK – pico %.2f W", max_power_read);
    } else {
        ESP_LOGE(TAG, "Firebase PATCH falhou");
    }
}

/* -------------------------------------------------------------------------- */
/* API pública                                                                */
/* -------------------------------------------------------------------------- */

void comm_init(void)
{
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ESP_ERROR_CHECK(nvs_flash_init());
    }

    if (wifi_init_sta() != ESP_OK) {
        ESP_LOGE(TAG, "Wi-Fi não conectou – HTTP/MQTT limitados");
    }

    if (mqtt_init_client() != ESP_OK) {
        ESP_LOGE(TAG, "MQTT init falhou");
    }

    ESP_LOGI(TAG, "comm_init concluído");
}
