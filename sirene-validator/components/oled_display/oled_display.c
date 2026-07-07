#include "oled_display.h"

#include <stdio.h>
#include <string.h>

#include "board_config.h"
#include "driver/i2c_master.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/semphr.h"
#include "mqtt_bridge.h"
#include "sdkconfig.h"
#include "wifi_prov.h"

static const char *TAG = "oled";

#define OLED_W 128
#define OLED_H 64
#define OLED_PAGES (OLED_H / 8)

#if CONFIG_SIRENE_OLED_ENABLE

static i2c_master_bus_handle_t s_bus;
static i2c_master_dev_handle_t s_dev;
static SemaphoreHandle_t s_mu;
static bool s_ready;
static uint8_t s_fb[OLED_W * OLED_PAGES];

static char s_op[16];
static char s_stats[24];
static char s_last_test[24];
static app_state_t s_state = STATE_PROVISIONING;

static bool glyph5x7(char c, uint8_t out[5])
{
    static const uint8_t blank[5] = {0, 0, 0, 0, 0};
    static const uint8_t unknown[5] = {0x5F, 0x41, 0x41, 0x41, 0x5F};
    if (c == ' ') {
        memcpy(out, blank, 5);
        return true;
    }
    if (c >= '0' && c <= '9') {
        static const uint8_t digits[10][5] = {
            {0x3E, 0x51, 0x49, 0x45, 0x3E}, {0x00, 0x42, 0x7F, 0x40, 0x00},
            {0x42, 0x61, 0x51, 0x49, 0x46}, {0x21, 0x41, 0x45, 0x4B, 0x31},
            {0x18, 0x14, 0x12, 0x7F, 0x10}, {0x27, 0x45, 0x45, 0x45, 0x39},
            {0x3C, 0x4A, 0x49, 0x49, 0x30}, {0x01, 0x71, 0x09, 0x05, 0x03},
            {0x36, 0x49, 0x49, 0x49, 0x36}, {0x06, 0x49, 0x49, 0x29, 0x1E},
        };
        memcpy(out, digits[c - '0'], 5);
        return true;
    }
    if (c >= 'A' && c <= 'Z') {
        static const uint8_t letters[26][5] = {
            {0x7C, 0x12, 0x11, 0x12, 0x7C}, {0x7F, 0x49, 0x49, 0x49, 0x36},
            {0x3E, 0x41, 0x41, 0x41, 0x22}, {0x7F, 0x41, 0x41, 0x22, 0x1C},
            {0x7F, 0x49, 0x49, 0x49, 0x41}, {0x7F, 0x09, 0x09, 0x09, 0x01},
            {0x3E, 0x41, 0x49, 0x49, 0x7A}, {0x7F, 0x08, 0x08, 0x08, 0x7F},
            {0x00, 0x41, 0x7F, 0x41, 0x00}, {0x20, 0x40, 0x41, 0x3F, 0x01},
            {0x7F, 0x08, 0x14, 0x22, 0x41}, {0x7F, 0x40, 0x40, 0x40, 0x40},
            {0x7F, 0x02, 0x0C, 0x02, 0x7F}, {0x7F, 0x04, 0x08, 0x10, 0x7F},
            {0x3E, 0x41, 0x41, 0x41, 0x3E}, {0x7F, 0x09, 0x09, 0x09, 0x06},
            {0x3E, 0x41, 0x51, 0x51, 0x3E}, {0x7F, 0x09, 0x19, 0x29, 0x46},
            {0x46, 0x49, 0x49, 0x49, 0x31}, {0x01, 0x01, 0x7F, 0x01, 0x01},
            {0x3F, 0x40, 0x40, 0x40, 0x3F}, {0x1F, 0x20, 0x40, 0x20, 0x1F},
            {0x3F, 0x40, 0x38, 0x40, 0x3F}, {0x63, 0x14, 0x08, 0x14, 0x63},
            {0x07, 0x08, 0x70, 0x08, 0x07}, {0x61, 0x51, 0x49, 0x45, 0x43},
        };
        memcpy(out, letters[c - 'A'], 5);
        return true;
    }
    switch (c) {
    case '.':
        memcpy(out, (uint8_t[]){0x00, 0x60, 0x60, 0x00, 0x00}, 5);
        return true;
    case '-':
        memcpy(out, (uint8_t[]){0x08, 0x08, 0x08, 0x08, 0x08}, 5);
        return true;
    case ':':
        memcpy(out, (uint8_t[]){0x00, 0x36, 0x36, 0x00, 0x00}, 5);
        return true;
    case '/':
        memcpy(out, (uint8_t[]){0x20, 0x10, 0x08, 0x04, 0x02}, 5);
        return true;
    default:
        memcpy(out, unknown, 5);
        return true;
    }
}

