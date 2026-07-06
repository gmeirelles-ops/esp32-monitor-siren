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
#include "mqtt_topics.h"
#include "nvs.h"
#include "esp_mac.h"
#include "esp_random.h"
#include "nvs_flash.h"
#include <stdlib.h>

static const char *TAG = "wifi_prov";
static EventGroupHandle_t s_wifi_events;
static const int WIFI_CONNECTED_BIT = BIT0;
static uint32_t s_reconnect_delay_ms = WIFI_RECONNECT_BASE_MS;
static char s_scan_html[4096];
static bool s_wifi_driver_ready;
static bool s_event_handlers_registered;
static bool s_ap_netif_ready;
static bool s_sta_netif_ready;
static httpd_handle_t s_portal_server;

static void wifi_event_handler(void *arg, esp_event_base_t base, int32_t id, void *data);

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

static esp_err_t ensure_netif_and_events(void)
{
    esp_err_t err = esp_netif_init();
    if (err != ESP_OK && err != ESP_ERR_INVALID_STATE) {
        return err;
    }
    err = esp_event_loop_create_default();
    if (err != ESP_OK && err != ESP_ERR_INVALID_STATE) {
        return err;
    }
    return ESP_OK;
}

static esp_err_t ensure_wifi_driver(void)
{
    esp_err_t err = ensure_netif_and_events();
    if (err != ESP_OK) {
        return err;
    }
    if (!s_wifi_driver_ready) {
        wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
        err = esp_wifi_init(&cfg);
        if (err != ESP_OK) {
            return err;
        }
        s_wifi_driver_ready = true;
    }
    if (!s_event_handlers_registered) {
        err = esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, wifi_event_handler, NULL);
        if (err != ESP_OK) {
            return err;
        }
        err = esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, wifi_event_handler, NULL);
        if (err != ESP_OK) {
            return err;
        }
        s_event_handlers_registered = true;
    }
    return ESP_OK;
}

static void ensure_wifi_netifs(void)
{
    if (!s_ap_netif_ready) {
        esp_netif_create_default_wifi_ap();
        s_ap_netif_ready = true;
    }
    if (!s_sta_netif_ready) {
        esp_netif_create_default_wifi_sta();
        s_sta_netif_ready = true;
    }
}

static void apply_wifi_country_and_compat(void)
{
    wifi_country_t country = {
        .cc = "BR",
        .schan = 1,
        .nchan = 13,
        .policy = WIFI_COUNTRY_POLICY_AUTO,
    };
    esp_wifi_set_country(&country);
    esp_wifi_set_ps(WIFI_PS_NONE);
    esp_wifi_set_storage(WIFI_STORAGE_RAM);
}

void wifi_prov_derive_ap_password(char *out, size_t len)
{
    if (!out || len == 0) {
        return;
    }
    if (WIFI_AP_PASS[0] != '\0') {
        strncpy(out, WIFI_AP_PASS, len - 1);
        out[len - 1] = '\0';
        return;
    }
    uint8_t mac[6] = {0};
    esp_read_mac(mac, ESP_MAC_WIFI_SOFTAP);
    snprintf(out, len, "sv%02x%02x%02x", mac[3], mac[4], mac[5]);
}

static void fill_ap_config(wifi_config_t *ap_cfg)
{
    memset(ap_cfg, 0, sizeof(*ap_cfg));
    strncpy((char *)ap_cfg->ap.ssid, WIFI_AP_SSID, sizeof(ap_cfg->ap.ssid) - 1);
    ap_cfg->ap.ssid_len = (uint8_t)strlen(WIFI_AP_SSID);
    ap_cfg->ap.channel = 6;
    ap_cfg->ap.max_connection = 4;
    ap_cfg->ap.ssid_hidden = 0;
    ap_cfg->ap.pmf_cfg.required = false;
    ap_cfg->ap.pmf_cfg.capable = true;
    char ap_pass[65] = {0};
    wifi_prov_derive_ap_password(ap_pass, sizeof(ap_pass));
    if (ap_pass[0] != '\0') {
        strncpy((char *)ap_cfg->ap.password, ap_pass, sizeof(ap_cfg->ap.password) - 1);
        ap_cfg->ap.authmode = WIFI_AUTH_WPA_WPA2_PSK;
    } else {
        ap_cfg->ap.authmode = WIFI_AUTH_OPEN;
    }
}

