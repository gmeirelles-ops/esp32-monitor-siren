#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "batch_storage.h"
#include "board_config.h"
#include "button.h"
#include "cJSON.h"
#include "device_id.h"
#include "esp_log.h"
#include "esp_task_wdt.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"
#include "led_feedback.h"
#include "mqtt_bridge.h"
#include "nvs_flash.h"
#include "offline_queue.h"
#include "ota_update.h"
#include "pzem.h"
#include "pure_logic.h"
#include "relay.h"
#include "sdkconfig.h"
#include "state_machine.h"
#include "telemetry.h"
#include "wifi_prov.h"

static const char *TAG = "main";
static batch_context_t s_batch;
static app_state_t s_state_before_fault;
static bool s_calibrating;
static QueueHandle_t s_work_queue;
static QueueHandle_t s_button_queue;
static QueueHandle_t s_pzem_queue;
static volatile bool s_pzem_busy;

typedef enum {
    WORK_BUTTON_PRESS = 1,
    WORK_MQTT_PAYLOAD,
} work_type_t;

typedef enum {
    PZEM_WORK_TEST = 1,
    PZEM_WORK_CALIBRATION,
} pzem_work_type_t;

typedef struct {
    work_type_t type;
    char payload[512];
} work_item_t;

typedef struct {
    pzem_work_type_t type;
    uint32_t duration_sec;
} pzem_work_item_t;

static void publish_or_queue(const char *topic_suffix, const char *json);
static void run_test_cycle(uint32_t duration_sec);
static bool parse_set_batch(cJSON *root);
static void publish_batch_ack(void);
static void handle_end_batch(void);
static void handle_end_batch_with_reason(const char *motivo);
static void handle_start_calibration(void);
static void on_calibration_sample(float power_w, uint32_t elapsed_ms, void *ctx);
static void handle_ota_update(cJSON *root);
static void handle_pzem_probe(void);
static void publish_test_result(bool approved, float potencia_media, uint32_t sequencial_usado);
static void process_mqtt_payload(const char *payload);
static void worker_task(void *arg);
static void pzem_worker_task(void *arg);
static bool enqueue_pzem_work(pzem_work_type_t type, uint32_t duration_sec);
static void hardware_monitor_task(void *arg);
static bool telemetry_snapshot(telemetry_snapshot_t *out);
static void on_mqtt_connected(void);
static void on_pzem_fault(bool fault);
static void on_ota_status(const char *json);

static void publish_or_queue(const char *topic_suffix, const char *json)
{
    if (mqtt_bridge_is_connected() && mqtt_bridge_publish(topic_suffix, json)) {
        return;
    }
    if (offline_queue_is_full()) {
        led_feedback_signal(FEEDBACK_QUEUE_FULL);
    }
    offline_queue_push(topic_suffix, json);
}

static void publish_test_result(bool approved, float potencia_media, uint32_t sequencial_usado)
{
    char json[384];
    snprintf(json, sizeof(json),
             "{\"tipo\":\"teste\",\"numero_op\":\"%s\",\"id_produto\":\"%s\",\"ano\":\"%s\","
             "\"veredito\":\"%s\",\"potencia_media\":%.2f,\"sequencial\":%lu,\"aprovados_no_lote\":%lu}",
             s_batch.numero_op, s_batch.id_produto, s_batch.ano,
             approved ? "APROVADO" : "REPROVADO", potencia_media,
             (unsigned long)sequencial_usado, (unsigned long)s_batch.aprovados);
    publish_or_queue("status", json);
}

static void publish_batch_ack(void)
{
    char json[192];
    snprintf(json, sizeof(json),
             "{\"tipo\":\"batch\",\"evento\":\"configurado\",\"numero_op\":\"%s\",\"estado\":\"BATCH_READY\"}",
             s_batch.numero_op);
    publish_or_queue("status", json);
}

