/**
 * @file main.c
 * @brief Bancada QA IoT Diponto v3.0 – FSM por potência (W) e tempo dinâmico (Firebase).
 */

#include <inttypes.h>
#include <stdio.h>
#include <string.h>

#include "cJSON.h"
#include "esp_http_client.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "nvs_flash.h"
#include "driver/gpio.h"

#include "pzem_sensor.h"
#include "wifi_manager.h"

/* -------------------------------------------------------------------------- */
/* Definições                                                                 */
/* -------------------------------------------------------------------------- */

#define FIREBASE_URL \
    "https://sistema-sirenes-qa-default-rtdb.firebaseio.com/teste_atual.json"

#define BUTTON_PIN          GPIO_NUM_0
#define SSR_PIN             GPIO_NUM_2

#define TEMPO_TESTE_DEFAULT_SEC  5
#define DEBOUNCE_MS              50
#define HANDSHAKE_POLL_MS        2000
#define IDLE_POLL_MS             10
#define PZEM_SAMPLE_INTERVAL_MS  200
#define PZEM_SAMPLE_MAX_COUNT    20

#define TASK_WIFI_STACK     6144
#define TASK_BENCH_STACK    10240
#define TASK_WIFI_PRIO      5
#define TASK_BENCH_PRIO     6

#define HTTP_RESP_BUF_SIZE  1024
#define HTTP_BODY_MAX       256

static const char *TAG = "bancada_v3";

/* -------------------------------------------------------------------------- */
/* Máquina de estados v3.0                                                    */
/* -------------------------------------------------------------------------- */

typedef enum {
    STATE_IDLE = 0,
    STATE_START,
    STATE_TESTING,
    STATE_SENDING,
    STATE_WAIT_HANDSHAKE,
} bench_state_t;

static bench_state_t s_state = STATE_IDLE;
static uint32_t s_potencia_lida = 0;
static uint32_t s_tempo_teste_sec = TEMPO_TESTE_DEFAULT_SEC;

/* -------------------------------------------------------------------------- */
/* GPIO                                                                       */
/* -------------------------------------------------------------------------- */

static esp_err_t gpio_init_bench(void)
{
    const gpio_config_t btn = {
        .pin_bit_mask = (1ULL << BUTTON_PIN),
        .mode         = GPIO_MODE_INPUT,
        .pull_up_en   = GPIO_PULLUP_ENABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type    = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&btn));

    const gpio_config_t ssr = {
        .pin_bit_mask = (1ULL << SSR_PIN),
        .mode         = GPIO_MODE_OUTPUT,
        .pull_up_en   = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type    = GPIO_INTR_DISABLE,
    };
    ESP_ERROR_CHECK(gpio_config(&ssr));

    gpio_set_level(SSR_PIN, 0);
    ESP_LOGI(TAG, "GPIO – botão=%d SSR=%d", (int)BUTTON_PIN, (int)SSR_PIN);
    return ESP_OK;
}

static bool button_pressed_debounced(void)
{
    if (gpio_get_level(BUTTON_PIN) != 0) {
        return false;
    }
    vTaskDelay(pdMS_TO_TICKS(DEBOUNCE_MS));
    return (gpio_get_level(BUTTON_PIN) == 0);
}

static void ssr_set(bool on)
{
    gpio_set_level(SSR_PIN, on ? 1 : 0);
    ESP_LOGI(TAG, "SSR %s", on ? "LIGADO (HIGH)" : "DESLIGADO (LOW)");
}

/* -------------------------------------------------------------------------- */
/* HTTP helpers                                                               */
/* -------------------------------------------------------------------------- */

typedef struct {
    char   buffer[HTTP_RESP_BUF_SIZE];
    int    length;
    bool   truncated;
} http_response_t;

static esp_err_t http_collect_event(esp_http_client_event_t *evt)
{
    http_response_t *resp = (http_response_t *)evt->user_data;
    if (resp == NULL || evt->event_id != HTTP_EVENT_ON_DATA) {
        return ESP_OK;
    }

    if (resp->length + evt->data_len >= (int)sizeof(resp->buffer) - 1) {
        resp->truncated = true;
        return ESP_OK;
    }

    memcpy(resp->buffer + resp->length, evt->data, evt->data_len);
    resp->length += evt->data_len;
    resp->buffer[resp->length] = '\0';
    return ESP_OK;
}

