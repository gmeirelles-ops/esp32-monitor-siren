/**
 * @file wifi_manager.c
 * @brief NVS + STA (timeout) + SoftAP com portal cativo (DNS + httpd).
 */

#include "wifi_manager.h"

#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "esp_check.h"
#include "esp_event.h"
#include "esp_http_server.h"
#include "esp_log.h"
#include "esp_mac.h"
#include "esp_netif.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "freertos/task.h"
#include "lwip/err.h"
#include "lwip/inet.h"
#include "lwip/netdb.h"
#include "lwip/sockets.h"
#include "nvs.h"
#include "nvs_flash.h"

/* -------------------------------------------------------------------------- */
/* Configuração                                                               */
/* -------------------------------------------------------------------------- */

#define NVS_NAMESPACE       "wifi_cfg"
#define NVS_KEY_SSID        "ssid"
#define NVS_KEY_PASS        "pass"

#define AP_SSID             "BANCADA-DIPONTO-SETUP"
#define AP_MAX_CONN         4

#define STA_CONNECT_MS      10000

#define WIFI_SSID_MAX       32
#define WIFI_PASS_MAX       64

#define DNS_PORT            53
#define DNS_MAX_LEN         256

static const char *TAG = "wifi_mgr";

static EventGroupHandle_t s_events;
static bool s_connected;
static esp_netif_t *s_netif_sta;
static esp_netif_t *s_netif_ap;

/* -------------------------------------------------------------------------- */
/* NVS                                                                        */
/* -------------------------------------------------------------------------- */

static esp_err_t nvs_load_credentials(char *ssid, size_t ssid_len,
                                    char *pass, size_t pass_len)
{
    nvs_handle_t handle;
    esp_err_t err = nvs_open(NVS_NAMESPACE, NVS_READONLY, &handle);
    if (err != ESP_OK) {
        return err;
    }

    size_t required = ssid_len;
    err = nvs_get_str(handle, NVS_KEY_SSID, ssid, &required);
    if (err != ESP_OK) {
        nvs_close(handle);
        return err;
    }

    if (ssid[0] == '\0') {
        nvs_close(handle);
        return ESP_ERR_NOT_FOUND;
    }

    required = pass_len;
    err = nvs_get_str(handle, NVS_KEY_PASS, pass, &required);
    if (err == ESP_ERR_NVS_NOT_FOUND) {
        pass[0] = '\0';
        err = ESP_OK;
    }

    nvs_close(handle);
    return err;
}

static esp_err_t nvs_save_credentials(const char *ssid, const char *pass)
{
    nvs_handle_t handle;
    esp_err_t err = nvs_open(NVS_NAMESPACE, NVS_READWRITE, &handle);
    if (err != ESP_OK) {
        return err;
    }

    err = nvs_set_str(handle, NVS_KEY_SSID, ssid);
    if (err == ESP_OK) {
        err = nvs_set_str(handle, NVS_KEY_PASS, pass != NULL ? pass : "");
    }
    if (err == ESP_OK) {
        err = nvs_commit(handle);
    }

    nvs_close(handle);
    return err;
}

/* -------------------------------------------------------------------------- */
/* Eventos Wi-Fi STA                                                          */
/* -------------------------------------------------------------------------- */

static void sta_event_handler(void *arg, esp_event_base_t event_base,
                              int32_t event_id, void *event_data)
{
    (void)arg;

    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        s_connected = false;
        xEventGroupClearBits(s_events, WIFI_MANAGER_CONNECTED_BIT);
        ESP_LOGW(TAG, "STA desconectado – reconectando…");
        esp_wifi_connect();
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        const ip_event_got_ip_t *ev = (const ip_event_got_ip_t *)event_data;
        ESP_LOGI(TAG, "STA conectado – IP: " IPSTR, IP2STR(&ev->ip_info.ip));
        s_connected = true;
        xEventGroupSetBits(s_events, WIFI_MANAGER_CONNECTED_BIT);
    }
}

static void ap_event_handler(void *arg, esp_event_base_t event_base,
                             int32_t event_id, void *event_data)
{
    (void)arg;

    if (event_id == WIFI_EVENT_AP_STACONNECTED) {
        const wifi_event_ap_staconnected_t *ev =
            (const wifi_event_ap_staconnected_t *)event_data;
        ESP_LOGI(TAG, "Cliente associado ao AP: " MACSTR, MAC2STR(ev->mac));
    } else if (event_id == WIFI_EVENT_AP_STADISCONNECTED) {
        const wifi_event_ap_stadisconnected_t *ev =
            (const wifi_event_ap_stadisconnected_t *)event_data;
        ESP_LOGW(TAG, "Cliente saiu do AP: " MACSTR " (razão %d)",
                 MAC2STR(ev->mac), ev->reason);
    }
}