static void run_test_cycle(uint32_t duration_sec)
{
    if (!state_machine_can_start_test() || pzem_is_fault() || ota_update_is_active()) {
        return;
    }

    if (pure_batch_quota_reached(s_batch.aprovados, s_batch.quantidade_total)) {
        led_feedback_signal(FEEDBACK_REJECTED);
        if (mqtt_bridge_is_connected()) {
            mqtt_bridge_publish_rejection("lote_cheio");
        }
        return;
    }

    state_machine_set(STATE_TESTING);
    button_set_test_in_progress(true);
    relay_set(true);

    pzem_cycle_result_t result = {0};
    bool ok = pzem_measure_cycle(duration_sec, INRUSH_DISCARD_MS, &result, NULL, NULL);

    relay_set(false);
    button_set_test_in_progress(false);

    if (!ok || result.uart_error) {
        state_machine_set(STATE_HARDWARE_FAULT);
        led_feedback_signal(FEEDBACK_FAULT);
        char alerta[128];
        snprintf(alerta, sizeof(alerta), "{\"tipo\":\"hardware\",\"falha\":\"pzem_uart\"}");
        publish_or_queue("alerta", alerta);
        return;
    }

    bool approved = pure_verdict_approved(result.average_w, s_batch.potencia_min, s_batch.potencia_max);
    uint32_t sequencial_usado = s_batch.proximo_sequencial;

    if (approved) {
        if (!s_batch.modo_reteste) {
            s_batch.aprovados++;
            s_batch.proximo_sequencial++;
            batch_storage_save(&s_batch);
        }
        led_feedback_signal(FEEDBACK_APPROVED);
    } else {
        led_feedback_signal(FEEDBACK_REJECTED);
    }

    publish_test_result(approved, result.average_w, sequencial_usado);

    if (approved && !s_batch.modo_reteste &&
        pure_batch_quota_reached(s_batch.aprovados, s_batch.quantidade_total)) {
        handle_end_batch_with_reason("cota_atingida");
    } else {
        state_machine_set(STATE_BATCH_READY);
    }
}

static bool parse_set_batch(cJSON *root)
{
    pure_batch_input_t in;
    memset(&in, 0, sizeof(in));

    cJSON *item = cJSON_GetObjectItem(root, "numero_op");
    if (!cJSON_IsString(item) || !pure_batch_copy_str(in.numero_op, sizeof(in.numero_op), item->valuestring)) {
        return false;
    }

    item = cJSON_GetObjectItem(root, "id_produto");
    if (!cJSON_IsString(item) || !pure_batch_copy_str(in.id_produto, sizeof(in.id_produto), item->valuestring)) {
        return false;
    }

    item = cJSON_GetObjectItem(root, "ano");
    if (!cJSON_IsString(item) || !pure_batch_copy_str(in.ano, sizeof(in.ano), item->valuestring)) {
        return false;
    }

    item = cJSON_GetObjectItem(root, "tempo_teste");
    if (!cJSON_IsNumber(item)) {
        return false;
    }
    in.tempo_teste_sec = (uint32_t)item->valuedouble;

    item = cJSON_GetObjectItem(root, "potencia_min");
    if (!cJSON_IsNumber(item)) {
        return false;
    }
    in.potencia_min = (float)item->valuedouble;

    item = cJSON_GetObjectItem(root, "potencia_max");
    if (!cJSON_IsNumber(item)) {
        return false;
    }
    in.potencia_max = (float)item->valuedouble;

    item = cJSON_GetObjectItem(root, "quantidade_total");
    if (!cJSON_IsNumber(item)) {
        return false;
    }
    in.quantidade_total = (uint32_t)item->valuedouble;

    item = cJSON_GetObjectItem(root, "proximo_sequencial");
    if (!cJSON_IsNumber(item)) {
        return false;
    }
    in.proximo_sequencial = (uint32_t)item->valuedouble;

    if (!pure_batch_fields_valid(&in)) {
        return false;
    }

    bool same_op = s_batch.active && pure_batch_same_op(s_batch.numero_op, in.numero_op);
    uint32_t preserved_aprovados = same_op ? s_batch.aprovados : 0;
    uint32_t preserved_sequencial = same_op ? s_batch.proximo_sequencial : in.proximo_sequencial;
    bool preserved_reteste = same_op ? s_batch.modo_reteste : false;
    if (same_op && in.proximo_sequencial > preserved_sequencial) {
        preserved_sequencial = in.proximo_sequencial;
    }

    item = cJSON_GetObjectItem(root, "modo_reteste");
    bool modo_reteste = preserved_reteste;
    if (cJSON_IsBool(item)) {
        modo_reteste = cJSON_IsTrue(item);
    }

    strcpy(s_batch.numero_op, in.numero_op);
    strcpy(s_batch.id_produto, in.id_produto);
    strcpy(s_batch.ano, in.ano);
    s_batch.tempo_teste_sec = in.tempo_teste_sec;
    s_batch.potencia_min = in.potencia_min;
    s_batch.potencia_max = in.potencia_max;
    s_batch.quantidade_total = in.quantidade_total;
    s_batch.proximo_sequencial = preserved_sequencial;
    s_batch.aprovados = preserved_aprovados;
    s_batch.modo_reteste = modo_reteste;
    s_batch.active = true;

    batch_storage_save(&s_batch);
    state_machine_set(STATE_BATCH_READY);
    telemetry_publish_now();
    publish_batch_ack();
    return true;
}

