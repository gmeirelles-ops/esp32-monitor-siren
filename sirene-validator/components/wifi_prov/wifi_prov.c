#include "wifi_prov.h"

#include <stdio.h>
#include <string.h>

#include "board_config.h"
#include "esp_event.h"
#include "esp_http_server.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "esp_wifi.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "freertos/task.h"
#include "mqtt_config.h"
#include "nvs.h"
#include "esp_random.h"
#include "nvs_flash.h"
#include <stdlib.h>

static const char *TAG = "wifi_prov";
static EventGroupHandle_t s_wifi_events;
static const int WIFI_CONNECTED_BIT = BIT0;
static uint32_t s_reconnect_delay_ms = WIFI_RECONNECT_BASE_MS;
static char s_scan_html[4096];

static int hex_value(char c)
{
    if (c >= '0' && c <= '9') {
        return c - '0';
    }
    if (c >= 'a' && c <= 'f') {
        return c - 'a' + 10;
    }
    if (c >= 'A' && c <= 'F') {
        return c - 'A' + 10;
    }
    return -1;
}

static void url_decode_inplace(char *s)
{
    char *src = s;
    char *dst = s;
    while (*src) {
        if (*src == '+') {
            *dst++ = ' ';
            src++;
        } else if (*src == '%' && src[1] && src[2]) {
            int hi = hex_value(src[1]);
            int lo = hex_value(src[2]);
            if (hi >= 0 && lo >= 0) {
                *dst++ = (char)((hi << 4) | lo);
                src += 3;
            } else {
                *dst++ = *src++;
            }
        } else {
            *dst++ = *src++;
        }
    }
    *dst = '\0';
}

static void html_escape(const char *src, char *dst, size_t dst_len)
{
    size_t j = 0;
    for (size_t i = 0; src[i] != '\0' && j + 1 < dst_len; i++) {
        const char *rep = NULL;
        switch (src[i]) {
        case '&': rep = "&amp;"; break;
        case '<': rep = "&lt;"; break;
        case '>': rep = "&gt;"; break;
        case '"': rep = "&quot;"; break;
        default: break;
        }
        if (rep) {
            size_t len = strlen(rep);
            if (j + len >= dst_len) {
                break;
            }
            memcpy(dst + j, rep, len);
            j += len;
        } else {
            dst[j++] = src[i];
        }
    }
    dst[j] = '\0';
}

static bool parse_form_value(const char *body, const char *key, char *out, size_t out_len)
{
    char pattern[32];
    snprintf(pattern, sizeof(pattern), "%s=", key);
    const char *start = strstr(body, pattern);
    if (!start) {
        return false;
    }
    start += strlen(pattern);
    const char *end = strchr(start, '&');
    size_t len = end ? (size_t)(end - start) : strlen(start);
    if (len >= out_len) {
        len = out_len - 1;
    }
    memcpy(out, start, len);
    out[len] = '\0';
    url_decode_inplace(out);
    return out[0] != '\0';
}

static void reconnect_task(void *arg)
{
    (void)arg;
    uint32_t jitter = esp_random() % 500;
    vTaskDelay(pdMS_TO_TICKS(s_reconnect_delay_ms + jitter));
    esp_wifi_connect();
    if (s_reconnect_delay_ms < WIFI_RECONNECT_MAX_MS) {
        s_reconnect_delay_ms *= 2;
        if (s_reconnect_delay_ms > WIFI_RECONNECT_MAX_MS) {
            s_reconnect_delay_ms = WIFI_RECONNECT_MAX_MS;
        }
    }
    vTaskDelete(NULL);
}

static void schedule_wifi_reconnect(void)
{
    xTaskCreate(reconnect_task, "wifi_reconn", 2048, NULL, 4, NULL);
}

