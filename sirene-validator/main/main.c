#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "batch_storage.h"
#include "board_config.h"
#include "button.h"
#include "cJSON.h"
#include "device_id.h"
#include "esp_log.h"
#include "esp_system.h"
#include "esp_task_wdt.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"
#include "led_feedback.h"
#include "mqtt_bridge.h"
#include "mqtt_config.h"
#include "mqtt_topics.h"
#include "nvs_flash.h"
#include "offline_queue.h"
#include "ota_update.h"
#include "pzem.h"
#include "pure_logic.h"
#include "relay.h"
#include "sdkconfig.h"
#include "state_machine.h"
#include "telemetry.h"
#include "time_sync.h"
#include "wifi_prov.h"

static const char *TAG = "main";
static batch_context_t s_batch;
static bool s_batch_nvs_fault;
static SemaphoreHandle_t s_batch_mu;
static app_state_t s_state_before_fault;
static bool s_calibrating;
static volatile bool s_ensaio_stop;
static bool s_ensaio_running;

typedef struct {
    uint32_t on_sec;
    uint32_t off_sec;
    uint32_t total_sec;
} ensaio_params_t;
static QueueHandle_t s_work_queue;
static QueueHandle_t s_button_queue;
static QueueHandle_t s_pzem_queue;
static volatile bool s_pzem_busy;
static int64_t s_last_button_press_us;

typedef enum {
    WORK_BUTTON_PRESS = 1,
    WORK_MQTT_PAYLOAD,
} work_type_t;

typedef enum {
    PZEM_WORK_TEST = 1,
    PZEM_WORK_CALIBRATION,
    PZEM_WORK_ENSAIO,
} pzem_work_type_t;

typedef struct {
    work_type_t type;
    char payload[512];
} work_item_t;

typedef struct {
    pzem_work_type_t type;
    uint32_t duration_sec;
    ensaio_params_t ensaio;
} pzem_work_item_t;

static void publish_or_queue(const char *topic_suffix, const char *json);
static void run_test_cycle(uint32_t duration_sec);
static bool parse_set_batch(cJSON *root);
static void publish_batch_ack(void);
static void publish_batch_nvs_fault(void);
static void handle_end_batch(void);
static void handle_end_batch_with_reason(const char *motivo);
static void handle_start_calibration(void);
static void handle_start_ensaio(ensaio_params_t params);
static void handle_stop_ensaio(void);
static bool parse_start_ensaio(cJSON *root, ensaio_params_t *out);
static void publish_ensaio_msg(const char *evento, const ensaio_params_t *params,
                               uint32_t n, const char *fase, uint32_t elapsed_sec,
                               uint32_t ciclos, const char *motivo);
static bool enqueue_ensaio_work(ensaio_params_t params);
static void on_calibration_sample(float power_w, uint32_t elapsed_ms, void *ctx);
static void handle_ota_update(cJSON *root);
static void handle_pzem_probe(void);
static void handle_reset_wifi(cJSON *root);
static void handle_set_bancada(cJSON *root);
static void publish_test_result(bool approved, float potencia_media, uint32_t sequencial_usado);
static void process_mqtt_payload(const char *payload);
static void worker_task(void *arg);
static void pzem_worker_task(void *arg);
static bool enqueue_pzem_work(pzem_work_type_t type, uint32_t duration_sec);
static void hardware_monitor_task(void *arg);
static bool telemetry_snapshot(telemetry_snapshot_t *out);
static void on_mqtt_connected(void);
static void on_pzem_fault(bool fault);
static void publish_hardware_fault(const char *falha);
static void enter_hardware_fault(app_state_t restore_state, const char *falha);

static void batch_lock(void)
{
    if (s_batch_mu) {
        xSemaphoreTake(s_batch_mu, portMAX_DELAY);
    }
}

static void batch_unlock(void)
{
    if (s_batch_mu) {
        xSemaphoreGive(s_batch_mu);
    }
}

static int64_t now_ts_ms(void)
{
    return esp_timer_get_time() / 1000;
}

