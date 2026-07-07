#include "mqtt_bridge.h"

#include <stdio.h>
#include <string.h>

#include "board_config.h"
#include "device_id.h"
#include "mqtt_topics.h"
#include "esp_log.h"
#include "esp_random.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "freertos/task.h"
#include "mqtt_client.h"
#include "mqtt_config.h"
#include "sdkconfig.h"
#if CONFIG_MBEDTLS_CERTIFICATE_BUNDLE
#include "esp_crt_bundle.h"
#endif

static const char *TAG = "mqtt";
static esp_mqtt_client_handle_t s_client;
static mqtt_command_cb_t s_cmd_cb;
static mqtt_connected_cb_t s_connected_cb;
static volatile bool s_connected;
static char s_presenca_topic[96];
static char s_broker_uri[128];
static uint32_t s_reconnect_delay_ms = MQTT_RECONNECT_BASE_MS;
static volatile bool s_reconnect_scheduled;
static SemaphoreHandle_t s_pub_mu;

static void mqtt_reconnect_task(void *arg)
{
    (void)arg;
    s_reconnect_scheduled = false;
    uint32_t jitter = esp_random() % 500;
    vTaskDelay(pdMS_TO_TICKS(s_reconnect_delay_ms + jitter));
    if (s_client) {
        esp_mqtt_client_reconnect(s_client);
    }
    if (s_reconnect_delay_ms < MQTT_RECONNECT_MAX_MS) {
        s_reconnect_delay_ms *= 2;
        if (s_reconnect_delay_ms > MQTT_RECONNECT_MAX_MS) {
            s_reconnect_delay_ms = MQTT_RECONNECT_MAX_MS;
        }
    }
    vTaskDelete(NULL);
}

static void schedule_mqtt_reconnect(void)
{
    if (s_reconnect_scheduled) {
        return;
    }
    s_reconnect_scheduled = true;
    xTaskCreate(mqtt_reconnect_task, "mqtt_reconn", 3072, NULL, 4, NULL);
}

static void mqtt_event_handler(void *handler_args, esp_event_base_t base, int32_t event_id, void *event_data)
{
    (void)handler_args;
    (void)base;
    esp_mqtt_event_handle_t event = event_data;

    switch ((esp_mqtt_event_id_t)event_id) {
    case MQTT_EVENT_CONNECTED:
        s_connected = true;
        s_reconnect_scheduled = false;
        s_reconnect_delay_ms = MQTT_RECONNECT_BASE_MS;
        {
            char topic[96];
            if (!mqtt_topics_build(topic, sizeof(topic), "comando")) {
                ESP_LOGE(TAG, "topico comando nao configurado");
                break;
            }
            esp_mqtt_client_subscribe(s_client, topic, 1);
            esp_mqtt_client_publish(s_client, s_presenca_topic, "online", 0, 1, 1);
            ESP_LOGI(TAG, "conectado, inscrito em %s", topic);
        }
        if (s_connected_cb) {
            s_connected_cb();
        }
        break;
    case MQTT_EVENT_DISCONNECTED:
        s_connected = false;
        ESP_LOGW(TAG, "desconectado — reconexao em %lu ms", (unsigned long)s_reconnect_delay_ms);
        schedule_mqtt_reconnect();
        break;
    case MQTT_EVENT_DATA:
        if (s_cmd_cb) {
            s_cmd_cb(event->data, event->data_len);
        }
        break;
    default:
        break;
    }
}