/* -------------------------------------------------------------------------- */
/* STA                                                                        */
/* -------------------------------------------------------------------------- */

static esp_err_t wifi_start_sta(const char *ssid, const char *pass)
{
    ESP_RETURN_ON_FALSE(ssid != NULL && ssid[0] != '\0', ESP_ERR_INVALID_ARG,
                        TAG, "SSID vazio");

    if (s_netif_sta == NULL) {
        s_netif_sta = esp_netif_create_default_wifi_sta();
    }

    wifi_config_t cfg = {0};
    strncpy((char *)cfg.sta.ssid, ssid, sizeof(cfg.sta.ssid) - 1);
    if (pass != NULL) {
        strncpy((char *)cfg.sta.password, pass, sizeof(cfg.sta.password) - 1);
    }

    if (pass == NULL || pass[0] == '\0') {
        cfg.sta.threshold.authmode = WIFI_AUTH_OPEN;
    } else {
        cfg.sta.threshold.authmode = WIFI_AUTH_WPA2_PSK;
    }

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &cfg));
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "Tentando STA – SSID: %s (timeout %d ms)", ssid, STA_CONNECT_MS);
    esp_wifi_connect();

    const EventBits_t bits = xEventGroupWaitBits(
        s_events, WIFI_MANAGER_CONNECTED_BIT, pdFALSE, pdTRUE,
        pdMS_TO_TICKS(STA_CONNECT_MS));

    if ((bits & WIFI_MANAGER_CONNECTED_BIT) != 0) {
        return ESP_OK;
    }

    ESP_LOGW(TAG, "Timeout STA (%d ms) – SSID: %s", STA_CONNECT_MS, ssid);
    esp_wifi_stop();
    s_connected = false;
    xEventGroupClearBits(s_events, WIFI_MANAGER_CONNECTED_BIT);
    return ESP_ERR_TIMEOUT;
}

/* -------------------------------------------------------------------------- */
/* DNS (portal cativo – redireciona consultas A para o IP do SoftAP)          */
/* -------------------------------------------------------------------------- */

#define DNS_OPCODE_MASK  (0x7800)
#define DNS_QR_FLAG      (1 << 7)
#define DNS_QD_TYPE_A    (0x0001)
#define DNS_ANS_TTL_SEC  (300)

typedef struct __attribute__((__packed__)) {
    uint16_t id;
    uint16_t flags;
    uint16_t qd_count;
    uint16_t an_count;
    uint16_t ns_count;
    uint16_t ar_count;
} dns_header_t;

typedef struct {
    uint16_t type;
    uint16_t class;
} dns_question_t;

typedef struct __attribute__((__packed__)) {
    uint16_t ptr_offset;
    uint16_t type;
    uint16_t class;
    uint32_t ttl;
    uint16_t addr_len;
    uint32_t ip_addr;
} dns_answer_t;

static char *dns_parse_name(char *raw, char *out, size_t out_max)
{
    char *label = raw;
    char *itr = out;
    int total = 0;

    do {
        int sub = *label;
        total += sub + 1;
        if (total > (int)out_max) {
            return NULL;
        }
        memcpy(itr, label + 1, (size_t)sub);
        itr[sub] = '.';
        itr += sub + 1;
        label += sub + 1;
    } while (*label != 0);

    out[total > 0 ? total - 1 : 0] = '\0';
    return label + 1;
}

static int dns_build_reply(char *req, int req_len, char *reply, int reply_max,
                           uint32_t ap_ip)
{
    if (req_len > reply_max) {
        return -1;
    }

    memset(reply, 0, (size_t)reply_max);
    memcpy(reply, req, (size_t)req_len);

    dns_header_t *hdr = (dns_header_t *)reply;
    if ((hdr->flags & DNS_OPCODE_MASK) != 0) {
        return 0;
    }

    hdr->flags |= DNS_QR_FLAG;
    const uint16_t qd_count = ntohs(hdr->qd_count);
    hdr->an_count = htons(qd_count);

    const int reply_len = (int)(req_len + qd_count * (int)sizeof(dns_answer_t));
    if (reply_len > reply_max) {
        return -1;
    }

    char *ans_ptr = reply + req_len;
    char *qd_ptr = reply + sizeof(dns_header_t);
    char name[128];

    for (int i = 0; i < qd_count; i++) {
        char *end = dns_parse_name(qd_ptr, name, sizeof(name));
        if (end == NULL) {
            return -1;
        }

        const dns_question_t *q = (const dns_question_t *)end;
        if (ntohs(q->type) != DNS_QD_TYPE_A) {
            continue;
        }

        dns_answer_t *ans = (dns_answer_t *)ans_ptr;
        ans->ptr_offset = htons(0xC000 | (uint16_t)(qd_ptr - reply));
        ans->type = htons(DNS_QD_TYPE_A);
        ans->class = q->class;
        ans->ttl = htonl(DNS_ANS_TTL_SEC);
        ans->addr_len = htons(4);
        ans->ip_addr = ap_ip;
        ans_ptr += sizeof(dns_answer_t);
    }

    return reply_len;
}

