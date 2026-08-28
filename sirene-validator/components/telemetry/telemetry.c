#include "telemetry.h"

#include <stdio.h>

#include "board_config.h"
#include "device_id.h"
#include "esp_log.h"
#include "esp_task_wdt.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "mqtt_bridge.h"
#include "mqtt_topics.h"

static const char *TAG = "telemetry";
static bool (*s_provider)(telemetry_snapshot_t *out);

static void delay_with_wdt_reset(uint32_t total_ms)
{
    const uint32_t chunk_ms = 5000;
    while (total_ms > 0) {
        uint32_t step = total_ms > chunk_ms ? chunk_ms : total_ms;
        vTaskDelay(pdMS_TO_TICKS(step));
        esp_task_wdt_reset();
        total_ms -= step;
    }
}

static void publish_heartbeat(void)
{
    if (!mqtt_bridge_is_connected()) {
        return;
    }
    telemetry_snapshot_t snap = {
        .rssi = -127,
        .estado = "DESCONHECIDO",
        .wifi_ssid = "",
        .fila = 0,
        .firmware_version = FIRMWARE_VERSION,
        .numero_op = "",
        .proximo_sequencial = 0,
        .aprovados = 0,
        .batch_active = false,
        .queue_drops = 0,
        .pzem_faults = 0,
        .batch_nvs_fault = false,
        .reset_reason = 0,
        .time_synced = false,
        .pzem_addr = 0,
    };
    if (s_provider) {
        s_provider(&snap);
    }
    char last_test_json[160] = "";
    if (snap.last_test_valid && snap.ultimo_veredito != NULL && snap.ultimo_veredito[0] != '\0') {
        snprintf(last_test_json, sizeof(last_test_json),
                 ",\"ultimo_veredito\":\"%s\",\"ultima_potencia\":%.2f,"
                 "\"ultimo_sequencial\":%lu,\"ultimo_ts_ms\":%lld",
                 snap.ultimo_veredito, snap.ultima_potencia,
                 (unsigned long)snap.ultimo_sequencial, (long long)snap.ultimo_ts_ms);
    }
    char json[768];
    snprintf(json, sizeof(json),
             "{\"device_id\":\"%s\",\"site\":\"%s\",\"bancada\":%u,"
             "\"uptime\":%lld,\"ts_ms\":%lld,\"rssi\":%d,\"estado\":\"%s\",\"wifi_ssid\":\"%s\","
             "\"fila\":%u,\"fila_drops\":%lu,\"firmware_version\":\"%s\",\"protocol_version\":%u,\"numero_op\":\"%s\","
             "\"proximo_sequencial\":%lu,\"aprovados\":%lu,\"batch_nvs_fault\":%s,"
             "\"pzem_faults\":%lu,\"pzem_addr\":\"0x%02X\",\"reset_reason\":%d,\"time_synced\":%s%s}",
             device_id_get(),
             mqtt_topics_get_site(),
             (unsigned)mqtt_topics_get_bancada(),
             (long long)(esp_timer_get_time() / 1000000LL),
             (long long)(esp_timer_get_time() / 1000LL),
             snap.rssi, snap.estado, snap.wifi_ssid ? snap.wifi_ssid : "",
             (unsigned)snap.fila, (unsigned long)snap.queue_drops, snap.firmware_version,
             (unsigned)MQTT_PROTOCOL_VERSION,
             snap.batch_active ? snap.numero_op : "",
             (unsigned long)snap.proximo_sequencial, (unsigned long)snap.aprovados,
             snap.batch_nvs_fault ? "true" : "false",
             (unsigned long)snap.pzem_faults, snap.pzem_addr, snap.reset_reason,
             snap.time_synced ? "true" : "false", last_test_json);
    mqtt_bridge_publish("heartbeat", json);
}

static void heartbeat_task(void *arg)
{
    (void)arg;
    esp_task_wdt_add(NULL);
    while (true) {
        esp_task_wdt_reset();
        publish_heartbeat();
        delay_with_wdt_reset(HEARTBEAT_INTERVAL_SEC * 1000);
    }
}

bool telemetry_init(void)
{
    return true;
}

void telemetry_set_snapshot_provider(bool (*provider)(telemetry_snapshot_t *out))
{
    s_provider = provider;
}

void telemetry_publish_now(void)
{
    publish_heartbeat();
}

void telemetry_start(void)
{
    xTaskCreate(heartbeat_task, "telemetry", 4096, NULL, 4, NULL);
    ESP_LOGI(TAG, "heartbeat a cada %ds", HEARTBEAT_INTERVAL_SEC);
}
