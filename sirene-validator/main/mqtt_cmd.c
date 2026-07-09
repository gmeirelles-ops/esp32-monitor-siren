#include "mqtt_cmd.h"

#include <stdio.h>
#include <string.h>

#include "app_runtime.h"
#include "batch_cmd.h"
#include "batch_storage.h"
#include "board_config.h"
#include "calibration.h"
#include "cJSON.h"
#include "ensaio.h"
#include "esp_log.h"
#include "esp_system.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"
#include "button.h"
#include "led_feedback.h"
#include "line_actuator.h"
#include "mqtt_bridge.h"
#include "mqtt_config.h"
#include "mqtt_topics.h"
#include "ota_update.h"
#include "pzem.h"
#include "pure_logic.h"
#include "relay.h"
#include "sdkconfig.h"
#include "state_machine.h"
#include "wifi_prov.h"

static const char *TAG = "mqtt_cmd";

static app_state_t hardware_fault_normalize_restore(app_state_t restore_state)
{
    if (restore_state == STATE_TESTING) {
        return batch_storage_has_active() ? STATE_BATCH_READY : STATE_IDLE;
    }
    return restore_state;
}

void hardware_fault_enter(app_state_t restore_state, const char *falha)
{
    restore_state = hardware_fault_normalize_restore(restore_state);
    relay_set(false);
    button_set_test_in_progress(false);
    line_actuator_safe_all();

    bool was_fault = (state_machine_get() == STATE_HARDWARE_FAULT);
    if (state_machine_get() == STATE_TESTING) {
        state_machine_set(STATE_HARDWARE_FAULT);
        was_fault = false;
    }

    if (!was_fault) {
        if (state_machine_get() != STATE_HARDWARE_FAULT) {
            *app_state_before_fault() = restore_state;
            state_machine_set(STATE_HARDWARE_FAULT);
        }
        led_feedback_signal(FEEDBACK_FAULT);
        char alerta[128];
        snprintf(alerta, sizeof(alerta), "{\"tipo\":\"hardware\",\"falha\":\"%s\"}", falha);
        app_publish_or_queue("alerta", alerta);
        ESP_LOGW(TAG, "falha hardware: %s — testes bloqueados ate PZEM voltar (restaura %s)",
                 falha, state_machine_name(restore_state));
    }
}

static void handle_ota_update(cJSON *root)
{
    if (!state_machine_can_accept_ota()) {
        mqtt_bridge_publish_rejection("ota_estado_invalido");
        return;
    }
    cJSON *url = cJSON_GetObjectItem(root, "url");
#if CONFIG_SIRENE_OTA_REQUIRE_HTTPS
    bool require_https = true;
#else
    bool require_https = false;
#endif
    if (!cJSON_IsString(url) ||
        !pure_ota_url_allowed_ex(url->valuestring, OTA_ALLOWED_EXTRA_HOST, require_https)) {
        mqtt_bridge_publish_rejection("ota_url_invalida");
        return;
    }
    state_machine_set(STATE_OTA_UPDATING);
    if (!ota_update_start(url->valuestring)) {
        state_machine_set(batch_storage_has_active() ? STATE_BATCH_READY : STATE_IDLE);
        mqtt_bridge_publish_rejection("ota_falha_inicio");
    }
}