static void dns_server_task(void *pv)
{
    const uint32_t ap_ip = (uint32_t)(uintptr_t)pv;
    char rx[128];
    char addr_str[16];

    struct sockaddr_in dest = {
        .sin_family = AF_INET,
        .sin_addr.s_addr = htonl(INADDR_ANY),
        .sin_port = htons(DNS_PORT),
    };

    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
    if (sock < 0) {
        ESP_LOGE(TAG, "DNS socket falhou");
        vTaskDelete(NULL);
        return;
    }

    if (bind(sock, (struct sockaddr *)&dest, sizeof(dest)) < 0) {
        ESP_LOGE(TAG, "DNS bind falhou");
        close(sock);
        vTaskDelete(NULL);
        return;
    }

    ESP_LOGI(TAG, "Servidor DNS ativo (porta %d → IP 0x%08" PRIX32 ")", DNS_PORT, ap_ip);

    for (;;) {
        struct sockaddr_in src;
        socklen_t slen = sizeof(src);
        const int len = recvfrom(sock, rx, sizeof(rx) - 1, 0,
                                 (struct sockaddr *)&src, &slen);
        if (len < 0) {
            continue;
        }

        inet_ntoa_r(src.sin_addr.s_addr, addr_str, sizeof(addr_str));
        char reply[DNS_MAX_LEN];
        const int rlen = dns_build_reply(rx, len, reply, DNS_MAX_LEN, ap_ip);
        if (rlen > 0) {
            sendto(sock, reply, (size_t)rlen, 0, (struct sockaddr *)&src, slen);
            ESP_LOGD(TAG, "DNS %d B de %s → portal", len, addr_str);
        }
    }
}

static void dns_server_start(uint32_t ap_ip)
{
    xTaskCreate(dns_server_task, "dns_cap", 4096,
                (void *)(uintptr_t)ap_ip, 5, NULL);
}

/* -------------------------------------------------------------------------- */
/* Portal cativo – HTTP                                                       */
/* -------------------------------------------------------------------------- */

static const char CAPTIVE_HTML[] =
    "<!DOCTYPE html><html><head>"
    "<meta charset=\"UTF-8\">"
    "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
    "<title>Bancada Diponto – Wi-Fi</title>"
    "<style>"
    "body{font-family:sans-serif;max-width:420px;margin:2rem auto;padding:0 1rem;"
    "background:#0f172a;color:#e2e8f0;}"
    "h1{color:#fbbf24;font-size:1.25rem;}"
    "label{display:block;margin:.75rem 0 .25rem;font-size:.9rem;}"
    "input{width:100%;padding:.6rem;border-radius:6px;border:1px solid #334155;"
    "background:#1e293b;color:#fff;box-sizing:border-box;}"
    "button{margin-top:1.25rem;width:100%;padding:.75rem;background:#fbbf24;"
    "color:#0f172a;border:none;border-radius:6px;font-weight:bold;cursor:pointer;}"
    "</style></head><body>"
    "<h1>Configurar Wi-Fi da Bancada</h1>"
    "<p>Conecte-se ao AP <strong>" AP_SSID "</strong> e informe a rede da fábrica.</p>"
    "<form method=\"POST\" action=\"/save\">"
    "<label for=\"ssid\">SSID</label>"
    "<input id=\"ssid\" name=\"SSID\" maxlength=\"32\" required>"
    "<label for=\"senha\">Senha</label>"
    "<input id=\"senha\" name=\"Senha\" type=\"password\" maxlength=\"64\">"
    "<button type=\"submit\">Salvar</button>"
    "</form></body></html>";