static void publish_or_queue(const char *topic_suffix, const char *json)
{
    if (mqtt_bridge_is_connected() && mqtt_bridge_publish(topic_suffix, json)) {
        return;
    }
    if (offline_queue_is_full()) {
        led_feedback_signal(FEEDBACK_QUEUE_FULL);
        return;
    }
    if (!offline_queue_push(topic_suffix, json)) {
        led_feedback_signal(FEEDBACK_QUEUE_FULL);
    }
}

static void publish_test_result(bool approved, float potencia_media, uint32_t sequencial_usado)
{
    char numero_op[16];
    char id_produto[4];
    char ano[3];
    uint32_t aprovados;
    batch_lock();
    strncpy(numero_op, s_batch.numero_op, sizeof(numero_op) - 1);
    strncpy(id_produto, s_batch.id_produto, sizeof(id_produto) - 1);
    strncpy(ano, s_batch.ano, sizeof(ano) - 1);
    aprovados = s_batch.aprovados;
    batch_unlock();

    char json[448];
    snprintf(json, sizeof(json),
             "{\"tipo\":\"teste\",\"ts_ms\":%lld,\"ts_unix\":%lld,"
             "\"numero_op\":\"%s\",\"id_produto\":\"%s\",\"ano\":\"%s\","
             "\"veredito\":\"%s\",\"potencia_media\":%.2f,\"sequencial\":%lu,\"aprovados_no_lote\":%lu}",
             (long long)now_ts_ms(), (long long)time_sync_unix(),
             numero_op, id_produto, ano,
             approved ? "APROVADO" : "REPROVADO", potencia_media,
             (unsigned long)sequencial_usado, (unsigned long)aprovados);
    publish_or_queue("status", json);
}

static void publish_batch_ack(void)
{
    char numero_op[16];
    batch_lock();
    strncpy(numero_op, s_batch.numero_op, sizeof(numero_op) - 1);
    batch_unlock();

    char json[224];
    snprintf(json, sizeof(json),
             "{\"tipo\":\"batch\",\"evento\":\"configurado\",\"ts_ms\":%lld,\"numero_op\":\"%s\",\"estado\":\"BATCH_READY\"}",
             (long long)now_ts_ms(), numero_op);
    publish_or_queue("status", json);
}

static void publish_batch_nvs_fault(void)
{
    char json[128];
    snprintf(json, sizeof(json),
             "{\"tipo\":\"alerta\",\"evento\":\"batch_nvs_fault\",\"detalhe\":\"falha ao persistir lote\"}");
    publish_or_queue("alerta", json);
    led_feedback_signal(FEEDBACK_FAULT);
}