static esp_err_t firebase_http_request(esp_http_client_method_t method, const char *body,
                                       http_response_t *out_resp, int *out_status)
{
    if (!wifi_manager_is_connected()) {
        ESP_LOGW(TAG, "Wi-Fi offline – HTTP abortado");
        return ESP_ERR_INVALID_STATE;
    }

    http_response_t local = {0};
    http_response_t *resp = out_resp != NULL ? out_resp : &local;

    const esp_http_client_config_t cfg = {
        .url            = FIREBASE_URL,
        .method         = method,
        .timeout_ms     = 10000,
        .event_handler  = http_collect_event,
        .user_data      = resp,
    };

    esp_http_client_handle_t client = esp_http_client_init(&cfg);
    if (client == NULL) {
        ESP_LOGE(TAG, "esp_http_client_init falhou");
        return ESP_FAIL;
    }

    esp_http_client_set_header(client, "Content-Type", "application/json");
    if (body != NULL && (method == HTTP_METHOD_PATCH || method == HTTP_METHOD_PUT ||
                         method == HTTP_METHOD_POST)) {
        esp_http_client_set_post_field(client, body, (int)strlen(body));
    }

    esp_err_t err = esp_http_client_perform(client);
    const int http_status = esp_http_client_get_status_code(client);

    if (out_status != NULL) {
        *out_status = http_status;
    }

    if (err != ESP_OK) {
        ESP_LOGE(TAG, "HTTP perform erro: %s", esp_err_to_name(err));
    } else if (http_status < 200 || http_status >= 300) {
        ESP_LOGE(TAG, "HTTP status inválido: %d", http_status);
        err = ESP_FAIL;
    } else if (resp->truncated) {
        ESP_LOGE(TAG, "Resposta HTTP truncada (>%d B)", HTTP_RESP_BUF_SIZE - 1);
        err = ESP_ERR_NO_MEM;
    }

    esp_http_client_cleanup(client);
    return err;
}

static esp_err_t firebase_get(http_response_t *resp)
{
    int status = 0;
    const esp_err_t err = firebase_http_request(HTTP_METHOD_GET, NULL, resp, &status);
    if (err == ESP_OK) {
        ESP_LOGI(TAG, "GET OK (HTTP %d) – %d bytes", status, resp->length);
    }
    return err;
}

static esp_err_t firebase_patch_body(const char *json_body)
{
    int status = 0;
    const esp_err_t err =
        firebase_http_request(HTTP_METHOD_PATCH, json_body, NULL, &status);
    if (err == ESP_OK) {
        ESP_LOGI(TAG, "PATCH OK (HTTP %d) – %s", status, json_body);
    } else {
        ESP_LOGE(TAG, "PATCH falhou – payload: %s", json_body);
    }
    return err;
}

static esp_err_t firebase_patch_status(const char *status_str)
{
    char body[HTTP_BODY_MAX];
    snprintf(body, sizeof(body), "{\"status\":\"%s\"}", status_str);
    return firebase_patch_body(body);
}

/* -------------------------------------------------------------------------- */
/* cJSON – configuração e handshake                                           */
/* -------------------------------------------------------------------------- */

typedef struct {
    char status[32];
    int  tempo_teste_sec;
    bool ok;
} teste_config_t;

static bool cjson_get_status_aguardando(const cJSON *root, char *out, size_t out_len)
{
    const cJSON *item = cJSON_GetObjectItem(root, "status");
    if (!cJSON_IsString(item) || item->valuestring == NULL) {
        return false;
    }
    strncpy(out, item->valuestring, out_len - 1);
    out[out_len - 1] = '\0';
    return (strcmp(out, "AGUARDANDO") == 0);
}

static int cjson_get_tempo_teste(const cJSON *root)
{
    const cJSON *item = cJSON_GetObjectItem(root, "tempo_teste");
    if (cJSON_IsNumber(item)) {
        const int t = (int)item->valuedouble;
        return (t > 0) ? t : TEMPO_TESTE_DEFAULT_SEC;
    }
    ESP_LOGW(TAG, "Campo tempo_teste ausente – fallback %d s",
             TEMPO_TESTE_DEFAULT_SEC);
    return TEMPO_TESTE_DEFAULT_SEC;
}

static esp_err_t firebase_parse_config(const char *json, teste_config_t *cfg)
{
    if (json == NULL || cfg == NULL) {
        return ESP_ERR_INVALID_ARG;
    }

    memset(cfg, 0, sizeof(*cfg));
    cfg->tempo_teste_sec = TEMPO_TESTE_DEFAULT_SEC;

    cJSON *root = cJSON_Parse(json);
    if (root == NULL) {
        const char *err = cJSON_GetErrorPtr();
        ESP_LOGE(TAG, "cJSON_Parse falhou%s%s",
                 err != NULL ? ": " : "", err != NULL ? err : "");
        return ESP_FAIL;
    }

    if (!cjson_get_status_aguardando(root, cfg->status, sizeof(cfg->status))) {
        const cJSON *st = cJSON_GetObjectItem(root, "status");
        const char *atual = cJSON_IsString(st) ? st->valuestring : "(ausente)";
        ESP_LOGW(TAG, "Status não é AGUARDANDO – atual: \"%s\"", atual);
        cJSON_Delete(root);
        return ESP_ERR_INVALID_STATE;
    }

    cfg->tempo_teste_sec = cjson_get_tempo_teste(root);
    cfg->ok = true;
    cJSON_Delete(root);

    ESP_LOGI(TAG, "Config OK – status=%s tempo_teste=%d s",
             cfg->status, cfg->tempo_teste_sec);
    return ESP_OK;
}