static void wifi_event_handler(void *arg, esp_event_base_t base, int32_t id, void *data)
{
    (void)arg;
    (void)data;
    if (base == WIFI_EVENT && id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (base == IP_EVENT && id == IP_EVENT_STA_GOT_IP) {
        s_reconnect_delay_ms = WIFI_RECONNECT_BASE_MS;
        xEventGroupSetBits(s_wifi_events, WIFI_CONNECTED_BIT);
    } else if (base == WIFI_EVENT && id == WIFI_EVENT_STA_DISCONNECTED) {
        xEventGroupClearBits(s_wifi_events, WIFI_CONNECTED_BIT);
        schedule_wifi_reconnect();
    }
}

static void build_portal_html(void)
{
    char mqtt_host[65] = {0};
    uint32_t mqtt_port = MQTT_DEFAULT_PORT;
    if (!mqtt_config_load(mqtt_host, sizeof(mqtt_host), &mqtt_port)) {
        mqtt_host[0] = '\0';
        mqtt_port = MQTT_DEFAULT_PORT;
    }

    snprintf(s_scan_html, sizeof(s_scan_html),
             "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Wi-Fi</title></head>"
             "<body><h1>Configurar Wi-Fi</h1>"
             "<form method='POST' action='/save'>"
             "Rede: <select name='ssid'>");

    wifi_scan_config_t scan_cfg = {0};
    esp_wifi_scan_start(&scan_cfg, true);
    uint16_t count = 0;
    esp_wifi_scan_get_ap_num(&count);
    wifi_ap_record_t *records = calloc(count, sizeof(wifi_ap_record_t));
    if (records && count > 0) {
        esp_wifi_scan_get_ap_records(&count, records);
        for (int i = 0; i < count; i++) {
            char escaped[80];
            char option[256];
            html_escape((const char *)records[i].ssid, escaped, sizeof(escaped));
            int written = snprintf(option, sizeof(option),
                                   "<option value=\"%s\">%s (%d dBm)</option>",
                                   escaped, escaped, records[i].rssi);
            if (written > 0 && (size_t)written < sizeof(option)) {
                strncat(s_scan_html, option, sizeof(s_scan_html) - strlen(s_scan_html) - 1);
            }
        }
    }
    free(records);

    char footer[512];
    snprintf(footer, sizeof(footer),
             "</select><br>SSID manual: <input name='ssid_manual' maxlength='32'><br>"
             "Senha: <input name='pass' type='password' maxlength='64'><br>"
             "<h2>Broker MQTT (opcional)</h2>"
             "Host: <input name='mqtt_host' maxlength='64' value='%s'><br>"
             "Porta: <input name='mqtt_port' type='number' min='1' max='65535' value='%lu'><br>"
             "<small>Deixe host vazio para usar o fallback de fábrica.</small><br>"
             "<button type='submit'>Salvar</button></form></body></html>",
             mqtt_host[0] != '\0' ? mqtt_host : "",
             (unsigned long)mqtt_port);
    strncat(s_scan_html, footer, sizeof(s_scan_html) - strlen(s_scan_html) - 1);
}

static bool try_sta_connect(const char *ssid, const char *pass, uint32_t timeout_ms)
{
    if (!s_wifi_events) {
        s_wifi_events = xEventGroupCreate();
    }
    xEventGroupClearBits(s_wifi_events, WIFI_CONNECTED_BIT);

    wifi_config_t sta_cfg = {0};
    strncpy((char *)sta_cfg.sta.ssid, ssid, sizeof(sta_cfg.sta.ssid) - 1);
    strncpy((char *)sta_cfg.sta.password, pass, sizeof(sta_cfg.sta.password) - 1);
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &sta_cfg));
    esp_wifi_connect();

    EventBits_t bits = xEventGroupWaitBits(s_wifi_events, WIFI_CONNECTED_BIT, pdFALSE, pdTRUE,
                                           pdMS_TO_TICKS(timeout_ms));
    return (bits & WIFI_CONNECTED_BIT) != 0;
}

static esp_err_t root_get(httpd_req_t *req)
{
    build_portal_html();
    httpd_resp_send(req, s_scan_html, HTTPD_RESP_USE_STRLEN);
    return ESP_OK;
}

static bool parse_port_value(const char *body, const char *key, uint32_t *out_port)
{
    char value[16] = {0};
    if (!parse_form_value(body, key, value, sizeof(value))) {
        return false;
    }
    char *end = NULL;
    unsigned long port = strtoul(value, &end, 10);
    if (end == value || port == 0 || port > 65535) {
        return false;
    }
    *out_port = (uint32_t)port;
    return true;
}

static esp_err_t save_post(httpd_req_t *req)
{
    char body[768];
    int received = httpd_req_recv(req, body, sizeof(body) - 1);
    if (received <= 0) {
        httpd_resp_send_500(req);
        return ESP_FAIL;
    }
    body[received] = '\0';

    char ssid[33] = {0};
    char pass[65] = {0};
    if (!parse_form_value(body, "ssid_manual", ssid, sizeof(ssid))) {
        parse_form_value(body, "ssid", ssid, sizeof(ssid));
    }
    parse_form_value(body, "pass", pass, sizeof(pass));

    char mqtt_host[65] = {0};
    parse_form_value(body, "mqtt_host", mqtt_host, sizeof(mqtt_host));
    uint32_t mqtt_port = MQTT_DEFAULT_PORT;
    if (!parse_port_value(body, "mqtt_port", &mqtt_port)) {
        mqtt_port = MQTT_DEFAULT_PORT;
    }

    if (ssid[0] == '\0') {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "SSID obrigatorio");
        return ESP_FAIL;
    }

    if (!try_sta_connect(ssid, pass, WIFI_STA_VALIDATE_TIMEOUT_MS)) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST,
                            "Falha ao conectar. Verifique SSID/senha e tente novamente.");
        return ESP_FAIL;
    }

    wifi_prov_save_credentials(ssid, pass);
    if (mqtt_host[0] != '\0') {
        if (!mqtt_config_save(mqtt_host, mqtt_port)) {
            httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "Falha ao salvar broker MQTT.");
            return ESP_FAIL;
        }
        ESP_LOGI(TAG, "broker MQTT salvo: %s:%lu", mqtt_host, (unsigned long)mqtt_port);
    }
    httpd_resp_sendstr(req, "Credenciais validadas e salvas. Reiniciando...");
    vTaskDelay(pdMS_TO_TICKS(1000));
    esp_restart();
    return ESP_OK;
}