static void url_decode(char *s)
{
    char *src = s;
    char *dst = s;

    while (*src) {
        if (*src == '+') {
            *dst++ = ' ';
            src++;
        } else if (*src == '%' && src[1] && src[2]) {
            char hex[3] = { src[1], src[2], '\0' };
            *dst++ = (char)strtol(hex, NULL, 16);
            src += 3;
        } else {
            *dst++ = *src++;
        }
    }
    *dst = '\0';
}

static bool form_get_value(const char *body, const char *key,
                           char *out, size_t out_len)
{
    char pattern[32];
    snprintf(pattern, sizeof(pattern), "%s=", key);
    const char *start = strstr(body, pattern);
    if (start == NULL) {
        return false;
    }

    start += strlen(pattern);
    const char *end = strchr(start, '&');
    size_t len = end != NULL ? (size_t)(end - start) : strlen(start);
    if (len >= out_len) {
        len = out_len - 1;
    }

    memcpy(out, start, len);
    out[len] = '\0';
    url_decode(out);
    return out[0] != '\0';
}

static esp_err_t captive_root_get(httpd_req_t *req)
{
    httpd_resp_set_type(req, "text/html");
    httpd_resp_send(req, CAPTIVE_HTML, HTTPD_RESP_USE_STRLEN);
    return ESP_OK;
}

static esp_err_t captive_save_post(httpd_req_t *req)
{
    char body[256];
    int total = 0;

    if (req->content_len >= (int)sizeof(body)) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "Payload grande");
        return ESP_FAIL;
    }

    while (total < req->content_len) {
        const int r = httpd_req_recv(req, body + total, req->content_len - total);
        if (r <= 0) {
            httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "Leitura falhou");
            return ESP_FAIL;
        }
        total += r;
    }
    body[total] = '\0';

    char ssid[WIFI_SSID_MAX + 1] = {0};
    char pass[WIFI_PASS_MAX + 1] = {0};

    if (!form_get_value(body, "SSID", ssid, sizeof(ssid))) {
        httpd_resp_send_err(req, HTTPD_400_BAD_REQUEST, "SSID obrigatório");
        return ESP_FAIL;
    }

    form_get_value(body, "Senha", pass, sizeof(pass));

    ESP_LOGI(TAG, "Credenciais recebidas – SSID: %s", ssid);

    const esp_err_t err = nvs_save_credentials(ssid, pass);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "NVS save falhou: %s", esp_err_to_name(err));
        httpd_resp_send_err(req, HTTPD_500_INTERNAL_SERVER_ERROR, "Erro NVS");
        return ESP_FAIL;
    }

    const char *ok_page =
        "<!DOCTYPE html><html><body style=\"font-family:sans-serif;text-align:center;"
        "padding:2rem;\"><h2>Salvo!</h2><p>Reiniciando a bancada…</p></body></html>";

    httpd_resp_set_type(req, "text/html");
    httpd_resp_send(req, ok_page, HTTPD_RESP_USE_STRLEN);

    vTaskDelay(pdMS_TO_TICKS(500));
    esp_restart();
    return ESP_OK;
}

static esp_err_t captive_404(httpd_req_t *req, httpd_err_code_t err)
{
    (void)err;
    httpd_resp_set_status(req, "302 Found");
    httpd_resp_set_hdr(req, "Location", "/");
    httpd_resp_send(req, "Redirect", HTTPD_RESP_USE_STRLEN);
    return ESP_OK;
}

static httpd_handle_t captive_portal_start(void)
{
    httpd_config_t cfg = HTTPD_DEFAULT_CONFIG();
    cfg.max_open_sockets = 8;
    cfg.lru_purge_enable = true;

    httpd_handle_t server = NULL;
    if (httpd_start(&server, &cfg) != ESP_OK) {
        return NULL;
    }

    const httpd_uri_t root_uri = {
        .uri     = "/",
        .method  = HTTP_GET,
        .handler = captive_root_get,
    };
    const httpd_uri_t save_uri = {
        .uri     = "/save",
        .method  = HTTP_POST,
        .handler = captive_save_post,
    };

    httpd_register_uri_handler(server, &root_uri);
    httpd_register_uri_handler(server, &save_uri);
    httpd_register_err_handler(server, HTTPD_404_NOT_FOUND, captive_404);

    ESP_LOGI(TAG, "HTTP portal cativo na porta %d", cfg.server_port);
    return server;
}

/* -------------------------------------------------------------------------- */
/* SoftAP + portal                                                            */
/* -------------------------------------------------------------------------- */

