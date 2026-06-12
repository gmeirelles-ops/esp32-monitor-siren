#include "telemetry.h"

#include <stdio.h>

#include "board_config.h"
#include "esp_log.h"
#include "esp_task_wdt.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "mqtt_bridge.h"

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
        .fila = 0,
        .firmware_version = FIRMWARE_VERSION,
        .numero_op = "",
        .proximo_sequencial = 0,
        .aprovados = 0,
        .batch_active = false,
    };
    if (s_provider) {
        s_provider(&snap);
    }
    char json[384];
    snprintf(json, sizeof(json),
             "{\"uptime\":%lld,\"rssi\":%d,\"estado\":\"%s\",\"fila\":%u,"
             "\"firmware_version\":\"%s\",\"numero_op\":\"%s\","
             "\"proximo_sequencial\":%lu,\"aprovados\":%lu}",
             (long long)(esp_timer_get_time() / 1000000LL),
             snap.rssi, snap.estado, (unsigned)snap.fila, snap.firmware_version,
             snap.batch_active ? snap.numero_op : "",
             (unsigned long)snap.proximo_sequencial, (unsigned long)snap.aprovados);
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
