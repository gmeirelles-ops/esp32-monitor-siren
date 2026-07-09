#include "batch_cmd.h"



#include <stdio.h>

#include <string.h>



#include "app_runtime.h"

#include "batch_storage.h"

#include "board_config.h"

#include "button.h"

#include "esp_log.h"

#include "esp_timer.h"

#include "led_feedback.h"

#include "line_actuator.h"

#include "mqtt_bridge.h"

#include "mqtt_cmd.h"

#include "ota_update.h"

#include "oled_display.h"

#include "pzem.h"

#include "pure_logic.h"

#include "relay.h"

#include "sdkconfig.h"

#include "state_machine.h"

#include "telemetry.h"

#include "offline_queue.h"
#include "time_sync.h"



static const char *TAG = "batch_cmd";



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



#if CONFIG_LINE_ACTUATOR_ENABLE && CONFIG_LINE_ACTUATOR_PUBLISH_TELEMETRY

static void publish_actuator_event(const char *evento, int gpio, uint16_t duracao_ms)

{

    if (gpio < 0) {

        return;

    }

    char json[192];

    snprintf(json, sizeof(json),

             "{\"tipo\":\"atuador\",\"evento\":\"%s\",\"ts_ms\":%lld,\"gpio\":%d,\"duracao_ms\":%u}",

             evento, (long long)app_now_ts_ms(), gpio, (unsigned)duracao_ms);

    app_publish_or_queue("status", json);

}

#else

static void publish_actuator_event(const char *evento, int gpio, uint16_t duracao_ms)

{

    (void)evento;

    (void)gpio;

    (void)duracao_ms;

}

#endif



typedef struct {

    bool approved;

    bool modo_reteste;

    float potencia_media;

    uint32_t sequencial_usado;

    uint32_t quantidade_total;

    int64_t measure_end_us;

} batch_verdict_ctx_t;



/**

 * Contract 004: NVS → MQTT/estado → GPIO/LED → OLED.

 * On NVS failure after approval counter update, MUST NOT pulse GPIO/actuator.

 */

static void batch_cmd_apply_verdict(batch_verdict_ctx_t *ctx)

{

    batch_context_t *batch = app_batch();

    bool *nvs_fault = app_batch_nvs_fault();



    app_batch_lock();

    if (ctx->approved) {

        if (pure_batch_approval_updates_counters(ctx->modo_reteste, ctx->approved)) {

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

                return;

            }

            *nvs_fault = false;

        }

    }

    uint32_t aprovados_now = batch->aprovados;

    app_batch_unlock();

    /* MQTT + estado antes de GPIO/OLED (I2C lento) — app vê APROVADO sem esperar 30s. */
    app_last_test_set(ctx->approved, ctx->potencia_media, ctx->sequencial_usado, app_now_ts_ms());
    publish_test_result(ctx->approved, ctx->potencia_media, ctx->sequencial_usado);
    offline_queue_sync_now();
    telemetry_publish_now();

    bool quota_done = ctx->approved && !ctx->modo_reteste &&
                      pure_batch_quota_reached(aprovados_now, ctx->quantidade_total);
    if (quota_done) {
        state_machine_set(STATE_BATCH_READY);
        batch_cmd_end_batch_with_reason("cota_atingida");
    } else {
        state_machine_set(STATE_BATCH_READY);
    }

    if (ctx->measure_end_us > 0) {
        if (ctx->approved) {

            led_feedback_signal(FEEDBACK_APPROVED);

            line_actuator_on_approved(!ctx->modo_reteste);

        } else {

            led_feedback_signal(FEEDBACK_REJECTED);

            line_actuator_on_rejected();

        }

        int64_t gpio_done_us = esp_timer_get_time();

        int64_t latency_us = gpio_done_us - ctx->measure_end_us;

        ESP_LOGI(TAG, "verdict_gpio_latency_us=%lld", (long long)latency_us);

        if (latency_us > 50000LL) {

            ESP_LOGW(TAG, "verdict_gpio_latency above 50ms target");

        }

    } else if (ctx->approved) {

        led_feedback_signal(FEEDBACK_APPROVED);

        line_actuator_on_approved(!ctx->modo_reteste);

    } else {

        led_feedback_signal(FEEDBACK_REJECTED);

        line_actuator_on_rejected();

    }



    if (ctx->approved) {
#if CONFIG_LINE_ACTUATOR_ENABLE
        publish_actuator_event("aprovacao_pulso", CONFIG_LINE_ACTUATOR_APPROVE_GPIO,
                               CONFIG_LINE_ACTUATOR_APPROVE_PULSE_MS);
#else
        publish_actuator_event("aprovacao_pulso", -1, 0);
#endif
    } else {

        publish_actuator_event("rejeicao_pulso", line_actuator_reject_gpio(),

                               line_actuator_reject_pulse_ms());

    }



    oled_display_on_test_result(ctx->approved, ctx->potencia_media);

    app_batch_lock();

    oled_display_set_batch(batch->numero_op, batch->aprovados, batch->proximo_sequencial);

    app_batch_unlock();


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

        if (pzem_is_fault() || state_machine_get() == STATE_HARDWARE_FAULT) {

            led_feedback_signal(FEEDBACK_REJECTED);

            mqtt_bridge_publish_rejection("pzem_falha");

        }

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

    telemetry_publish_now();

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

    int64_t measure_end_us = esp_timer_get_time();



    batch_verdict_ctx_t verdict = {

        .approved = approved,

        .modo_reteste = modo_reteste,

        .potencia_media = result.average_w,

        .sequencial_usado = 0,

        .quantidade_total = quantidade_total,

        .measure_end_us = measure_end_us,

    };



    app_batch_lock();

    verdict.sequencial_usado = batch->proximo_sequencial;

    app_batch_unlock();



    batch_cmd_apply_verdict(&verdict);

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

    item = cJSON_GetObjectItem(root, "modo_reteste");

    bool modo_reteste = false;

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

    batch->proximo_sequencial = in.proximo_sequencial;

    batch->aprovados = 0;

    batch->modo_reteste = modo_reteste;

    batch->active = true;

    app_last_test_clear();
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

    app_last_test_clear();

    batch_storage_clear();

    state_machine_set(STATE_IDLE);

    telemetry_publish_now();

    oled_display_set_batch(NULL, 0, 0);

}



void batch_cmd_end_batch(void)

{

    batch_cmd_end_batch_with_reason(NULL);

}