static void run_test_cycle(uint32_t duration_sec)
{
    if (!state_machine_can_start_test() || pzem_is_fault() || ota_update_is_active()) {
        return;
    }

    if (s_batch_nvs_fault) {
        led_feedback_signal(FEEDBACK_FAULT);
        if (mqtt_bridge_is_connected()) {
            mqtt_bridge_publish_rejection("batch_nvs_fault");
        }
        return;
    }

    batch_lock();
    if (pure_batch_quota_reached(s_batch.aprovados, s_batch.quantidade_total)) {
        batch_unlock();
        led_feedback_signal(FEEDBACK_REJECTED);
        if (mqtt_bridge_is_connected()) {
            mqtt_bridge_publish_rejection("lote_cheio");
        }
        return;
    }

    float pot_min = s_batch.potencia_min;
    float pot_max = s_batch.potencia_max;
    bool modo_reteste = s_batch.modo_reteste;
    uint32_t quantidade_total = s_batch.quantidade_total;
    batch_unlock();

    state_machine_set(STATE_TESTING);
    button_set_test_in_progress(true);
    relay_set(true);

    pzem_cycle_result_t result = {0};
    bool ok = pzem_measure_cycle(duration_sec, INRUSH_DISCARD_MS, &result, NULL, NULL);

    relay_set(false);
    button_set_test_in_progress(false);

    if (pzem_is_fault() || !ok || result.uart_error) {
        enter_hardware_fault(STATE_BATCH_READY, "pzem_uart");
        return;
    }

    bool approved = pure_verdict_approved(result.average_w, pot_min, pot_max);
    uint32_t sequencial_usado;

    batch_lock();
    sequencial_usado = s_batch.proximo_sequencial;

    if (approved) {
        if (!modo_reteste) {
            uint32_t prev_aprovados = s_batch.aprovados;
            uint32_t prev_sequencial = s_batch.proximo_sequencial;
            s_batch.aprovados++;
            s_batch.proximo_sequencial++;
            if (!batch_storage_save(&s_batch)) {
                s_batch.aprovados = prev_aprovados;
                s_batch.proximo_sequencial = prev_sequencial;
                s_batch_nvs_fault = true;
                batch_unlock();
                publish_batch_nvs_fault();
            } else {
                s_batch_nvs_fault = false;
                batch_unlock();
            }
        } else {
            batch_unlock();
        }
        led_feedback_signal(FEEDBACK_APPROVED);
    } else {
        batch_unlock();
        led_feedback_signal(FEEDBACK_REJECTED);
    }

    publish_test_result(approved, result.average_w, sequencial_usado);

    bool quota_done = false;
    batch_lock();
    quota_done = approved && !modo_reteste &&
                 pure_batch_quota_reached(s_batch.aprovados, quantidade_total);
    batch_unlock();

    if (quota_done) {
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

    batch_context_t backup;
    batch_lock();
    backup = s_batch;

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

    if (!batch_storage_save(&s_batch)) {
        s_batch = backup;
        s_batch_nvs_fault = true;
        batch_unlock();
        publish_batch_nvs_fault();
        return false;
    }
    s_batch_nvs_fault = false;
    batch_unlock();
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
    if (s_calibrating) {
        mqtt_bridge_publish_rejection("end_batch_durante_calibracao");
        return;
    }
    if (s_ensaio_running) {
        mqtt_bridge_publish_rejection("end_batch_durante_ensaio");
        return;
    }
    if (ota_update_is_active() || state_machine_get() == STATE_OTA_UPDATING) {
        mqtt_bridge_publish_rejection("end_batch_durante_ota");
        return;
    }
    const char *reason = motivo != NULL ? motivo : "operador";
    char json[128];
    snprintf(json, sizeof(json),
             "{\"tipo\":\"batch\",\"evento\":\"encerrado\",\"motivo\":\"%s\"}", reason);
    publish_or_queue("status", json);
    batch_lock();
    memset(&s_batch, 0, sizeof(s_batch));
    batch_unlock();
    batch_storage_clear();
    state_machine_set(STATE_IDLE);
    telemetry_publish_now();
}

static void handle_end_batch(void)
{
    handle_end_batch_with_reason(NULL);
}

static void publish_calibracao_msg(const char *evento, float potencia_w, uint32_t elapsed_ms,
                                   float potencia_media)
{
    char json[320];
    int64_t ts_ms = esp_timer_get_time() / 1000;
    const char *site = mqtt_topics_get_site();
    unsigned bancada = (unsigned)mqtt_topics_get_bancada();

    if (evento && strcmp(evento, "amostra") == 0) {
        snprintf(json, sizeof(json),
                 "{\"device_id\":\"%s\",\"site\":\"%s\",\"bancada\":%u,\"ts_ms\":%lld,"
                 "\"tipo\":\"calibracao_amostra\",\"evento\":\"amostra\",\"potencia_w\":%.2f,"
                 "\"elapsed_ms\":%lu}",
                 device_id_get(), site, bancada, (long long)ts_ms, potencia_w,
                 (unsigned long)elapsed_ms);
    } else if (evento && strcmp(evento, "falha") == 0) {
        snprintf(json, sizeof(json),
                 "{\"device_id\":\"%s\",\"site\":\"%s\",\"bancada\":%u,\"ts_ms\":%lld,"
                 "\"tipo\":\"calibracao\",\"evento\":\"falha\",\"motivo\":\"pzem_uart\"}",
                 device_id_get(), site, bancada, (long long)ts_ms);
    } else if (evento && strcmp(evento, "iniciado") == 0) {
        snprintf(json, sizeof(json),
                 "{\"device_id\":\"%s\",\"site\":\"%s\",\"bancada\":%u,\"ts_ms\":%lld,"
                 "\"tipo\":\"calibracao\",\"evento\":\"iniciado\"}",
                 device_id_get(), site, bancada, (long long)ts_ms);
    } else {
        snprintf(json, sizeof(json),
                 "{\"device_id\":\"%s\",\"site\":\"%s\",\"bancada\":%u,\"ts_ms\":%lld,"
                 "\"tipo\":\"calibracao\",\"evento\":\"concluido\",\"potencia_media\":%.2f}",
                 device_id_get(), site, bancada, (long long)ts_ms, potencia_media);
    }
    publish_or_queue("calibracao", json);
}

static void on_calibration_sample(float power_w, uint32_t elapsed_ms, void *ctx)
{
    (void)ctx;
    publish_calibracao_msg("amostra", power_w, elapsed_ms, 0);
}

static void handle_start_calibration(void)
{
    if (!state_machine_can_accept_calibration()) {
        mqtt_bridge_publish_rejection("calibracao_estado_invalido");
        return;
    }
    if (pzem_is_fault()) {
        mqtt_bridge_publish_rejection("calibracao_pzem_falha");
        return;
    }

    app_state_t restore_state;
    batch_lock();
    restore_state = s_batch.active ? STATE_BATCH_READY : STATE_IDLE;
    batch_unlock();

    s_calibrating = true;
    publish_calibracao_msg("iniciado", 0, 0, 0);
    state_machine_set(STATE_TESTING);
    button_set_test_in_progress(true);
    relay_set(true);

    pzem_cycle_result_t result = {0};
    bool ok = pzem_measure_cycle(CALIBRATION_SEC, INRUSH_DISCARD_MS, &result,
                                 on_calibration_sample, NULL);

    relay_set(false);
    button_set_test_in_progress(false);
    s_calibrating = false;

    if (pzem_is_fault() || !ok || result.uart_error) {
        publish_calibracao_msg("falha", 0, 0, 0);
        enter_hardware_fault(restore_state, "pzem_uart_calibracao");
        return;
    }

    publish_calibracao_msg("concluido", 0, 0, result.average_w);
    state_machine_set(restore_state);
}

static void publish_ensaio_msg(const char *evento, const ensaio_params_t *params,
                               uint32_t n, const char *fase, uint32_t elapsed_sec,
                               uint32_t ciclos, const char *motivo)
{
    char json[384];
    int64_t ts_ms = esp_timer_get_time() / 1000;
    const char *site = mqtt_topics_get_site();
    unsigned bancada = (unsigned)mqtt_topics_get_bancada();

    if (evento && strcmp(evento, "iniciado") == 0 && params != NULL) {
        snprintf(json, sizeof(json),
                 "{\"device_id\":\"%s\",\"site\":\"%s\",\"bancada\":%u,\"ts_ms\":%lld,"
                 "\"tipo\":\"ensaio\",\"evento\":\"iniciado\",\"on_sec\":%u,\"off_sec\":%u,"
                 "\"duracao_total_sec\":%u}",
                 device_id_get(), site, bancada, (long long)ts_ms,
                 (unsigned)params->on_sec, (unsigned)params->off_sec,
                 (unsigned)params->total_sec);
    } else if (evento && strcmp(evento, "ciclo") == 0) {
        snprintf(json, sizeof(json),
                 "{\"device_id\":\"%s\",\"site\":\"%s\",\"bancada\":%u,\"ts_ms\":%lld,"
                 "\"tipo\":\"ensaio\",\"evento\":\"ciclo\",\"n\":%u,\"fase\":\"%s\","
                 "\"elapsed_sec\":%u}",
                 device_id_get(), site, bancada, (long long)ts_ms, (unsigned)n,
                 fase != NULL ? fase : "ligado", (unsigned)elapsed_sec);
    } else if (evento && strcmp(evento, "concluido") == 0) {
        snprintf(json, sizeof(json),
                 "{\"device_id\":\"%s\",\"site\":\"%s\",\"bancada\":%u,\"ts_ms\":%lld,"
                 "\"tipo\":\"ensaio\",\"evento\":\"concluido\",\"ciclos\":%u,"
                 "\"elapsed_sec\":%u,\"motivo\":\"%s\"}",
                 device_id_get(), site, bancada, (long long)ts_ms, (unsigned)ciclos,
                 (unsigned)elapsed_sec, motivo != NULL ? motivo : "duracao");
    } else if (evento && strcmp(evento, "falha") == 0) {
        snprintf(json, sizeof(json),
                 "{\"device_id\":\"%s\",\"site\":\"%s\",\"bancada\":%u,\"ts_ms\":%lld,"
                 "\"tipo\":\"ensaio\",\"evento\":\"falha\",\"motivo\":\"%s\"}",
                 device_id_get(), site, bancada, (long long)ts_ms,
                 motivo != NULL ? motivo : "desconhecido");
    } else {
        return;
    }
    publish_or_queue("ensaio", json);
}

static bool parse_start_ensaio(cJSON *root, ensaio_params_t *out)
{
    cJSON *on = cJSON_GetObjectItem(root, "on_sec");
    cJSON *off = cJSON_GetObjectItem(root, "off_sec");
    cJSON *dur = cJSON_GetObjectItem(root, "duracao_total_sec");
    if (!cJSON_IsNumber(on) || !cJSON_IsNumber(off) || !cJSON_IsNumber(dur)) {
        return false;
    }
    out->on_sec = (uint32_t)on->valuedouble;
    out->off_sec = (uint32_t)off->valuedouble;
    out->total_sec = (uint32_t)dur->valuedouble;
    return pure_ensaio_params_valid(out->on_sec, out->off_sec, out->total_sec);
}

static bool enqueue_ensaio_work(ensaio_params_t params)
{
    if (s_pzem_busy || s_ensaio_running) {
        return false;
    }
    pzem_work_item_t item = {
        .type = PZEM_WORK_ENSAIO,
        .duration_sec = 0,
        .ensaio = params,
    };
    return xQueueSend(s_pzem_queue, &item, 0) == pdTRUE;
}

static void ensaio_delay_sec(uint32_t sec)
{
    for (uint32_t t = 0; t < sec && !s_ensaio_stop; t++) {
        vTaskDelay(pdMS_TO_TICKS(1000));
        esp_task_wdt_reset();
    }
}

static void handle_start_ensaio(ensaio_params_t params)
{
    app_state_t restore_state;
    batch_lock();
    restore_state = s_batch.active ? STATE_BATCH_READY : STATE_IDLE;
    batch_unlock();

    s_ensaio_running = true;
    s_ensaio_stop = false;
    state_machine_set(STATE_TESTING);
    button_set_test_in_progress(true);
    publish_ensaio_msg("iniciado", &params, 0, NULL, 0, 0, NULL);

    uint32_t elapsed = 0;
    uint32_t ciclo = 0;

    while (elapsed < params.total_sec && !s_ensaio_stop) {
        ciclo++;
        uint32_t on = params.on_sec;
        if (elapsed + on > params.total_sec) {
            on = params.total_sec - elapsed;
        }
        relay_set(true);
        publish_ensaio_msg("ciclo", NULL, ciclo, "ligado", elapsed, 0, NULL);
        ensaio_delay_sec(on);
        elapsed += on;
        relay_set(false);

        if (elapsed >= params.total_sec || s_ensaio_stop) {
            break;
        }

        uint32_t off = params.off_sec;
        if (elapsed + off > params.total_sec) {
            off = params.total_sec - elapsed;
        }
        publish_ensaio_msg("ciclo", NULL, ciclo, "desligado", elapsed, 0, NULL);
        ensaio_delay_sec(off);
        elapsed += off;
    }

    relay_set(false);
    button_set_test_in_progress(false);
    s_ensaio_running = false;
    publish_ensaio_msg("concluido", NULL, 0, NULL, elapsed, ciclo,
                       s_ensaio_stop ? "parado" : "duracao");
    state_machine_set(restore_state);
}

static void handle_stop_ensaio(void)
{
    if (s_ensaio_running) {
        s_ensaio_stop = true;
    } else {
        mqtt_bridge_publish_rejection("ensaio_inativo");
    }
}

static void handle_ota_update(cJSON *root)
{
    if (!state_machine_can_accept_ota()) {
        mqtt_bridge_publish_rejection("ota_estado_invalido");
        return;
    }
    cJSON *url = cJSON_GetObjectItem(root, "url");
    if (!cJSON_IsString(url) || !pure_ota_url_allowed(url->valuestring, OTA_ALLOWED_EXTRA_HOST)) {
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

static void handle_reset_wifi(cJSON *root)
{
    if (state_machine_get() == STATE_TESTING || s_calibrating || s_ensaio_running) {
        mqtt_bridge_publish_rejection("reset_wifi_durante_teste");
        return;
    }
    if (ota_update_is_active() || state_machine_get() == STATE_OTA_UPDATING) {
        mqtt_bridge_publish_rejection("reset_wifi_durante_ota");
        return;
    }

    bool clear_mqtt = false;
    cJSON *opt = cJSON_GetObjectItem(root, "clear_mqtt");
    if (cJSON_IsBool(opt) && cJSON_IsTrue(opt)) {
        clear_mqtt = true;
    }

    ESP_LOGW(TAG, "reset Wi-Fi solicitado (clear_mqtt=%s)", clear_mqtt ? "sim" : "nao");
    publish_or_queue("status", "{\"tipo\":\"wifi\",\"evento\":\"reset_iniciado\"}");
    vTaskDelay(pdMS_TO_TICKS(500));

    if (!wifi_prov_clear_credentials()) {
        mqtt_bridge_publish_rejection("reset_wifi_falha");
        return;
    }
    if (clear_mqtt) {
        mqtt_config_clear();
    }
    esp_restart();
}

static void handle_set_bancada(cJSON *root)
{
    if (state_machine_get() == STATE_TESTING || s_calibrating || s_ensaio_running) {
        mqtt_bridge_publish_rejection("set_bancada_durante_teste");
        return;
    }
    if (ota_update_is_active() || state_machine_get() == STATE_OTA_UPDATING) {
        mqtt_bridge_publish_rejection("set_bancada_durante_ota");
        return;
    }

    cJSON *num = cJSON_GetObjectItem(root, "bancada");
    if (!cJSON_IsNumber(num)) {
        mqtt_bridge_publish_rejection("set_bancada_invalida");
        return;
    }
    int bancada = (int)num->valuedouble;
    if (bancada < 1 || bancada > 99) {
        mqtt_bridge_publish_rejection("set_bancada_invalida");
        return;
    }

    const char *site = MQTT_DEFAULT_SITE;
    cJSON *site_json = cJSON_GetObjectItem(root, "site");
    if (cJSON_IsString(site_json) && site_json->valuestring[0] != '\0') {
        site = site_json->valuestring;
    }

    if (!mqtt_topics_save((uint8_t)bancada, site)) {
        mqtt_bridge_publish_rejection("set_bancada_falha");
        return;
    }

    ESP_LOGI(TAG, "bancada atualizada para %s/bancada-%02d — reiniciando", site, bancada);
    publish_or_queue("status", "{\"tipo\":\"station\",\"evento\":\"bancada_atualizada\"}");
    vTaskDelay(pdMS_TO_TICKS(500));
    esp_restart();
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
    } else if (strcmp(cmd->valuestring, "END_BATCH") == 0 ||
               strcmp(cmd->valuestring, "CANCEL_BATCH") == 0) {
        handle_end_batch();
    } else if (strcmp(cmd->valuestring, "START_CALIBRATION") == 0) {
        if (!state_machine_can_accept_calibration()) {
            mqtt_bridge_publish_rejection("calibracao_estado_invalido");
        } else if (pzem_is_fault()) {
            mqtt_bridge_publish_rejection("calibracao_pzem_falha");
        } else if (!enqueue_pzem_work(PZEM_WORK_CALIBRATION, 0)) {
            mqtt_bridge_publish_rejection("pzem_ocupado");
        }
    } else if (strcmp(cmd->valuestring, "START_ENSAIO") == 0) {
        ensaio_params_t params;
        if (s_ensaio_running) {
            mqtt_bridge_publish_rejection("ensaio_ja_ativo");
        } else if (s_calibrating) {
            mqtt_bridge_publish_rejection("ensaio_estado_invalido");
        } else if (state_machine_get() == STATE_TESTING) {
            mqtt_bridge_publish_rejection("ensaio_durante_teste");
        } else if (!state_machine_can_accept_calibration()) {
            mqtt_bridge_publish_rejection("ensaio_estado_invalido");
        } else if (!parse_start_ensaio(root, &params)) {
            mqtt_bridge_publish_rejection("ensaio_campos_invalidos");
        } else if (!enqueue_ensaio_work(params)) {
            mqtt_bridge_publish_rejection("pzem_ocupado");
        }
    } else if (strcmp(cmd->valuestring, "STOP_ENSAIO") == 0) {
        handle_stop_ensaio();
    } else if (strcmp(cmd->valuestring, "OTA_UPDATE") == 0) {
        handle_ota_update(root);
    } else if (strcmp(cmd->valuestring, "PZEM_PROBE") == 0) {
        handle_pzem_probe();
    } else if (strcmp(cmd->valuestring, "RESET_WIFI") == 0) {
        handle_reset_wifi(root);
    } else if (strcmp(cmd->valuestring, "SET_BANCADA") == 0) {
        handle_set_bancada(root);
    } else {
        mqtt_bridge_publish_rejection("cmd_desconhecido");
    }

    cJSON_Delete(root);
}

static bool mqtt_cmd_is_blocked(const char *payload)
{
    if (state_machine_get() != STATE_TESTING && !s_calibrating && !s_ensaio_running &&
        !ota_update_is_active() && state_machine_get() != STATE_OTA_UPDATING) {
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

    static const char *blocked[] = {
        "SET_BATCH", "END_BATCH", "CANCEL_BATCH", "START_CALIBRATION", "START_ENSAIO",
        "OTA_UPDATE", "PZEM_PROBE", "RESET_WIFI", "SET_BANCADA", NULL
    };
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
    if (mqtt_cmd_is_blocked(payload)) {
        if (ota_update_is_active() || state_machine_get() == STATE_OTA_UPDATING) {
            mqtt_bridge_publish_rejection("cmd_durante_ota");
        } else {
            mqtt_bridge_publish_rejection("cmd_durante_teste");
        }
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
        } else if (item.type == PZEM_WORK_ENSAIO) {
            handle_start_ensaio(item.ensaio);
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
            if (s_ensaio_running) {
                ESP_LOGI(TAG, "botao — parar ensaio");
                s_ensaio_stop = true;
            } else if (!s_calibrating) {
                int64_t now = esp_timer_get_time();
                if (s_last_button_press_us > 0 &&
                    (now - s_last_button_press_us) < 800000LL &&
                    state_machine_get() == STATE_BATCH_READY) {
                    ESP_LOGI(TAG, "duplo toque — cancelar lote");
                    handle_end_batch_with_reason("botao_duplo");
                    s_last_button_press_us = 0;
                } else {
                    s_last_button_press_us = now;
                    uint32_t duration;
                    batch_lock();
                    duration = s_batch.tempo_teste_sec;
                    batch_unlock();
                    enqueue_pzem_work(PZEM_WORK_TEST, duration);
                }
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
    static char s_wifi_ssid[33];
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

    batch_lock();
    out->batch_nvs_fault = s_batch_nvs_fault;
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
    batch_unlock();
    return true;
}

static bool ota_post_boot_smoke(void)
{
#if CONFIG_DEV_MOCK_PZEM
    return true;
#else
    float power = 0;
    for (int i = 0; i < 3; i++) {
        if (pzem_probe_read(&power)) {
            ESP_LOGI(TAG, "OTA smoke test PZEM OK: %.1f W", power);
            return true;
        }
        vTaskDelay(pdMS_TO_TICKS(100));
    }
    ESP_LOGE(TAG, "OTA smoke test PZEM falhou");
    return false;
#endif
}

static void publish_hardware_fault(const char *falha)
{
    char alerta[128];
    snprintf(alerta, sizeof(alerta), "{\"tipo\":\"hardware\",\"falha\":\"%s\"}", falha);
    publish_or_queue("alerta", alerta);
}

static void enter_hardware_fault(app_state_t restore_state, const char *falha)
{
    if (state_machine_get() != STATE_HARDWARE_FAULT) {
        s_state_before_fault = restore_state;
        state_machine_set(STATE_HARDWARE_FAULT);
        led_feedback_signal(FEEDBACK_FAULT);
        publish_hardware_fault(falha);
    }
}

static void on_pzem_fault(bool fault)
{
    if (!fault) {
        return;
    }
    app_state_t restore = state_machine_get();
    if (restore == STATE_TESTING) {
        restore = s_batch.active ? STATE_BATCH_READY : STATE_IDLE;
    }
    enter_hardware_fault(restore, "pzem_uart");
    relay_set(false);
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
        }

        if (!button_is_test_in_progress() && state_machine_get() != STATE_TESTING && !s_calibrating &&
            !s_ensaio_running &&
            !ota_update_is_active() && state_machine_get() != STATE_OTA_UPDATING &&
            button_is_pressed()) {
            button_hold_ms += 100;
            if (button_hold_ms >= WIFI_RESET_BUTTON_HOLD_MS) {
                ESP_LOGW(TAG, "botao pressionado %d ms — reset Wi-Fi", WIFI_RESET_BUTTON_HOLD_MS);
                publish_or_queue("status", "{\"tipo\":\"wifi\",\"evento\":\"reset_botao\"}");
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

void app_main(void)
{
    ESP_ERROR_CHECK(nvs_flash_init());
    ota_update_erase_factory_data_if_pending();

    s_batch_mu = xSemaphoreCreateMutex();

    relay_init_safe();
    device_id_init();
    state_machine_init(NULL);
    led_feedback_init();
    pzem_init(on_pzem_fault);
    ota_update_init(on_ota_status);
    ota_update_set_smoke_test(ota_post_boot_smoke);
    ota_update_mark_valid_on_boot();

    s_work_queue = xQueueCreate(4, sizeof(work_item_t));
    s_button_queue = xQueueCreate(4, sizeof(uint8_t));
    s_pzem_queue = xQueueCreate(2, sizeof(pzem_work_item_t));
    button_init(s_button_queue);
    offline_queue_init();
    telemetry_init();

#if !CONFIG_DEV_MOCK_PZEM
    bool boot_pzem_fault = false;
    if (!pzem_boot_self_test()) {
        boot_pzem_fault = true;
        s_state_before_fault = STATE_IDLE;
        state_machine_set(STATE_HARDWARE_FAULT);
        led_feedback_signal(FEEDBACK_FAULT);
        publish_hardware_fault("pzem_uart_boot");
    }
#endif

    ESP_LOGI(TAG, "device_id=%s firmware=%s", device_id_get(), FIRMWARE_VERSION);

    memset(&s_batch, 0, sizeof(s_batch));
    bool batch_loaded = batch_storage_load(&s_batch);
#if !CONFIG_DEV_MOCK_PZEM
    if (!boot_pzem_fault) {
        if (batch_loaded) {
            state_machine_set(STATE_BATCH_READY);
            ESP_LOGI(TAG, "lote restaurado OP=%s seq=%lu", s_batch.numero_op,
                     (unsigned long)s_batch.proximo_sequencial);
        } else {
            state_machine_set(STATE_IDLE);
        }
    } else if (batch_loaded) {
        s_state_before_fault = STATE_BATCH_READY;
        ESP_LOGW(TAG, "lote OP=%s em RAM — PZEM em falha, aguardando recuperacao",
                 s_batch.numero_op);
    }
#else
    if (batch_loaded) {
        state_machine_set(STATE_BATCH_READY);
        ESP_LOGI(TAG, "lote restaurado OP=%s seq=%lu", s_batch.numero_op,
                 (unsigned long)s_batch.proximo_sequencial);
    } else {
        state_machine_set(STATE_IDLE);
    }
#endif

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

    mqtt_topics_init();
    wifi_prov_apply_factory_mqtt_station();
    if (!mqtt_topics_is_configured()) {
        ESP_LOGW(TAG, "bancada nao configurada — modo provisionamento");
        state_machine_set(STATE_PROVISIONING);
        wifi_prov_start_softap_portal();
        return;
    }

    time_sync_start();

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