static void handle_end_batch_with_reason(const char *motivo)
{
    if (state_machine_get() == STATE_TESTING) {
        mqtt_bridge_publish_rejection("end_batch_durante_teste");
        return;
    }
    if (motivo != NULL) {
        char json[128];
        snprintf(json, sizeof(json),
                 "{\"tipo\":\"batch\",\"evento\":\"encerrado\",\"motivo\":\"%s\"}", motivo);
        publish_or_queue("status", json);
    }
    memset(&s_batch, 0, sizeof(s_batch));
    batch_storage_clear();
    state_machine_set(STATE_IDLE);
    telemetry_publish_now();
}

static void handle_end_batch(void)
{
    handle_end_batch_with_reason(NULL);
}

static void on_calibration_sample(float power_w, uint32_t elapsed_ms, void *ctx)
{
    (void)ctx;
    char json[128];
    snprintf(json, sizeof(json),
             "{\"tipo\":\"calibracao_amostra\",\"potencia_w\":%.2f,\"elapsed_ms\":%lu}",
             power_w, (unsigned long)elapsed_ms);
    publish_or_queue("calibracao", json);
}

static void handle_start_calibration(void)
{
    if (!state_machine_can_accept_calibration()) {
        mqtt_bridge_publish_rejection("calibracao_estado_invalido");
        return;
    }

    s_calibrating = true;
    state_machine_set(STATE_TESTING);
    button_set_test_in_progress(true);
    relay_set(true);

    pzem_cycle_result_t result = {0};
    bool ok = pzem_measure_cycle(CALIBRATION_SEC, INRUSH_DISCARD_MS, &result,
                                 on_calibration_sample, NULL);

    relay_set(false);
    button_set_test_in_progress(false);
    s_calibrating = false;

    if (!ok || result.uart_error) {
        state_machine_set(STATE_HARDWARE_FAULT);
        return;
    }

    char json[128];
    snprintf(json, sizeof(json), "{\"tipo\":\"calibracao\",\"potencia_media\":%.2f}", result.average_w);
    publish_or_queue("calibracao", json);
    state_machine_set(STATE_IDLE);
}

static void handle_ota_update(cJSON *root)
{
    if (!state_machine_can_accept_ota()) {
        mqtt_bridge_publish_rejection("ota_estado_invalido");
        return;
    }
    cJSON *url = cJSON_GetObjectItem(root, "url");
    if (!cJSON_IsString(url) || !pure_ota_url_valid(url->valuestring)) {
        mqtt_bridge_publish_rejection("ota_url_invalida");
        return;
    }
    state_machine_set(STATE_OTA_UPDATING);
    if (!ota_update_start(url->valuestring)) {
        state_machine_set(batch_storage_has_active() ? STATE_BATCH_READY : STATE_IDLE);
        mqtt_bridge_publish_rejection("ota_falha_inicio");
    }
}

static void handle_pzem_probe(void)
{
    float power = 0;
    bool ok = pzem_probe_read(&power);
    char json[128];
    snprintf(json, sizeof(json),
             "{\"tipo\":\"pzem\",\"evento\":\"probe\",\"potencia_w\":%.2f,\"uart_ok\":%s}",
             power, ok ? "true" : "false");
    publish_or_queue("status", json);
}

static void process_mqtt_payload(const char *payload)
{
    cJSON *root = cJSON_Parse(payload);
    if (!root) {
        mqtt_bridge_publish_rejection("json_invalido");
        return;
    }

    cJSON *cmd = cJSON_GetObjectItem(root, "cmd");
    if (!cJSON_IsString(cmd)) {
        cJSON_Delete(root);
        mqtt_bridge_publish_rejection("cmd_ausente");
        return;
    }

    if (strcmp(cmd->valuestring, "SET_BATCH") == 0) {
        if (!state_machine_can_accept_batch_cmd()) {
            mqtt_bridge_publish_rejection("set_batch_durante_teste");
        } else if (!parse_set_batch(root)) {
            mqtt_bridge_publish_rejection("set_batch_campos_invalidos");
        }
    } else if (strcmp(cmd->valuestring, "END_BATCH") == 0) {
        handle_end_batch();
    } else if (strcmp(cmd->valuestring, "START_CALIBRATION") == 0) {
        if (!state_machine_can_accept_calibration()) {
            mqtt_bridge_publish_rejection("calibracao_estado_invalido");
        } else if (!enqueue_pzem_work(PZEM_WORK_CALIBRATION, 0)) {
            mqtt_bridge_publish_rejection("pzem_ocupado");
        }
    } else if (strcmp(cmd->valuestring, "OTA_UPDATE") == 0) {
        handle_ota_update(root);
    } else if (strcmp(cmd->valuestring, "PZEM_PROBE") == 0) {
        handle_pzem_probe();
    } else {
        mqtt_bridge_publish_rejection("cmd_desconhecido");
    }

    cJSON_Delete(root);
}

