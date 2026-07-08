#include "batch_cmd.h"

#include <stdio.h>
#include <string.h>

#include "app_runtime.h"
#include "batch_storage.h"
#include "board_config.h"
#include "button.h"
#include "led_feedback.h"
#include "mqtt_bridge.h"
#include "mqtt_cmd.h"
#include "ota_update.h"
#include "oled_display.h"
#include "pzem.h"
#include "pure_logic.h"
#include "relay.h"
#include "state_machine.h"
#include "telemetry.h"
#include "time_sync.h"

static void publish_test_result(bool approved, float potencia_media, uint32_t sequencial_usado)
{
    batch_context_t *batch = app_batch();
    char numero_op[16];
    char id_produto[4];
    char ano[3];
    uint32_t aprovados;
    app_batch_lock();
    strncpy(numero_op, batch->numero_op, sizeof(numero_op) - 1);
    strncpy(id_produto, batch->id_produto, sizeof(id_produto) - 1);
    strncpy(ano, batch->ano, sizeof(ano) - 1);
    aprovados = batch->aprovados;
    app_batch_unlock();

    char json[448];
    snprintf(json, sizeof(json),
             "{\"tipo\":\"teste\",\"ts_ms\":%lld,\"ts_unix\":%lld,"
             "\"numero_op\":\"%s\",\"id_produto\":\"%s\",\"ano\":\"%s\","
             "\"veredito\":\"%s\",\"potencia_media\":%.2f,\"sequencial\":%lu,\"aprovados_no_lote\":%lu}",
             (long long)app_now_ts_ms(), (long long)time_sync_unix(),
             numero_op, id_produto, ano,
             approved ? "APROVADO" : "REPROVADO", potencia_media,
             (unsigned long)sequencial_usado, (unsigned long)aprovados);
    app_publish_or_queue("status", json);
}

void batch_cmd_publish_ack(void)
{
    batch_context_t *batch = app_batch();
    char numero_op[16];
    app_batch_lock();
    strncpy(numero_op, batch->numero_op, sizeof(numero_op) - 1);
    app_batch_unlock();

    char json[224];
    snprintf(json, sizeof(json),
             "{\"tipo\":\"batch\",\"evento\":\"configurado\",\"ts_ms\":%lld,\"numero_op\":\"%s\",\"estado\":\"BATCH_READY\"}",
             (long long)app_now_ts_ms(), numero_op);
    app_publish_or_queue("status", json);
}

void batch_cmd_publish_nvs_fault(void)
{
    char json[128];
    snprintf(json, sizeof(json),
             "{\"tipo\":\"alerta\",\"evento\":\"batch_nvs_fault\",\"detalhe\":\"falha ao persistir lote\"}");
    app_publish_or_queue("alerta", json);
    led_feedback_signal(FEEDBACK_FAULT);
}

