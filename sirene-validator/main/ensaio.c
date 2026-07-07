#include "ensaio.h"

#include <stdio.h>
#include <string.h>

#include "app_runtime.h"
#include "button.h"
#include "cJSON.h"
#include "device_id.h"
#include "esp_task_wdt.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "mqtt_bridge.h"
#include "mqtt_topics.h"
#include "pure_logic.h"
#include "relay.h"
#include "state_machine.h"

static void publish_ensaio_msg(const char *evento, const ensaio_params_t *params,
                               uint32_t n, const char *fase, uint32_t elapsed_sec,
                               uint32_t ciclos, const char *motivo)
{
    char json[384];
    int64_t ts_ms = app_now_ts_ms();
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
    app_publish_or_queue("ensaio", json);
}

static void ensaio_delay_sec(uint32_t sec)
{
    volatile bool *stop = app_ensaio_stop();
    for (uint32_t t = 0; t < sec && !*stop; t++) {
        vTaskDelay(pdMS_TO_TICKS(1000));
        esp_task_wdt_reset();
    }
}

bool ensaio_parse_start(cJSON *root, ensaio_params_t *out)
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

bool ensaio_enqueue_work(ensaio_params_t params)
{
    if (*app_pzem_busy() || *app_ensaio_running()) {
        return false;
    }
    return app_enqueue_pzem_work(PZEM_WORK_ENSAIO, 0, &params);
}

void ensaio_handle_start(ensaio_params_t params)
{
    batch_context_t *batch = app_batch();
    app_state_t restore_state;
    app_batch_lock();
    restore_state = batch->active ? STATE_BATCH_READY : STATE_IDLE;
    app_batch_unlock();

    *app_ensaio_running() = true;
    *app_ensaio_stop() = false;
    state_machine_set(STATE_TESTING);
    button_set_test_in_progress(true);
    publish_ensaio_msg("iniciado", &params, 0, NULL, 0, 0, NULL);

    uint32_t elapsed = 0;
    uint32_t ciclo = 0;
    volatile bool *stop = app_ensaio_stop();

    while (elapsed < params.total_sec && !*stop) {
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

        if (elapsed >= params.total_sec || *stop) {
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
    *app_ensaio_running() = false;
    publish_ensaio_msg("concluido", NULL, 0, NULL, elapsed, ciclo,
                       *stop ? "parado" : "duracao");
    state_machine_set(restore_state);
}

void ensaio_handle_stop(void)
{
    if (*app_ensaio_running()) {
        *app_ensaio_stop() = true;
    } else {
        mqtt_bridge_publish_rejection("ensaio_inativo");
    }
}