static bool mqtt_cmd_blocked_during_test(const char *payload)
{
    if (state_machine_get() != STATE_TESTING && !s_calibrating) {
        return false;
    }

    const char *key = strstr(payload, "\"cmd\"");
    if (!key) {
        return false;
    }

    const char *colon = strchr(key, ':');
    if (!colon) {
        return false;
    }

    const char *p = colon + 1;
    while (*p == ' ' || *p == '\t') {
        p++;
    }
    if (*p != '"') {
        return false;
    }
    p++;

    static const char *blocked[] = {"SET_BATCH", "END_BATCH", "START_CALIBRATION", "OTA_UPDATE", "PZEM_PROBE", NULL};
    for (int i = 0; blocked[i] != NULL; i++) {
        size_t n = strlen(blocked[i]);
        if (strncmp(p, blocked[i], n) == 0 && p[n] == '"') {
            return true;
        }
    }
    return false;
}

static void on_mqtt_command(const char *payload, int len)
{
    if (len >= (int)sizeof(((work_item_t *)0)->payload)) {
        mqtt_bridge_publish_rejection("payload_grande");
        return;
    }
    if (mqtt_cmd_blocked_during_test(payload)) {
        mqtt_bridge_publish_rejection("cmd_durante_teste");
        return;
    }
    work_item_t item = {.type = WORK_MQTT_PAYLOAD};
    memcpy(item.payload, payload, len);
    item.payload[len] = '\0';
    if (xQueueSend(s_work_queue, &item, 0) != pdTRUE) {
        mqtt_bridge_publish_rejection("fila_cheia");
    }
}

static bool enqueue_pzem_work(pzem_work_type_t type, uint32_t duration_sec)
{
    if (s_pzem_busy) {
        return false;
    }
    pzem_work_item_t item = {
        .type = type,
        .duration_sec = duration_sec,
    };
    return xQueueSend(s_pzem_queue, &item, 0) == pdTRUE;
}

static void pzem_worker_task(void *arg)
{
    (void)arg;
    esp_task_wdt_add(NULL);
    pzem_work_item_t item;
    while (true) {
        esp_task_wdt_reset();
        if (xQueueReceive(s_pzem_queue, &item, pdMS_TO_TICKS(500)) != pdTRUE) {
            continue;
        }
        s_pzem_busy = true;
        if (item.type == PZEM_WORK_TEST) {
            run_test_cycle(item.duration_sec);
        } else if (item.type == PZEM_WORK_CALIBRATION) {
            handle_start_calibration();
        }
        s_pzem_busy = false;
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
            if (!s_calibrating) {
                enqueue_pzem_work(PZEM_WORK_TEST, s_batch.tempo_teste_sec);
            }
        }
        if (xQueueReceive(s_work_queue, &item, pdMS_TO_TICKS(500)) != pdTRUE) {
            continue;
        }
        if (item.type == WORK_MQTT_PAYLOAD) {
            process_mqtt_payload(item.payload);
        }
    }
}

static bool mqtt_publish_wrapper(const char *topic_suffix, const char *json)
{
    return mqtt_bridge_publish(topic_suffix, json);
}

static void on_mqtt_connected(void)
{
    telemetry_publish_now();
    offline_queue_sync_now();
}

static bool telemetry_snapshot(telemetry_snapshot_t *out)
{
    out->rssi = wifi_prov_get_rssi();
    out->estado = state_machine_name(state_machine_get());
    out->fila = offline_queue_count();
    out->firmware_version = FIRMWARE_VERSION;
    out->batch_active = s_batch.active;
    if (s_batch.active) {
        out->numero_op = s_batch.numero_op;
        out->proximo_sequencial = s_batch.proximo_sequencial;
        out->aprovados = s_batch.aprovados;
    } else {
        out->numero_op = "";
        out->proximo_sequencial = 0;
        out->aprovados = 0;
    }
    return true;
}