void batch_cmd_run_test_cycle(uint32_t duration_sec)
{
    batch_context_t *batch = app_batch();
    bool *nvs_fault = app_batch_nvs_fault();

    if (!state_machine_can_start_test() || pzem_is_fault() || ota_update_is_active()) {
        return;
    }

    if (*nvs_fault) {
        led_feedback_signal(FEEDBACK_FAULT);
        if (mqtt_bridge_is_connected()) {
            mqtt_bridge_publish_rejection("batch_nvs_fault");
        }
        return;
    }

    app_batch_lock();
    if (pure_batch_quota_reached(batch->aprovados, batch->quantidade_total)) {
        app_batch_unlock();
        led_feedback_signal(FEEDBACK_REJECTED);
        if (mqtt_bridge_is_connected()) {
            mqtt_bridge_publish_rejection("lote_cheio");
        }
        return;
    }

    float pot_min = batch->potencia_min;
    float pot_max = batch->potencia_max;
    bool modo_reteste = batch->modo_reteste;
    uint32_t quantidade_total = batch->quantidade_total;
    app_batch_unlock();

    state_machine_set(STATE_TESTING);
    button_set_test_in_progress(true);
    relay_set(true);

    pzem_cycle_result_t result = {0};
    bool ok = pzem_measure_cycle(duration_sec, INRUSH_DISCARD_MS, &result, NULL, NULL);

    relay_set(false);
    button_set_test_in_progress(false);

    if (pzem_is_fault() || !ok || result.uart_error) {
        hardware_fault_enter(STATE_BATCH_READY, "pzem_uart");
        return;
    }

    bool approved = pure_verdict_approved(result.average_w, pot_min, pot_max);
    uint32_t sequencial_usado;

    app_batch_lock();
    sequencial_usado = batch->proximo_sequencial;

    if (approved) {
        if (pure_batch_approval_updates_counters(modo_reteste, approved)) {
            uint32_t prev_aprovados = batch->aprovados;
            uint32_t prev_sequencial = batch->proximo_sequencial;
            batch->aprovados++;
            batch->proximo_sequencial++;
            if (!batch_storage_save(batch)) {
                batch->aprovados = prev_aprovados;
                batch->proximo_sequencial = prev_sequencial;
                *nvs_fault = true;
                app_batch_unlock();
                batch_cmd_publish_nvs_fault();
            } else {
                *nvs_fault = false;
                app_batch_unlock();
            }
        } else {
            app_batch_unlock();
        }
        led_feedback_signal(FEEDBACK_APPROVED);
    } else {
        app_batch_unlock();
        led_feedback_signal(FEEDBACK_REJECTED);
    }

    publish_test_result(approved, result.average_w, sequencial_usado);
    oled_display_on_test_result(approved, result.average_w);
    app_batch_lock();
    oled_display_set_batch(batch->numero_op, batch->aprovados, batch->proximo_sequencial);
    app_batch_unlock();

    bool quota_done = false;
    app_batch_lock();
    quota_done = approved && !modo_reteste &&
                 pure_batch_quota_reached(batch->aprovados, quantidade_total);
    app_batch_unlock();

    if (quota_done) {
        state_machine_set(STATE_BATCH_READY);
        batch_cmd_end_batch_with_reason("cota_atingida");
    } else {
        state_machine_set(STATE_BATCH_READY);
    }
}

bool batch_cmd_parse_set_batch(cJSON *root)
{
    batch_context_t *batch = app_batch();
    bool *nvs_fault = app_batch_nvs_fault();
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
    app_batch_lock();
    backup = *batch;

    bool same_op = batch->active && pure_batch_same_op(batch->numero_op, in.numero_op);
    uint32_t preserved_aprovados = same_op ? batch->aprovados : 0;
    uint32_t preserved_sequencial = same_op ? batch->proximo_sequencial : in.proximo_sequencial;
    bool preserved_reteste = same_op ? batch->modo_reteste : false;
    if (same_op && in.proximo_sequencial > preserved_sequencial) {
        preserved_sequencial = in.proximo_sequencial;
    }

    item = cJSON_GetObjectItem(root, "modo_reteste");
    bool modo_reteste = preserved_reteste;
    if (cJSON_IsBool(item)) {
        modo_reteste = cJSON_IsTrue(item);
    }

    strcpy(batch->numero_op, in.numero_op);
    strcpy(batch->id_produto, in.id_produto);
    strcpy(batch->ano, in.ano);
    batch->tempo_teste_sec = in.tempo_teste_sec;
    batch->potencia_min = in.potencia_min;
    batch->potencia_max = in.potencia_max;
    batch->quantidade_total = in.quantidade_total;
    batch->proximo_sequencial = preserved_sequencial;
    batch->aprovados = preserved_aprovados;
    batch->modo_reteste = modo_reteste;
    batch->active = true;

    if (!batch_storage_save(batch)) {
        *batch = backup;
        *nvs_fault = true;
        app_batch_unlock();
        batch_cmd_publish_nvs_fault();
        return false;
    }
    *nvs_fault = false;
    app_batch_unlock();
    state_machine_set(STATE_BATCH_READY);
    telemetry_publish_now();
    batch_cmd_publish_ack();
    oled_display_set_batch(batch->numero_op, batch->aprovados, batch->proximo_sequencial);
    return true;
}

void batch_cmd_end_batch_with_reason(const char *motivo)
{
    if (state_machine_get() == STATE_TESTING) {
        mqtt_bridge_publish_rejection("end_batch_durante_teste");
        return;
    }
    if (*app_calibrating()) {
        mqtt_bridge_publish_rejection("end_batch_durante_calibracao");
        return;
    }
    if (*app_ensaio_running()) {
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
    app_publish_or_queue("status", json);
    app_batch_lock();
    memset(app_batch(), 0, sizeof(batch_context_t));
    app_batch_unlock();
    batch_storage_clear();
    state_machine_set(STATE_IDLE);
    telemetry_publish_now();
    oled_display_set_batch(NULL, 0, 0);
}

void batch_cmd_end_batch(void)
{
    batch_cmd_end_batch_with_reason(NULL);
}