static esp_err_t oled_cmd(uint8_t cmd)
{
    uint8_t buf[2] = {0x00, cmd};
    return i2c_master_transmit(s_dev, buf, sizeof(buf), 50);
}

static esp_err_t oled_data(const uint8_t *data, size_t len)
{
    uint8_t stack[17];
    while (len > 0) {
        size_t chunk = len > 16 ? 16 : len;
        stack[0] = 0x40;
        memcpy(stack + 1, data, chunk);
        esp_err_t err = i2c_master_transmit(s_dev, stack, chunk + 1, 50);
        if (err != ESP_OK) {
            return err;
        }
        data += chunk;
        len -= chunk;
    }
    return ESP_OK;
}

static bool oled_hw_init(void)
{
    i2c_master_bus_config_t bus_cfg = {
        .clk_source = I2C_CLK_SRC_DEFAULT,
        .i2c_port = I2C_NUM_0,
        .scl_io_num = OLED_I2C_SCL_GPIO,
        .sda_io_num = OLED_I2C_SDA_GPIO,
        .glitch_ignore_cnt = 7,
        .flags.enable_internal_pullup = true,
    };
    if (i2c_new_master_bus(&bus_cfg, &s_bus) != ESP_OK) {
        return false;
    }

    i2c_device_config_t dev_cfg = {
        .dev_addr_length = I2C_ADDR_BIT_LEN_7,
        .device_address = OLED_I2C_ADDR,
        .sclk_speed_hz = 400000,
    };
    if (i2c_master_bus_add_device(s_bus, &dev_cfg, &s_dev) != ESP_OK) {
        return false;
    }

    static const uint8_t init_seq[] = {
        0xAE, 0xD5, 0x80, 0xA8, 0x3F, 0xD3, 0x00, 0x40, 0x8D, 0x14, 0x20, 0x00, 0xA1, 0xC8, 0xDA, 0x12,
        0x81, 0xCF, 0xD9, 0xF1, 0xDB, 0x40, 0xA4, 0xA6, 0xAF,
    };
    for (size_t i = 0; i < sizeof(init_seq); i++) {
        if (oled_cmd(init_seq[i]) != ESP_OK) {
            return false;
        }
    }
    return true;
}

static void fb_clear(void)
{
    memset(s_fb, 0, sizeof(s_fb));
}

static void fb_draw_char(int x, int page, char c)
{
    uint8_t glyph[5];
    if (c >= 'a' && c <= 'z') {
        c = (char)(c - 'a' + 'A');
    }
    glyph5x7(c, glyph);
    for (int col = 0; col < 5; col++) {
        int px = x + col;
        if (px < 0 || px >= OLED_W) {
            continue;
        }
        s_fb[page * OLED_W + px] = glyph[col];
    }
}

static void fb_draw_text(int x, int page, const char *text)
{
    int cx = x;
    for (const char *p = text; *p; p++) {
        if (*p == '\n') {
            break;
        }
        fb_draw_char(cx, page, *p);
        cx += 6;
        if (cx >= OLED_W - 5) {
            break;
        }
    }
}

static void fb_flush(void)
{
    for (int page = 0; page < OLED_PAGES; page++) {
        oled_cmd(0xB0 | page);
        oled_cmd(0x00);
        oled_cmd(0x10);
        oled_data(&s_fb[page * OLED_W], OLED_W);
    }
}