static void on_pzem_fault(bool fault)
{
    if (!fault) {
        return;
    }
    s_state_before_fault = state_machine_get();
    state_machine_set(STATE_HARDWARE_FAULT);
    relay_set(false);
    led_feedback_signal(FEEDBACK_FAULT);
    char alerta[128];
    snprintf(alerta, sizeof(alerta), "{\"tipo\":\"hardware\",\"falha\":\"pzem_uart\"}");
    publish_or_queue("alerta", alerta);
}

static void on_ota_status(const char *json)
{
    publish_or_queue("status", json);
    if (strstr(json, "\"evento\":\"falha\"") != NULL) {
        app_state_t restore = batch_storage_has_active() ? STATE_BATCH_READY : STATE_IDLE;
        state_machine_set(restore);
        ESP_LOGW(TAG, "OTA falhou — estado restaurado para %s", state_machine_name(restore));
    }
}

static void hardware_monitor_task(void *arg)
{
    (void)arg;
    esp_task_wdt_add(NULL);
    while (true) {
        esp_task_wdt_reset();
        if (state_machine_get() == STATE_HARDWARE_FAULT) {
            pzem_clear_fault();
            if (!pzem_is_fault()) {
                app_state_t restore = s_state_before_fault;
                if (restore == STATE_TESTING) {
                    restore = batch_storage_has_active() ? STATE_BATCH_READY : STATE_IDLE;
                }
                state_machine_set(restore);
                char alerta[128];
                snprintf(alerta, sizeof(alerta), "{\"tipo\":\"hardware\",\"evento\":\"recuperado\"}");
                publish_or_queue("alerta", alerta);
            }
        }
        vTaskDelay(pdMS_TO_TICKS(2000));
    }
}

void app_main(void)
{
    ESP_ERROR_CHECK(nvs_flash_init());

    relay_init_safe();
    device_id_init();
    state_machine_init(NULL);
    led_feedback_init();
    pzem_init(on_pzem_fault);
    ota_update_init(on_ota_status);
    ota_update_mark_valid_on_boot();

    s_work_queue = xQueueCreate(4, sizeof(work_item_t));
    s_button_queue = xQueueCreate(4, sizeof(uint8_t));
    s_pzem_queue = xQueueCreate(2, sizeof(pzem_work_item_t));
    button_init(s_button_queue);
    offline_queue_init();
    telemetry_init();

#if !CONFIG_DEV_MOCK_PZEM
    if (!pzem_boot_self_test()) {
        s_state_before_fault = state_machine_get();
        state_machine_set(STATE_HARDWARE_FAULT);
        led_feedback_signal(FEEDBACK_FAULT);
        char alerta[128];
        snprintf(alerta, sizeof(alerta), "{\"tipo\":\"hardware\",\"falha\":\"pzem_uart_boot\"}");
        publish_or_queue("alerta", alerta);
    }
#endif

    ESP_LOGI(TAG, "device_id=%s firmware=%s", device_id_get(), FIRMWARE_VERSION);

    memset(&s_batch, 0, sizeof(s_batch));
    if (batch_storage_load(&s_batch)) {
        state_machine_set(STATE_BATCH_READY);
        ESP_LOGI(TAG, "lote restaurado OP=%s seq=%lu", s_batch.numero_op, (unsigned long)s_batch.proximo_sequencial);
    } else {
        state_machine_set(STATE_IDLE);
    }

    if (!wifi_prov_has_credentials()) {
        state_machine_set(STATE_PROVISIONING);
        wifi_prov_start_softap_portal();
        return;
    }

    if (!wifi_prov_connect_sta()) {
        ESP_LOGW(TAG, "falha STA — modo provisionamento");
        state_machine_set(STATE_PROVISIONING);
        wifi_prov_start_softap_portal();
        return;
    }

    offline_queue_set_publish_fn(mqtt_publish_wrapper);
    mqtt_bridge_init(on_mqtt_command, on_mqtt_connected);
    telemetry_set_snapshot_provider(telemetry_snapshot);
    telemetry_start();
    offline_queue_sync_task_start();
    xTaskCreate(pzem_worker_task, "pzem_worker", 8192, NULL, 6, NULL);
    xTaskCreate(worker_task, "worker", 8192, NULL, 6, NULL);
    xTaskCreate(hardware_monitor_task, "hw_mon", 3072, NULL, 5, NULL);

    ESP_LOGI(TAG, "sistema pronto (hardening producao)");
}
