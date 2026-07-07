#include "calibration.h"

#include <stdio.h>
#include <string.h>

#include "app_runtime.h"
#include "board_config.h"
#include "button.h"
#include "device_id.h"
#include "mqtt_bridge.h"
#include "mqtt_cmd.h"
#include "mqtt_topics.h"
#include "pzem.h"
#include "relay.h"
#include "state_machine.h"

static void publish_calibracao_msg(const char *evento, float potencia_w, uint32_t elapsed_ms,
                                   float potencia_media)
{
    char json[320];
    int64_t ts_ms = app_now_ts_ms();
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
    app_publish_or_queue("calibracao", json);
}

static void on_calibration_sample(float power_w, uint32_t elapsed_ms, void *ctx)
{
    (void)ctx;
    publish_calibracao_msg("amostra", power_w, elapsed_ms, 0);
}

void calibration_handle_start(void)
{
    if (!state_machine_can_accept_calibration()) {
        mqtt_bridge_publish_rejection("calibracao_estado_invalido");
        return;
    }
    if (pzem_is_fault()) {
        mqtt_bridge_publish_rejection("calibracao_pzem_falha");
        return;
    }

    batch_context_t *batch = app_batch();
    app_state_t restore_state;
    app_batch_lock();
    restore_state = batch->active ? STATE_BATCH_READY : STATE_IDLE;
    app_batch_unlock();

    *app_calibrating() = true;
    publish_calibracao_msg("iniciado", 0, 0, 0);
    state_machine_set(STATE_TESTING);
    button_set_test_in_progress(true);
    relay_set(true);

    pzem_cycle_result_t result = {0};
    bool ok = pzem_measure_cycle(CALIBRATION_SEC, INRUSH_DISCARD_MS, &result,
                                 on_calibration_sample, NULL);

    relay_set(false);
    button_set_test_in_progress(false);
    *app_calibrating() = false;

    if (pzem_is_fault() || !ok || result.uart_error) {
        publish_calibracao_msg("falha", 0, 0, 0);
        hardware_fault_enter(restore_state, "pzem_uart_calibracao");
        return;
    }

    publish_calibracao_msg("concluido", 0, 0, result.average_w);
    state_machine_set(restore_state);
}