static void render_locked(void)
{
    char line0[22];
    char line3[22];
    char ssid[12];

    snprintf(line0, sizeof(line0), "DIPONTO %s", state_machine_name(s_state));
    if (s_op[0] != '\0') {
        /* s_stats already formatted */
    } else {
        snprintf(s_stats, sizeof(s_stats), "sem lote");
    }

    if (wifi_prov_get_ssid(ssid, sizeof(ssid)) && ssid[0] != '\0') {
        snprintf(line3, sizeof(line3), "WiFi %s MQTT %s", ssid,
                 mqtt_bridge_is_connected() ? "OK" : "--");
    } else {
        snprintf(line3, sizeof(line3), "WiFi -- MQTT %s",
                 mqtt_bridge_is_connected() ? "OK" : "--");
    }

    fb_clear();
    fb_draw_text(0, 0, line0);
    fb_draw_text(0, 2, s_op[0] ? s_op : "OP: ---");
    fb_draw_text(0, 4, s_stats);
    fb_draw_text(0, 6, s_last_test[0] ? s_last_test : line3);
    fb_flush();
}

static void lock_refresh(void)
{
    if (!s_ready || !s_mu) {
        return;
    }
    xSemaphoreTake(s_mu, portMAX_DELAY);
    render_locked();
    xSemaphoreGive(s_mu);
}

#endif /* CONFIG_SIRENE_OLED_ENABLE */

void oled_display_init(void)
{
#if CONFIG_SIRENE_OLED_ENABLE
    s_mu = xSemaphoreCreateMutex();
    s_ready = oled_hw_init();
    if (s_ready) {
        ESP_LOGI(TAG, "SSD1306 OK SDA=%d SCL=%d addr=0x%02X",
                 OLED_I2C_SDA_GPIO, OLED_I2C_SCL_GPIO, OLED_I2C_ADDR);
        strcpy(s_op, "");
        strcpy(s_stats, "inicializando...");
        strcpy(s_last_test, "");
        lock_refresh();
    } else {
        ESP_LOGW(TAG, "SSD1306 nao detectado (SDA=%d SCL=%d) — display desabilitado",
                 OLED_I2C_SDA_GPIO, OLED_I2C_SCL_GPIO);
    }
#else
    ESP_LOGD(TAG, "OLED desabilitado em menuconfig");
#endif
}

bool oled_display_is_ready(void)
{
#if CONFIG_SIRENE_OLED_ENABLE
    return s_ready;
#else
    return false;
#endif
}

void oled_display_set_batch(const char *numero_op, uint32_t aprovados, uint32_t sequencial)
{
#if CONFIG_SIRENE_OLED_ENABLE
    if (!s_ready || !s_mu) {
        return;
    }
    xSemaphoreTake(s_mu, portMAX_DELAY);
    if (numero_op != NULL && numero_op[0] != '\0') {
        snprintf(s_op, sizeof(s_op), "OP %s", numero_op);
        snprintf(s_stats, sizeof(s_stats), "OK %lu seq %lu",
                 (unsigned long)aprovados, (unsigned long)sequencial);
    } else {
        s_op[0] = '\0';
        snprintf(s_stats, sizeof(s_stats), "sem lote");
    }
    xSemaphoreGive(s_mu);
    lock_refresh();
#else
    (void)numero_op;
    (void)aprovados;
    (void)sequencial;
#endif
}

void oled_display_refresh(void)
{
#if CONFIG_SIRENE_OLED_ENABLE
    lock_refresh();
#endif
}

void oled_display_on_state_change(app_state_t prev, app_state_t next)
{
    (void)prev;
#if CONFIG_SIRENE_OLED_ENABLE
    if (!s_ready || !s_mu) {
        return;
    }
    xSemaphoreTake(s_mu, portMAX_DELAY);
    s_state = next;
    xSemaphoreGive(s_mu);
    lock_refresh();
#else
    (void)next;
#endif
}

void oled_display_on_test_result(bool approved, float potencia_w)
{
#if CONFIG_SIRENE_OLED_ENABLE
    if (!s_ready || !s_mu) {
        return;
    }
    xSemaphoreTake(s_mu, portMAX_DELAY);
    snprintf(s_last_test, sizeof(s_last_test), "%s %.1fW",
             approved ? "APROV" : "REPROV", potencia_w);
    xSemaphoreGive(s_mu);
    lock_refresh();
#else
    (void)approved;
    (void)potencia_w;
#endif
}