static void wifi_start_captive_portal(void)
{
    esp_log_level_set("httpd_uri", ESP_LOG_ERROR);
    esp_log_level_set("httpd_txrx", ESP_LOG_ERROR);

    if (s_netif_ap == NULL) {
        s_netif_ap = esp_netif_create_default_wifi_ap();
    }

    wifi_config_t ap_cfg = {
        .ap = {
            .ssid           = AP_SSID,
            .ssid_len       = (uint8_t)strlen(AP_SSID),
            .channel        = 1,
            .max_connection = AP_MAX_CONN,
            .authmode       = WIFI_AUTH_OPEN,
        },
    };

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_AP));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_AP, &ap_cfg));
    ESP_ERROR_CHECK(esp_wifi_start());

    esp_netif_ip_info_t ip_info;
    ESP_ERROR_CHECK(esp_netif_get_ip_info(s_netif_ap, &ip_info));

    char ip_str[16];
    inet_ntoa_r(ip_info.ip.addr, ip_str, sizeof(ip_str));
    ESP_LOGI(TAG, "SoftAP ativo – SSID: %s | IP: %s (sem senha)", AP_SSID, ip_str);

    captive_portal_start();
    dns_server_start(ip_info.ip.addr);

    ESP_LOGI(TAG, "Portal cativo pronto – abra http://%s no navegador", ip_str);

    for (;;) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

/* -------------------------------------------------------------------------- */
/* API pública                                                                */
/* -------------------------------------------------------------------------- */

esp_err_t wifi_manager_init(void)
{
    s_events = xEventGroupCreate();
    if (s_events == NULL) {
        return ESP_ERR_NO_MEM;
    }

    s_connected = false;
    s_netif_sta = NULL;
    s_netif_ap = NULL;

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    esp_event_handler_instance_t inst_sta_any;
    esp_event_handler_instance_t inst_sta_ip;
    esp_event_handler_instance_t inst_ap_any;

    ESP_ERROR_CHECK(esp_event_handler_instance_register(
        WIFI_EVENT, ESP_EVENT_ANY_ID, &sta_event_handler, NULL, &inst_sta_any));
    ESP_ERROR_CHECK(esp_event_handler_instance_register(
        IP_EVENT, IP_EVENT_STA_GOT_IP, &sta_event_handler, NULL, &inst_sta_ip));
    ESP_ERROR_CHECK(esp_event_handler_instance_register(
        WIFI_EVENT, ESP_EVENT_ANY_ID, &ap_event_handler, NULL, &inst_ap_any));

    ESP_LOGI(TAG, "Wi-Fi manager inicializado");
    return ESP_OK;
}

esp_err_t wifi_manager_run(void)
{
    char ssid[WIFI_SSID_MAX + 1] = {0};
    char pass[WIFI_PASS_MAX + 1] = {0};

    const esp_err_t nvs_err = nvs_load_credentials(ssid, sizeof(ssid),
                                                   pass, sizeof(pass));

    if (nvs_err == ESP_OK) {
        ESP_LOGI(TAG, "Credenciais NVS encontradas");
        if (wifi_start_sta(ssid, pass) == ESP_OK) {
            return ESP_OK;
        }
        ESP_LOGW(TAG, "Falha STA – iniciando portal de configuração");
    } else if (nvs_err == ESP_ERR_NVS_NOT_FOUND ||
               nvs_err == ESP_ERR_NOT_FOUND) {
        ESP_LOGI(TAG, "Sem credenciais na NVS – portal de configuração");
    } else {
        ESP_LOGW(TAG, "NVS leitura: %s – portal de configuração",
                 esp_err_to_name(nvs_err));
    }

    wifi_start_captive_portal();
    return ESP_OK; /* inalcançável – portal bloqueia ou reinicia */
}

void wifi_manager_wait_connected(void)
{
    ESP_LOGI(TAG, "Aguardando Wi-Fi conectado…");
    xEventGroupWaitBits(s_events, WIFI_MANAGER_CONNECTED_BIT,
                        pdFALSE, pdTRUE, portMAX_DELAY);
}

bool wifi_manager_is_connected(void)
{
    return s_connected;
}

EventGroupHandle_t wifi_manager_get_event_group(void)
{
    return s_events;
}

void wifi_manager_supervisor_task(void *pv_parameters)
{
    (void)pv_parameters;
    ESP_LOGI(TAG, "Supervisor Wi-Fi (core %d)", xPortGetCoreID());

    for (;;) {
        if (!s_connected) {
            xEventGroupWaitBits(s_events, WIFI_MANAGER_CONNECTED_BIT,
                                pdFALSE, pdTRUE, pdMS_TO_TICKS(5000));
        }
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}
