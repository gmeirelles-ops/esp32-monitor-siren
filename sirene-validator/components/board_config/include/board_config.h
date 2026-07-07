#pragma once

#include <stdint.h>

#include "sdkconfig.h"

/* GPIO map — perfil escolhido em menuconfig (Sirene board config) */
#if CONFIG_SIRENE_BOARD_LEGACY_DEVKIT
#define GPIO_RELAY            26
#define GPIO_BUTTON           0
#define PZEM_TX_PIN           17
#define PZEM_RX_PIN           16
#else
#define GPIO_RELAY            4
#define GPIO_BUTTON           5
#define PZEM_TX_PIN           27
#define PZEM_RX_PIN           26
#endif
#define GPIO_LED_STATUS       25
#define GPIO_BUZZER           33

/* SSD1306 OLED (I2C) — ver Sirene OLED display em menuconfig */
#define OLED_I2C_SDA_GPIO     CONFIG_SIRENE_OLED_SDA_GPIO
#define OLED_I2C_SCL_GPIO     CONFIG_SIRENE_OLED_SCL_GPIO
#define OLED_I2C_ADDR         CONFIG_SIRENE_OLED_I2C_ADDR

/* UART PZEM-004T */
#define PZEM_UART_NUM         UART_NUM_2
#define PZEM_BAUD_RATE        9600
#define PZEM_SLAVE_ADDR       0x01   /* fallback; auto-detect 0x01 ou 0xF8 no boot */
#define PZEM_SLAVE_ADDR_V3    0xF8
#define PZEM_READ_ALL_REGS    10
#define PZEM_RESPONSE_ALL_LEN 25     /* 3 + (10 regs × 2) + CRC */
#define PZEM_RESPONSE_DELAY_MS  100
#define PZEM_READ_TIMEOUT_MS    300

/* MQTT broker (fallback de fábrica — sobrescrito por NVS mqtt_cfg se provisionado) */
#define MQTT_BROKER_URI       "wss://mqtt.diponto.com:443"
#define MQTT_DEFAULT_HOST     "mqtt.diponto.com"
#define MQTT_DEFAULT_SITE     "producao"
#define MQTT_NVS_NAMESPACE    "mqtt_cfg"
#define MQTT_NVS_HOST_KEY     "host"
#define MQTT_NVS_PORT_KEY     "port"
#define MQTT_NVS_USER_KEY     "user"
#define MQTT_NVS_PASS_KEY     "pass"
#define MQTT_NVS_TLS_KEY      "tls"
#define MQTT_DEFAULT_PORT     1883
#define MQTT_DEFAULT_PORT_TLS 443
#define MQTT_DEFAULT_USER     CONFIG_SIRENE_MQTT_DEFAULT_USER
#define MQTT_DEFAULT_PASS     CONFIG_SIRENE_MQTT_DEFAULT_PASSWORD

/* Identidade MQTT da bancada (tópicos producao/bancada-NN/...) */
#define STATION_NVS_NAMESPACE    "station_cfg"
#define STATION_NVS_SITE_KEY     "site"
#define STATION_NVS_BANCADA_KEY  "bancada"
/* Número da bancada gravado no firmware (1–99). Ajuste antes do build por dispositivo. */
#define STATION_DEFAULT_BANCADA  1

/* Host OTA adicional além de IPs RFC1918 e *.local (ex.: "ota.diponto.internal") */
#define OTA_ALLOWED_EXTRA_HOST  ""

/* Timing */
#define INRUSH_DISCARD_MS         500
#define PZEM_SAMPLE_READ_RETRIES  3
#define CALIBRATION_SEC           5
#define CALIBRATION_SAMPLE_MS     500
#define BUTTON_DEBOUNCE_MS    50
#define WIFI_RESET_BUTTON_HOLD_MS 5000

/* Offline queue */
#define OFFLINE_QUEUE_MAX     64

/* Wi-Fi provisioning — senha AP derivada do MAC (ver wifi_prov_derive_ap_password) */
#define WIFI_AP_SSID          "SireneValidator"
#define WIFI_AP_PASS          CONFIG_SIRENE_WIFI_AP_PASSWORD
#define WIFI_AP_IP            "192.168.4.1"
#define WIFI_NVS_NAMESPACE    "wifi_cfg"
#define WIFI_NVS_SSID_KEY     "ssid"
#define WIFI_NVS_PASS_KEY     "pass"

/* NVS namespaces */
#define BATCH_NVS_NAMESPACE   "batch"
#define QUEUE_NVS_NAMESPACE   "queue"

/* Telemetria e robustez */
#define HEARTBEAT_INTERVAL_SEC    30
#define WIFI_RECONNECT_BASE_MS      1000
#define WIFI_RECONNECT_MAX_MS       30000
#define MQTT_RECONNECT_BASE_MS      1000
#define MQTT_RECONNECT_MAX_MS       30000
#define WIFI_STA_VALIDATE_TIMEOUT_MS 15000
#define OFFLINE_SYNC_INTERVAL_MS    5000
#define FIRMWARE_VERSION            "1.7.5"
