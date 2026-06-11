#include "mqtt_bridge.h"

#include <stdio.h>
#include <string.h>

#include "board_config.h"
#include "device_id.h"
#include "esp_log.h"
#include "esp_random.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "mqtt_client.h"
#include "mqtt_config.h"

static const char *TAG = "mqtt";
static esp_mqtt_client_handle_t s_client;
static mqtt_command_cb_t s_cmd_cb;
static mqtt_connected_cb_t s_connected_cb;
static bool s_connected;
static char s_presenca_topic[64];
static char s_broker_uri[128];
static uint32_t s_reconnect_delay_ms = MQTT_RECONNECT_BASE_MS;

static void mqtt_reconnect_task(void *arg)
{
    (void)arg;
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
        s_reconnect_delay_ms = MQTT_RECONNECT_BASE_MS;
        {
            char topic[64];
            device_id_topic(topic, sizeof(topic), "comando");
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
    s_cmd_cb = cmd_cb;
    s_connected_cb = connected_cb;
    device_id_topic(s_presenca_topic, sizeof(s_presenca_topic), "presenca");

    bool from_nvs = mqtt_config_get_uri(s_broker_uri, sizeof(s_broker_uri));
    ESP_LOGI(TAG, "broker %s (%s)", s_broker_uri, from_nvs ? "NVS" : "fallback");

    esp_mqtt_client_config_t cfg = {
        .broker.address.uri = s_broker_uri,
        .session.last_will.topic = s_presenca_topic,
        .session.last_will.msg = "offline",
        .session.last_will.qos = 1,
        .session.last_will.retain = true,
        .network.disable_auto_reconnect = true,
        .network.reconnect_timeout_ms = MQTT_RECONNECT_BASE_MS,
    };
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
    char topic[64];
    device_id_topic(topic, sizeof(topic), topic_suffix);
    int msg_id = esp_mqtt_client_publish(s_client, topic, json, 0, 1, 0);
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
