#include <stdio.h>
#include <string.h>

#include "app_runtime.h"
#include "batch_cmd.h"
#include "board_config.h"
#include "button.h"
#include "calibration.h"
#include "device_id.h"
#include "ensaio.h"
#include "esp_log.h"
#include "esp_system.h"
#include "esp_task_wdt.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/semphr.h"
#include "freertos/task.h"
#include "led_feedback.h"
#include "mqtt_bridge.h"
#include "mqtt_cmd.h"
#include "mqtt_topics.h"
#include "nvs_flash.h"
#include "offline_queue.h"
#include "oled_display.h"
#include "ota_update.h"
#include "pzem.h"
#include "relay.h"
#include "sdkconfig.h"
#include "state_machine.h"
#include "telemetry.h"
#include "time_sync.h"
#include "wifi_prov.h"

static const char *TAG = "main";
static SemaphoreHandle_t s_batch_mu;
static QueueHandle_t s_work_queue;
static QueueHandle_t s_button_queue;
static QueueHandle_t s_pzem_queue;
static int64_t s_last_button_press_us;

static void publish_hardware_fault_boot(const char *falha)
{
    char alerta[128];
    snprintf(alerta, sizeof(alerta), "{\"tipo\":\"hardware\",\"falha\":\"%s\"}", falha);
    app_publish_or_queue("alerta", alerta);
}

static bool mqtt_publish_wrapper(const char *topic_suffix, const char *json)
{
    return mqtt_bridge_publish(topic_suffix, json);
}

static void on_mqtt_connected(void)
{
    telemetry_publish_now();
    offline_queue_sync_now();
    oled_display_refresh();
}

static bool telemetry_snapshot(telemetry_snapshot_t *out)
{
    static char s_wifi_ssid[33];
    batch_context_t *batch = app_batch();
    out->rssi = wifi_prov_get_rssi();
    out->estado = state_machine_name(state_machine_get());
    if (wifi_prov_get_ssid(s_wifi_ssid, sizeof(s_wifi_ssid))) {
        out->wifi_ssid = s_wifi_ssid;
    } else {
        out->wifi_ssid = "";
    }
    out->fila = offline_queue_count();
    out->queue_drops = offline_queue_drop_count();
    out->firmware_version = FIRMWARE_VERSION;
    out->pzem_faults = pzem_get_fault_count();
    out->pzem_addr = pzem_get_slave_addr();
    out->reset_reason = (int)esp_reset_reason();
    out->time_synced = time_sync_ready();

    app_batch_lock();
    out->batch_nvs_fault = *app_batch_nvs_fault();
    out->batch_active = batch->active;
    if (batch->active) {
        out->numero_op = batch->numero_op;
        out->proximo_sequencial = batch->proximo_sequencial;
        out->aprovados = batch->aprovados;
    } else {
        out->numero_op = "";
        out->proximo_sequencial = 0;
        out->aprovados = 0;
    }
    app_batch_unlock();
    return true;
}

static bool ota_post_boot_smoke(void)
{
#if CONFIG_DEV_MOCK_PZEM
    return true;
#else
    if (relay_is_on()) {
        ESP_LOGE(TAG, "OTA smoke: rele ligado");
        relay_set(false);
        return false;
    }
    if (!mqtt_topics_is_configured()) {
        ESP_LOGE(TAG, "OTA smoke: bancada nao configurada");
        return false;
    }
    batch_context_t probe_batch;
    if (!batch_storage_load(&probe_batch)) {
        memset(&probe_batch, 0, sizeof(probe_batch));
    }
    float power = 0;
    for (int i = 0; i < 3; i++) {
        if (pzem_probe_read(&power)) {
            ESP_LOGI(TAG, "OTA smoke test OK: PZEM=%.1f W rele=OFF", power);
            return true;
        }
        vTaskDelay(pdMS_TO_TICKS(100));
    }
    ESP_LOGE(TAG, "OTA smoke test PZEM falhou");
    return false;
#endif
}

static void on_pzem_fault(bool fault)
{
    if (!fault) {
        return;
    }
    app_state_t restore = state_machine_get();
    if (restore == STATE_TESTING) {
        restore = app_batch()->active ? STATE_BATCH_READY : STATE_IDLE;
    }
    hardware_fault_enter(restore, "pzem_uart");
    relay_set(false);
}

static void on_ota_status(const char *json)
{
    app_publish_or_queue("status", json);
    if (strstr(json, "\"evento\":\"falha\"") != NULL) {
        app_state_t restore = batch_storage_has_active() ? STATE_BATCH_READY : STATE_IDLE;
        state_machine_set(restore);
        ESP_LOGW(TAG, "OTA falhou — estado restaurado para %s", state_machine_name(restore));
    }
}