static esp_err_t wifi_start_portal_ap(void)
{
    esp_err_t err = ensure_wifi_driver();
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "ensure_wifi_driver: %s", esp_err_to_name(err));
        return err;
    }
    ensure_wifi_netifs();
    apply_wifi_country_and_compat();

    esp_wifi_stop();
    vTaskDelay(pdMS_TO_TICKS(150));

    wifi_config_t ap_cfg;
    fill_ap_config(&ap_cfg);

    err = esp_wifi_set_mode(WIFI_MODE_APSTA);
    if (err != ESP_OK) {
        return err;
    }
    err = esp_wifi_set_config(WIFI_IF_AP, &ap_cfg);
    if (err != ESP_OK) {
        return err;
    }
    err = esp_wifi_set_protocol(WIFI_IF_AP, WIFI_PROTOCOL_11B | WIFI_PROTOCOL_11G | WIFI_PROTOCOL_11N);
    if (err != ESP_OK) {
        ESP_LOGW(TAG, "set_protocol AP: %s", esp_err_to_name(err));
    }
    err = esp_wifi_set_bandwidth(WIFI_IF_AP, WIFI_BW_HT20);
    if (err != ESP_OK) {
        ESP_LOGW(TAG, "set_bandwidth AP: %s", esp_err_to_name(err));
    }
    err = esp_wifi_start();
    if (err != ESP_OK) {
        return err;
    }

    ESP_LOGI(TAG, "AP ativo: ssid=%s canal=%d auth=%d", WIFI_AP_SSID, ap_cfg.ap.channel,
             (int)ap_cfg.ap.authmode);
    return ESP_OK;
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
        if (s_wifi_events) {
            xEventGroupSetBits(s_wifi_events, WIFI_CONNECTED_BIT);
        }
    } else if (base == WIFI_EVENT && id == WIFI_EVENT_STA_DISCONNECTED) {
        if (s_wifi_events) {
            xEventGroupClearBits(s_wifi_events, WIFI_CONNECTED_BIT);
        }
        schedule_wifi_reconnect();
    }
}

void wifi_prov_apply_factory_mqtt_station(void)
{
    mqtt_topics_init();
    if (!mqtt_topics_is_configured() && STATION_DEFAULT_BANCADA >= 1 && STATION_DEFAULT_BANCADA <= 99) {
        mqtt_topics_save((uint8_t)STATION_DEFAULT_BANCADA, MQTT_DEFAULT_SITE);
    }
    mqtt_config_save(MQTT_DEFAULT_HOST, MQTT_DEFAULT_PORT_TLS, MQTT_DEFAULT_USER, MQTT_DEFAULT_PASS, true);
}

static void build_portal_html(void)
{
    char ap_pass[65] = {0};
    wifi_prov_derive_ap_password(ap_pass, sizeof(ap_pass));

    snprintf(s_scan_html, sizeof(s_scan_html),
             "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Wi-Fi</title></head>"
             "<body><h1>Configurar Wi-Fi</h1>"
             "<p>Conecte-se à rede <b>%s</b>"
             "%s"
             " e abra <a href='http://%s'>http://%s</a></p>"
             "<form method='POST' action='/save'>"
             "Rede: <select name='ssid'>",
             WIFI_AP_SSID,
             ap_pass[0] != '\0' ? " com senha <b>" : " (aberta",
             WIFI_AP_IP, WIFI_AP_IP);
    if (ap_pass[0] != '\0') {
        strncat(s_scan_html, ap_pass, sizeof(s_scan_html) - strlen(s_scan_html) - 1);
        strncat(s_scan_html, "</b>", sizeof(s_scan_html) - strlen(s_scan_html) - 1);
    }

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

    char footer[800];
    snprintf(footer, sizeof(footer),
             "</select><br>SSID manual: <input name='ssid_manual' maxlength='32'><br>"
             "Senha Wi-Fi: <input name='pass' type='password' maxlength='64'><br>"
             "<small>Broker MQTT e bancada já vêm do firmware.</small><br>"
             "<button type='submit'>Salvar</button></form></body></html>");
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
    sta_cfg.sta.pmf_cfg.capable = true;
    sta_cfg.sta.pmf_cfg.required = false;

    esp_err_t err = esp_wifi_set_mode(WIFI_MODE_APSTA);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "set_mode APSTA: %s", esp_err_to_name(err));
        return false;
    }
    err = esp_wifi_set_config(WIFI_IF_STA, &sta_cfg);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "set_config STA: %s", esp_err_to_name(err));
        return false;
    }
    esp_wifi_disconnect();
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