static bool firebase_parse_handshake_aguardando(const char *json)
{
    if (json == NULL) {
        return false;
    }

    cJSON *root = cJSON_Parse(json);
    if (root == NULL) {
        ESP_LOGE(TAG, "Handshake: JSON inválido");
        return false;
    }

    char status[32] = {0};
    const bool ok = cjson_get_status_aguardando(root, status, sizeof(status));
    cJSON_Delete(root);

    if (ok) {
        ESP_LOGI(TAG, "Handshake – status=%s", status);
    }
    return ok;
}

/* -------------------------------------------------------------------------- */
/* STATE_START – leitura de configuração                                       */
/* -------------------------------------------------------------------------- */

static esp_err_t state_start_fetch_config(void)
{
    http_response_t resp = {0};

    ESP_LOGI(TAG, "[START] GET configuração Firebase…");
    const esp_err_t err = firebase_get(&resp);
    if (err != ESP_OK) {
        return err;
    }

    ESP_LOGI(TAG, "[START] Payload: %s", resp.buffer);

    teste_config_t cfg = {0};
    const esp_err_t parse_err = firebase_parse_config(resp.buffer, &cfg);
    if (parse_err != ESP_OK) {
        return parse_err;
    }

    s_tempo_teste_sec = (uint32_t)cfg.tempo_teste_sec;
    return ESP_OK;
}

/* -------------------------------------------------------------------------- */
/* STATE_TESTING – relé dinâmico + amostragem PZEM                              */
/* -------------------------------------------------------------------------- */

static uint32_t calc_sample_interval_ms(uint32_t tempo_ms)
{
    uint32_t interval = PZEM_SAMPLE_INTERVAL_MS;
    const uint32_t count = tempo_ms / interval;

    if (count > PZEM_SAMPLE_MAX_COUNT) {
        interval = tempo_ms / PZEM_SAMPLE_MAX_COUNT;
        if (interval < 100) {
            interval = 100;
        }
    }
    if (interval == 0) {
        interval = 100;
    }
    return interval;
}

static esp_err_t state_testing_run(void)
{
    const uint32_t tempo_ms = s_tempo_teste_sec * 1000U;
    const uint32_t sample_ms = calc_sample_interval_ms(tempo_ms);
    const TickType_t deadline = xTaskGetTickCount() + pdMS_TO_TICKS(tempo_ms);

    ESP_LOGI(TAG, "[TESTING] tempo_teste=%" PRIu32 " s (%" PRIu32 " ms), "
             "amostragem a cada %" PRIu32 " ms",
             s_tempo_teste_sec, tempo_ms, sample_ms);

    if (firebase_patch_status("TESTANDO") != ESP_OK) {
        ESP_LOGW(TAG, "[TESTING] PATCH TESTANDO falhou – prosseguindo mesmo assim");
    }

    ssr_set(true);
    s_potencia_lida = 0;

    uint32_t amostra = 0;
    while (xTaskGetTickCount() < deadline) {
        uint32_t potencia = 0;
        const esp_err_t pzem_err = pzem_sensor_read_power(&potencia);

        if (pzem_err == ESP_OK) {
            amostra++;
            if (potencia > s_potencia_lida) {
                s_potencia_lida = potencia;
            }
            ESP_LOGI(TAG, "[TESTING] amostra #%lu potência=%" PRIu32 " (%.2f W) "
                     "pico=%" PRIu32,
                     (unsigned long)amostra, potencia, potencia / 100.0f,
                     s_potencia_lida);
        } else {
            ESP_LOGW(TAG, "[TESTING] PZEM leitura falhou: %s",
                     esp_err_to_name(pzem_err));
        }

        const TickType_t now = xTaskGetTickCount();
        if (now >= deadline) {
            break;
        }

        const TickType_t remaining = deadline - now;
        const TickType_t delay_ticks = pdMS_TO_TICKS(sample_ms);
        vTaskDelay(delay_ticks < remaining ? delay_ticks : remaining);
    }

    ssr_set(false);
    ESP_LOGI(TAG, "[TESTING] concluído – pico potencia_lida=%" PRIu32 " (%.2f W)",
             s_potencia_lida, s_potencia_lida / 100.0f);
    return ESP_OK;
}

/* -------------------------------------------------------------------------- */
/* STATE_SENDING / WAIT_HANDSHAKE                                             */
/* -------------------------------------------------------------------------- */