static void pzem_worker_task(void *arg)
{
    (void)arg;
    esp_task_wdt_add(NULL);
    pzem_work_item_t item;
    while (true) {
        esp_task_wdt_reset();
        if (xQueueReceive(app_pzem_queue(), &item, pdMS_TO_TICKS(500)) != pdTRUE) {
            continue;
        }
        if (item.type == PZEM_WORK_TEST) {
            batch_cmd_run_test_cycle(item.duration_sec);
        } else if (item.type == PZEM_WORK_CALIBRATION) {
            calibration_handle_start();
        } else if (item.type == PZEM_WORK_ENSAIO) {
            ensaio_handle_start(item.ensaio);
        } else if (item.type == PZEM_WORK_PROBE) {
            float power = 0;
            bool ok = pzem_probe_read(&power);
            char json[128];
            snprintf(json, sizeof(json),
                     "{\"tipo\":\"pzem\",\"evento\":\"probe\",\"potencia_w\":%.2f,\"uart_ok\":%s}",
                     power, ok ? "true" : "false");
            app_publish_or_queue("status", json);
        }
        *app_pzem_busy() = false;
    }
}

static void worker_task(void *arg)
{
    (void)arg;
    esp_task_wdt_add(NULL);
    work_item_t item;
    while (true) {
        esp_task_wdt_reset();
        uint8_t btn_ev;
        if (xQueueReceive(s_button_queue, &btn_ev, 0) == pdTRUE) {
            if (*app_ensaio_running()) {
                ESP_LOGI(TAG, "botao — parar ensaio");
                *app_ensaio_stop() = true;
            } else if (!*app_calibrating()) {
                int64_t now = esp_timer_get_time();
                if (s_last_button_press_us > 0 &&
                    (now - s_last_button_press_us) < 800000LL &&
                    state_machine_get() == STATE_BATCH_READY) {
                    ESP_LOGI(TAG, "duplo toque — cancelar lote");
                    batch_cmd_end_batch_with_reason("botao_duplo");
                    s_last_button_press_us = 0;
                } else {
                    s_last_button_press_us = now;
                    uint32_t duration;
                    app_batch_lock();
                    duration = app_batch()->tempo_teste_sec;
                    app_batch_unlock();
                    app_enqueue_pzem_work(PZEM_WORK_TEST, duration, NULL);
                }
            }
        }
        if (xQueueReceive(app_work_queue(), &item, pdMS_TO_TICKS(500)) != pdTRUE) {
            continue;
        }
        if (item.type == WORK_MQTT_PAYLOAD) {
            mqtt_cmd_process_payload(item.payload);
        }
    }
}