bool wifi_prov_has_credentials(void)
{
    char ssid[33];
    return wifi_prov_load_credentials(ssid, sizeof(ssid), NULL, 0);
}

bool wifi_prov_load_credentials(char *ssid, size_t ssid_len, char *pass, size_t pass_len)
{
    nvs_handle_t handle;
    if (nvs_open(WIFI_NVS_NAMESPACE, NVS_READONLY, &handle) != ESP_OK) {
        return false;
    }
    size_t len = ssid_len;
    if (nvs_get_str(handle, WIFI_NVS_SSID_KEY, ssid, &len) != ESP_OK || ssid[0] == '\0') {
        nvs_close(handle);
        return false;
    }
    if (pass && pass_len > 0) {
        len = pass_len;
        nvs_get_str(handle, WIFI_NVS_PASS_KEY, pass, &len);
    }
    nvs_close(handle);
    return true;
}

bool wifi_prov_save_credentials(const char *ssid, const char *pass)
{
    nvs_handle_t handle;
    if (nvs_open(WIFI_NVS_NAMESPACE, NVS_READWRITE, &handle) != ESP_OK) {
        return false;
    }
    nvs_set_str(handle, WIFI_NVS_SSID_KEY, ssid);
    nvs_set_str(handle, WIFI_NVS_PASS_KEY, pass ? pass : "");
    esp_err_t err = nvs_commit(handle);
    nvs_close(handle);
    return err == ESP_OK;
}

void wifi_prov_start_softap_portal(void)
{
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_ap();
    esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));
    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, wifi_event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, wifi_event_handler, NULL));

    wifi_config_t ap_cfg = {0};
    strncpy((char *)ap_cfg.ap.ssid, WIFI_AP_SSID, sizeof(ap_cfg.ap.ssid) - 1);
    ap_cfg.ap.ssid_len = strlen(WIFI_AP_SSID);
    ap_cfg.ap.channel = 1;
    ap_cfg.ap.max_connection = 4;
    ap_cfg.ap.authmode = WIFI_AUTH_OPEN;

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_APSTA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_AP, &ap_cfg));
    ESP_ERROR_CHECK(esp_wifi_start());

    httpd_handle_t server = NULL;
    httpd_config_t http_cfg = HTTPD_DEFAULT_CONFIG();
    http_cfg.server_port = 80;
    if (httpd_start(&server, &http_cfg) == ESP_OK) {
        httpd_uri_t root = {.uri = "/", .method = HTTP_GET, .handler = root_get};
        httpd_uri_t save = {.uri = "/save", .method = HTTP_POST, .handler = save_post};
        httpd_register_uri_handler(server, &root);
        httpd_register_uri_handler(server, &save);
        ESP_LOGI(TAG, "Captive portal em http://%s (scan + validacao)", WIFI_AP_IP);
    }
}

bool wifi_prov_connect_sta(void)
{
    if (!s_wifi_events) {
        s_wifi_events = xEventGroupCreate();
    }

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));
    ESP_ERROR_CHECK(esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, wifi_event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, wifi_event_handler, NULL));

    char ssid[33] = {0};
    char pass[65] = {0};
    if (!wifi_prov_load_credentials(ssid, sizeof(ssid), pass, sizeof(pass))) {
        return false;
    }

    wifi_config_t sta_cfg = {0};
    strncpy((char *)sta_cfg.sta.ssid, ssid, sizeof(sta_cfg.sta.ssid) - 1);
    strncpy((char *)sta_cfg.sta.password, pass, sizeof(sta_cfg.sta.password) - 1);

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &sta_cfg));
    ESP_ERROR_CHECK(esp_wifi_start());

    EventBits_t bits = xEventGroupWaitBits(s_wifi_events, WIFI_CONNECTED_BIT, pdFALSE, pdTRUE, pdMS_TO_TICKS(15000));
    return (bits & WIFI_CONNECTED_BIT) != 0;
}

int wifi_prov_get_rssi(void)
{
    wifi_ap_record_t ap;
    if (esp_wifi_sta_get_ap_info(&ap) == ESP_OK) {
        return ap.rssi;
    }
    return -127;
}