static esp_err_t save_post(httpd_req_t *req)
{
    char body[512];
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
    wifi_prov_apply_factory_mqtt_station();
    ESP_LOGI(TAG, "Wi-Fi salvo; broker/bancada de fabrica aplicados (bancada %d)",
             STATION_DEFAULT_BANCADA);
    httpd_resp_sendstr(req, "Wi-Fi validado e salvo. Reiniciando...");
    vTaskDelay(pdMS_TO_TICKS(1000));
    esp_restart();
    return ESP_OK;
}

static void start_portal_http(void)
{
    if (s_portal_server != NULL) {
        return;
    }
    httpd_config_t http_cfg = HTTPD_DEFAULT_CONFIG();
    http_cfg.server_port = 80;
    http_cfg.lru_purge_enable = true;
    http_cfg.recv_wait_timeout = 10;
    if (httpd_start(&s_portal_server, &http_cfg) != ESP_OK) {
        ESP_LOGE(TAG, "falha ao iniciar servidor HTTP");
        return;
    }
    httpd_uri_t root = {.uri = "/", .method = HTTP_GET, .handler = root_get};
    httpd_uri_t save = {.uri = "/save", .method = HTTP_POST, .handler = save_post};
    httpd_register_uri_handler(s_portal_server, &root);
    httpd_register_uri_handler(s_portal_server, &save);
    if (WIFI_AP_PASS[0] != '\0') {
        ESP_LOGI(TAG, "portal http://%s — rede %s", WIFI_AP_IP, WIFI_AP_SSID);
    } else {
        char ap_pass[65] = {0};
        wifi_prov_derive_ap_password(ap_pass, sizeof(ap_pass));
        ESP_LOGI(TAG, "portal http://%s — rede %s senha %s (MAC)", WIFI_AP_IP, WIFI_AP_SSID, ap_pass);
    }
}

bool wifi_prov_clear_credentials(void)
{
    nvs_handle_t handle;
    if (nvs_open(WIFI_NVS_NAMESPACE, NVS_READWRITE, &handle) != ESP_OK) {
        return false;
    }
    esp_err_t err = nvs_erase_all(handle);
    if (err == ESP_OK) {
        err = nvs_commit(handle);
    }
    nvs_close(handle);
    return err == ESP_OK;
}

bool wifi_prov_get_ssid(char *ssid, size_t ssid_len)
{
    if (!ssid || ssid_len == 0) {
        return false;
    }
    ssid[0] = '\0';
    return wifi_prov_load_credentials(ssid, ssid_len, NULL, 0);
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
    if (wifi_start_portal_ap() != ESP_OK) {
        ESP_LOGE(TAG, "falha ao iniciar AP de provisionamento");
        return;
    }
    start_portal_http();
}

bool wifi_prov_connect_sta(void)
{
    if (!s_wifi_events) {
        s_wifi_events = xEventGroupCreate();
    }

    esp_err_t err = ensure_wifi_driver();
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "ensure_wifi_driver: %s", esp_err_to_name(err));
        return false;
    }
    if (!s_sta_netif_ready) {
        esp_netif_create_default_wifi_sta();
        s_sta_netif_ready = true;
    }
    apply_wifi_country_and_compat();

    char ssid[33] = {0};
    char pass[65] = {0};
    if (!wifi_prov_load_credentials(ssid, sizeof(ssid), pass, sizeof(pass))) {
        return false;
    }

    esp_wifi_stop();
    vTaskDelay(pdMS_TO_TICKS(150));

    wifi_config_t sta_cfg = {0};
    strncpy((char *)sta_cfg.sta.ssid, ssid, sizeof(sta_cfg.sta.ssid) - 1);
    strncpy((char *)sta_cfg.sta.password, pass, sizeof(sta_cfg.sta.password) - 1);
    sta_cfg.sta.pmf_cfg.capable = true;
    sta_cfg.sta.pmf_cfg.required = false;

    err = esp_wifi_set_mode(WIFI_MODE_STA);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "set_mode STA: %s", esp_err_to_name(err));
        return false;
    }
    err = esp_wifi_set_config(WIFI_IF_STA, &sta_cfg);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "set_config STA: %s", esp_err_to_name(err));
        return false;
    }
    err = esp_wifi_start();
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "wifi_start STA: %s", esp_err_to_name(err));
        return false;
    }

    xEventGroupClearBits(s_wifi_events, WIFI_CONNECTED_BIT);
    EventBits_t bits = xEventGroupWaitBits(s_wifi_events, WIFI_CONNECTED_BIT, pdFALSE, pdTRUE,
                                           pdMS_TO_TICKS(WIFI_STA_VALIDATE_TIMEOUT_MS));
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