bool mqtt_bridge_init(mqtt_command_cb_t cmd_cb, mqtt_connected_cb_t connected_cb)
{
    if (!s_pub_mu) {
        s_pub_mu = xSemaphoreCreateMutex();
    }
    s_cmd_cb = cmd_cb;
    s_connected_cb = connected_cb;
    if (!mqtt_topics_build(s_presenca_topic, sizeof(s_presenca_topic), "presenca")) {
        ESP_LOGE(TAG, "station_cfg ausente — configure bancada no portal");
        return false;
    }

    bool from_nvs = mqtt_config_get_uri(s_broker_uri, sizeof(s_broker_uri));
    char mqtt_user[65] = {0};
    char mqtt_pass[65] = {0};
    bool has_auth = mqtt_config_load_auth(mqtt_user, sizeof(mqtt_user), mqtt_pass, sizeof(mqtt_pass));
    bool mqtt_tls = false;
    mqtt_config_load_tls(&mqtt_tls);
    bool tls_transport = mqtt_tls || strncmp(s_broker_uri, "mqtts://", 8) == 0 ||
                           strncmp(s_broker_uri, "wss://", 6) == 0;
    ESP_LOGI(TAG, "broker %s (%s)%s%s", s_broker_uri, from_nvs ? "NVS" : "fallback",
             has_auth ? ", auth" : "", tls_transport ? ", tls" : "");

    esp_mqtt_client_config_t cfg = {
        .broker.address.uri = s_broker_uri,
        .session.last_will.topic = s_presenca_topic,
        .session.last_will.msg = "offline",
        .session.last_will.qos = 1,
        .session.last_will.retain = true,
        .network.disable_auto_reconnect = true,
        .network.reconnect_timeout_ms = MQTT_RECONNECT_BASE_MS,
    };
    if (has_auth) {
        cfg.credentials.username = mqtt_user;
        cfg.credentials.authentication.password = mqtt_pass;
    }
    if (tls_transport) {
        bool private_broker = mqtt_config_broker_is_private_lan();
#if CONFIG_MBEDTLS_CERTIFICATE_BUNDLE
        cfg.broker.verification.crt_bundle_attach = esp_crt_bundle_attach;
#endif
        if (private_broker) {
            cfg.broker.verification.skip_cert_common_name_check = true;
#if CONFIG_SIRENE_MQTT_LAN_INSECURE_TLS && CONFIG_ESP_TLS_SKIP_SERVER_CERT_VERIFY
            ESP_LOGW(TAG, "MQTT TLS broker LAN — verificacao relaxada (perfil LAN)");
#elif CONFIG_SIRENE_MQTT_LAN_INSECURE_TLS
            ESP_LOGW(TAG, "MQTT TLS broker LAN — use sdkconfig.defaults.lan para cert autoassinado");
#endif
        } else {
            ESP_LOGI(TAG, "MQTT WSS/TLS — CA publica (crt bundle)");
        }
    }
    s_client = esp_mqtt_client_init(&cfg);
    if (!s_client) {
        return false;
    }
    esp_mqtt_client_register_event(s_client, ESP_EVENT_ANY_ID, mqtt_event_handler, NULL);
    return esp_mqtt_client_start(s_client) == ESP_OK;
}

bool mqtt_bridge_is_connected(void)
{
    return s_connected;
}

bool mqtt_bridge_publish(const char *topic_suffix, const char *json)
{
    if (!s_client || !s_connected) {
        return false;
    }
    char topic[96];
    if (!mqtt_topics_build(topic, sizeof(topic), topic_suffix)) {
        return false;
    }
    if (s_pub_mu) {
        xSemaphoreTake(s_pub_mu, portMAX_DELAY);
    }
    int msg_id = esp_mqtt_client_publish(s_client, topic, json, 0, 1, 0);
    if (s_pub_mu) {
        xSemaphoreGive(s_pub_mu);
    }
    return msg_id >= 0;
}

bool mqtt_bridge_publish_status(const char *json)
{
    return mqtt_bridge_publish("status", json);
}

bool mqtt_bridge_publish_alerta(const char *json)
{
    return mqtt_bridge_publish("alerta", json);
}

bool mqtt_bridge_publish_calibracao(const char *json)
{
    return mqtt_bridge_publish("calibracao", json);
}

bool mqtt_bridge_publish_rejection(const char *reason)
{
    char json[256];
    snprintf(json, sizeof(json), "{\"tipo\":\"rejeicao\",\"motivo\":\"%s\"}", reason);
    return mqtt_bridge_publish_status(json);
}