static esp_err_t firebase_patch_concluido(void)
{
    char body[HTTP_BODY_MAX];
    snprintf(body, sizeof(body),
             "{\"status\":\"CONCLUIDO\",\"potencia_lida\":%" PRIu32 "}",
             s_potencia_lida);
    return firebase_patch_body(body);
}

static bool firebase_poll_handshake(void)
{
    http_response_t resp = {0};
    if (firebase_get(&resp) != ESP_OK) {
        return false;
    }
    return firebase_parse_handshake_aguardando(resp.buffer);
}

/* -------------------------------------------------------------------------- */
/* FSM – task principal                                                       */
/* -------------------------------------------------------------------------- */

static const char *state_name(bench_state_t st)
{
    switch (st) {
    case STATE_IDLE:            return "IDLE";
    case STATE_START:           return "START";
    case STATE_TESTING:         return "TESTING";
    case STATE_SENDING:         return "SENDING";
    case STATE_WAIT_HANDSHAKE:  return "WAIT_HANDSHAKE";
    default:                    return "?";
    }
}

static void bench_task(void *pv)
{
    (void)pv;

    wifi_manager_wait_connected();
    ESP_LOGI(TAG, "=== Diponto QA v3.0 – core %d – FSM: %s ===",
             xPortGetCoreID(), state_name(s_state));

    for (;;) {
        ESP_LOGD(TAG, "Estado atual: %s", state_name(s_state));

        switch (s_state) {
        case STATE_IDLE:
            if (button_pressed_debounced()) {
                ESP_LOGI(TAG, "[IDLE] Botão pressionado – buscar configuração");
                s_state = STATE_START;
            } else {
                vTaskDelay(pdMS_TO_TICKS(IDLE_POLL_MS));
            }
            break;

        case STATE_START:
            if (state_start_fetch_config() == ESP_OK) {
                ESP_LOGI(TAG, "[START] Autorizado – tempo_teste=%" PRIu32 " s",
                         s_tempo_teste_sec);
                s_state = STATE_TESTING;
            } else {
                ESP_LOGW(TAG, "[START] Ciclo abortado – bancada não liberada");
                s_state = STATE_IDLE;
            }
            break;

        case STATE_TESTING:
            state_testing_run();
            s_state = STATE_SENDING;
            ESP_LOGI(TAG, "Transição → %s", state_name(s_state));
            break;

        case STATE_SENDING:
            if (firebase_patch_concluido() == ESP_OK) {
                s_state = STATE_WAIT_HANDSHAKE;
                ESP_LOGI(TAG, "[SENDING] Resultado enviado – aguardando AGUARDANDO");
            } else {
                ESP_LOGW(TAG, "[SENDING] Reenvio em 2 s…");
                vTaskDelay(pdMS_TO_TICKS(2000));
            }
            break;

        case STATE_WAIT_HANDSHAKE:
            if (firebase_poll_handshake()) {
                ESP_LOGI(TAG, "[HANDSHAKE] App liberou – novo ciclo permitido");
                s_state = STATE_IDLE;
            } else {
                ESP_LOGD(TAG, "[HANDSHAKE] Aguardando… próximo GET em %d ms",
                         HANDSHAKE_POLL_MS);
                vTaskDelay(pdMS_TO_TICKS(HANDSHAKE_POLL_MS));
            }
            break;

        default:
            ESP_LOGW(TAG, "Estado inválido – reset IDLE");
            s_state = STATE_IDLE;
            break;
        }
    }
}

/* -------------------------------------------------------------------------- */
/* Wi-Fi                                                                      */
/* -------------------------------------------------------------------------- */

static void wifi_provision_task(void *pv)
{
    (void)pv;
    ESP_LOGI(TAG, "Task Wi-Fi (core %d)", xPortGetCoreID());
    ESP_ERROR_CHECK(wifi_manager_run());
    wifi_manager_supervisor_task(NULL);
}

/* -------------------------------------------------------------------------- */
/* app_main                                                                   */
/* -------------------------------------------------------------------------- */

void app_main(void)
{
    ESP_LOGI(TAG, "Bancada QA Diponto v3.0 – potência (W) + tempo dinâmico");

    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ESP_ERROR_CHECK(nvs_flash_init());
    }

    ESP_ERROR_CHECK(gpio_init_bench());
    ESP_ERROR_CHECK(pzem_sensor_init());
    ESP_ERROR_CHECK(wifi_manager_init());

    xTaskCreatePinnedToCore(wifi_provision_task, "wifi_prov",
                            TASK_WIFI_STACK, NULL, TASK_WIFI_PRIO, NULL, 0);

    xTaskCreatePinnedToCore(bench_task, "bench_fsm",
                            TASK_BENCH_STACK, NULL, TASK_BENCH_PRIO, NULL, 1);

    ESP_LOGI(TAG, "Tasks ativas: wifi_prov (0), bench_fsm (1)");
}