static void hardware_monitor_task(void *arg)
{
    (void)arg;
    esp_task_wdt_add(NULL);
    uint32_t button_hold_ms = 0;
    int64_t last_pzem_recover_us = 0;
    while (true) {
        esp_task_wdt_reset();
        if (state_machine_get() == STATE_HARDWARE_FAULT) {
            int64_t now = esp_timer_get_time();
            if (now - last_pzem_recover_us >= 5000000LL) {
                last_pzem_recover_us = now;
                pzem_clear_fault();
                if (!pzem_is_fault()) {
                    app_state_t restore = *app_state_before_fault();
                    if (restore == STATE_TESTING) {
                        restore = batch_storage_has_active() ? STATE_BATCH_READY : STATE_IDLE;
                    }
                    state_machine_set(restore);
                    app_publish_or_queue("alerta", "{\"tipo\":\"hardware\",\"evento\":\"recuperado\"}");
                }
            }
        }

        if (!button_is_test_in_progress() && state_machine_get() != STATE_TESTING && !*app_calibrating() &&
            !*app_ensaio_running() &&
            !ota_update_is_active() && state_machine_get() != STATE_OTA_UPDATING &&
            button_is_pressed()) {
            button_hold_ms += 100;
            if (button_hold_ms >= WIFI_RESET_BUTTON_HOLD_MS) {
                ESP_LOGW(TAG, "botao pressionado %d ms — reset Wi-Fi", WIFI_RESET_BUTTON_HOLD_MS);
                app_publish_or_queue("status", "{\"tipo\":\"wifi\",\"evento\":\"reset_botao\"}");
                vTaskDelay(pdMS_TO_TICKS(300));
                wifi_prov_clear_credentials();
                esp_restart();
            }
        } else {
            button_hold_ms = 0;
        }

        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

static void provisioning_watchdog_task(void *arg)
{
    (void)arg;
    esp_task_wdt_add(NULL);
    while (true) {
        esp_task_wdt_reset();
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

static void enter_provisioning_mode(void)
{
    state_machine_set(STATE_PROVISIONING);
    wifi_prov_start_softap_portal();
    xTaskCreate(provisioning_watchdog_task, "prov_wdt", 2048, NULL, 3, NULL);
}

static esp_err_t nvs_flash_init_retry(void)
{
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_LOGW(TAG, "NVS precisa erase — reformatando");
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    return ret;
}

void app_main(void)
{
    ESP_ERROR_CHECK(nvs_flash_init_retry());
    ota_update_erase_factory_data_if_pending();

    s_batch_mu = xSemaphoreCreateMutex();
    s_work_queue = xQueueCreate(4, sizeof(work_item_t));
    s_button_queue = xQueueCreate(4, sizeof(uint8_t));
    s_pzem_queue = xQueueCreate(2, sizeof(pzem_work_item_t));
    app_runtime_init(s_batch_mu, s_work_queue, s_pzem_queue);

    relay_init_safe();
    device_id_init();
    state_machine_init(oled_display_on_state_change);
    led_feedback_init();
    oled_display_init();
    pzem_init(on_pzem_fault);
    ota_update_init(on_ota_status);
    ota_update_set_smoke_test(ota_post_boot_smoke);
    ota_update_mark_valid_on_boot();

    button_init(s_button_queue);
    if (!offline_queue_init()) {
        ESP_LOGE(TAG, "offline_queue_init falhou — fila offline desabilitada");
    }
    telemetry_init();

#if !CONFIG_DEV_MOCK_PZEM
    bool boot_pzem_fault = false;
    if (!pzem_boot_self_test()) {
        boot_pzem_fault = true;
        *app_state_before_fault() = STATE_IDLE;
        state_machine_set(STATE_HARDWARE_FAULT);
        led_feedback_signal(FEEDBACK_FAULT);
        publish_hardware_fault_boot("pzem_uart_boot");
    }
#endif

    ESP_LOGI(TAG, "device_id=%s firmware=%s", device_id_get(), FIRMWARE_VERSION);

    memset(app_batch(), 0, sizeof(batch_context_t));
    bool batch_loaded = batch_storage_load(app_batch());
#if !CONFIG_DEV_MOCK_PZEM
    if (!boot_pzem_fault) {
        if (batch_loaded) {
            state_machine_set(STATE_BATCH_READY);
            ESP_LOGI(TAG, "lote restaurado OP=%s seq=%lu", app_batch()->numero_op,
                     (unsigned long)app_batch()->proximo_sequencial);
            oled_display_set_batch(app_batch()->numero_op, app_batch()->aprovados,
                                   app_batch()->proximo_sequencial);
        } else {
            state_machine_set(STATE_IDLE);
            oled_display_set_batch(NULL, 0, 0);
        }
    } else if (batch_loaded) {
        *app_state_before_fault() = STATE_BATCH_READY;
        ESP_LOGW(TAG, "lote OP=%s em RAM — PZEM em falha, aguardando recuperacao",
                 app_batch()->numero_op);
        oled_display_set_batch(app_batch()->numero_op, app_batch()->aprovados,
                               app_batch()->proximo_sequencial);
    }
#else
    if (batch_loaded) {
        state_machine_set(STATE_BATCH_READY);
        ESP_LOGI(TAG, "lote restaurado OP=%s seq=%lu", app_batch()->numero_op,
                 (unsigned long)app_batch()->proximo_sequencial);
        oled_display_set_batch(app_batch()->numero_op, app_batch()->aprovados,
                               app_batch()->proximo_sequencial);
    } else {
        state_machine_set(STATE_IDLE);
        oled_display_set_batch(NULL, 0, 0);
    }
#endif

    if (!wifi_prov_has_credentials()) {
        enter_provisioning_mode();
        return;
    }

    if (!wifi_prov_connect_sta()) {
        ESP_LOGW(TAG, "falha STA — modo provisionamento");
        enter_provisioning_mode();
        return;
    }

    mqtt_topics_init();
    wifi_prov_apply_factory_mqtt_station();
    if (!mqtt_topics_is_configured()) {
        ESP_LOGW(TAG, "bancada nao configurada — modo provisionamento");
        enter_provisioning_mode();
        return;
    }

    time_sync_start();

    offline_queue_set_publish_fn(mqtt_publish_wrapper);
    if (!mqtt_bridge_init(mqtt_cmd_on_command, on_mqtt_connected)) {
        ESP_LOGE(TAG, "mqtt_bridge_init falhou — reiniciando em modo provisionamento");
        enter_provisioning_mode();
        return;
    }
    telemetry_set_snapshot_provider(telemetry_snapshot);
    telemetry_start();
    offline_queue_sync_task_start();
    xTaskCreate(pzem_worker_task, "pzem_worker", 8192, NULL, 6, NULL);
    xTaskCreate(worker_task, "worker", 8192, NULL, 6, NULL);
    xTaskCreate(hardware_monitor_task, "hw_mon", 3072, NULL, 5, NULL);

    ESP_LOGI(TAG, "sistema pronto (hardening producao)");
}