static void handle_reset_wifi(cJSON *root)
{
    if (state_machine_get() == STATE_TESTING || *app_calibrating() || *app_ensaio_running()) {
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
    app_publish_or_queue("status", "{\"tipo\":\"wifi\",\"evento\":\"reset_iniciado\"}");
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
    if (state_machine_get() == STATE_TESTING || *app_calibrating() || *app_ensaio_running()) {
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
        if (!pure_site_name_valid(site_json->valuestring)) {
            mqtt_bridge_publish_rejection("set_bancada_invalida");
            return;
        }
        site = site_json->valuestring;
    }

    if (!mqtt_topics_save((uint8_t)bancada, site)) {
        mqtt_bridge_publish_rejection("set_bancada_falha");
        return;
    }

    ESP_LOGI(TAG, "bancada atualizada para %s/bancada-%02d — reiniciando", site, bancada);
    app_publish_or_queue("status", "{\"tipo\":\"station\",\"evento\":\"bancada_atualizada\"}");
    vTaskDelay(pdMS_TO_TICKS(500));
    esp_restart();
}

void mqtt_cmd_process_payload(const char *payload)
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
            if (state_machine_get() == STATE_TESTING) {
                mqtt_bridge_publish_rejection("config_durante_teste");
            } else {
                mqtt_bridge_publish_rejection("set_batch_durante_teste");
            }
        } else if (!batch_cmd_parse_set_batch(root)) {
            mqtt_bridge_publish_rejection("set_batch_campos_invalidos");
        }
    } else if (strcmp(cmd->valuestring, "END_BATCH") == 0 ||
               strcmp(cmd->valuestring, "CANCEL_BATCH") == 0) {
        batch_cmd_end_batch();
    } else if (strcmp(cmd->valuestring, "START_CALIBRATION") == 0) {
        if (!state_machine_can_accept_calibration()) {
            mqtt_bridge_publish_rejection("calibracao_estado_invalido");
        } else if (pzem_is_fault()) {
            mqtt_bridge_publish_rejection("calibracao_pzem_falha");
        } else {
            uint32_t duration_sec = 0;
            cJSON *tempo = cJSON_GetObjectItem(root, "tempo_teste");
            if (cJSON_IsNumber(tempo) && tempo->valuedouble >= 1.0 && tempo->valuedouble <= 120.0) {
                duration_sec = (uint32_t)tempo->valuedouble;
            }
            if (!app_enqueue_pzem_work(PZEM_WORK_CALIBRATION, duration_sec, NULL)) {
                mqtt_bridge_publish_rejection("pzem_ocupado");
            }
        }
    } else if (strcmp(cmd->valuestring, "START_ENSAIO") == 0) {
        ensaio_params_t params;
        if (*app_ensaio_running()) {
            mqtt_bridge_publish_rejection("ensaio_ja_ativo");
        } else if (*app_calibrating()) {
            mqtt_bridge_publish_rejection("ensaio_estado_invalido");
        } else if (state_machine_get() == STATE_TESTING) {
            mqtt_bridge_publish_rejection("ensaio_durante_teste");
        } else if (!state_machine_can_accept_calibration()) {
            mqtt_bridge_publish_rejection("ensaio_estado_invalido");
        } else if (!ensaio_parse_start(root, &params)) {
            mqtt_bridge_publish_rejection("ensaio_campos_invalidos");
        } else if (!ensaio_enqueue_work(params)) {
            mqtt_bridge_publish_rejection("pzem_ocupado");
        }
    } else if (strcmp(cmd->valuestring, "STOP_ENSAIO") == 0) {
        ensaio_handle_stop();
    } else if (strcmp(cmd->valuestring, "OTA_UPDATE") == 0) {
        handle_ota_update(root);
    } else if (strcmp(cmd->valuestring, "PZEM_PROBE") == 0) {
        if (!app_enqueue_pzem_work(PZEM_WORK_PROBE, 0, NULL)) {
            mqtt_bridge_publish_rejection("pzem_ocupado");
        }
    } else if (strcmp(cmd->valuestring, "RESET_WIFI") == 0) {
        handle_reset_wifi(root);
    } else if (strcmp(cmd->valuestring, "SET_BANCADA") == 0) {
        handle_set_bancada(root);
    } else {
        mqtt_bridge_publish_rejection("cmd_desconhecido");
    }

    cJSON_Delete(root);
}

bool mqtt_cmd_is_blocked(const char *payload)
{
    if (state_machine_get() != STATE_TESTING && !*app_calibrating() && !*app_ensaio_running() &&
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

void mqtt_cmd_on_command(const char *payload, int len)
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
    if (xQueueSend(app_work_queue(), &item, 0) != pdTRUE) {
        mqtt_bridge_publish_rejection("fila_cheia");
    }
}
